import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_ce/hive.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/episode.dart';
import 'package:poltro_play/core/utils/string_utils.dart';

/// Serviço que consome a API REST do PostgreSQL para séries e episódios.
/// URL Base: https://series.leflow.com.br
class SeriesApiService {
  static const String _baseUrl = 'https://series.leflow.com.br';
  static const int _pageSize = 20;

  /// Lista séries com paginação
  Future<List<Series>> getSeries({int page = 1}) async {
    final cacheKey = 'series_page_$page';

    // Dispara a requisição de rede em background para atualizar o cache
    final networkFuture = _fetchAndUpdateCache(page, cacheKey);

    // Tenta carregar do cache instantaneamente
    final cached = _loadFromCache(cacheKey);
    if (cached.isNotEmpty) {
      return cached; // Retorna na hora! O Riverpod depois pode ser forçado a atualizar se precisarmos, mas para initial load isso é mágico.
    }

    // Se não tem cache, espera a rede
    return await networkFuture;
  }

  Future<List<Series>> _fetchAndUpdateCache(int page, String cacheKey) async {
    try {
      final uri = Uri.parse('$_baseUrl/series?page=$page&limit=$_pageSize');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          if (Hive.isBoxOpen('user_prefs_box')) {
            Hive.box('user_prefs_box').put(cacheKey, response.body);
          }
        } catch (_) {}

        final data = json.decode(response.body);
        final List list = data['series'] ?? [];
        return list.map((j) => Series.fromApi(j)).toList();
      }
    } catch (e) {
      print('SeriesApiService.getSeries network error: $e');
    }
    return [];
  }

  List<Series> _loadFromCache(String cacheKey) {
    try {
      if (Hive.isBoxOpen('user_prefs_box')) {
        final box = Hive.box('user_prefs_box');
        final cachedBody = box.get(cacheKey);
        if (cachedBody != null) {
          final data = json.decode(cachedBody);
          final List list = data['series'] ?? [];
          return list.map((j) => Series.fromApi(j)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Total de séries no banco
  Future<int> getTotalCount() async {
    try {
      final uri = Uri.parse('$_baseUrl/series?page=1&limit=1');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Busca uma série pelo ID
  Future<Series?> getSeriesById(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/series/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return Series.fromApi(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('SeriesApiService.getSeriesById error: $e');
      return null;
    }
  }

  /// Episódios de uma série, já ordenados por temporada e episódio
  Future<List<Episode>> getEpisodes(int seriesId) async {
    try {
      final uri = Uri.parse('$_baseUrl/series/$seriesId/episodes');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        return list.map((j) => Episode.fromApi(j)).toList();
      }
      return [];
    } catch (e) {
      print('SeriesApiService.getEpisodes error: $e');
      return [];
    }
  }

  /// Séries em destaque (is_highlight = true)
  Future<List<Series>> getHighlights() async {
    try {
      final uri = Uri.parse('$_baseUrl/series/highlights');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        return list.map((j) => Series.fromApi(j)).toList();
      }
      return [];
    } catch (e) {
      print('SeriesApiService.getHighlights error: $e');
      return [];
    }
  }

  // Cache em memória de todas as séries para busca rápida e tolerante a acentos
  List<Series>? _allSeriesMemoryCache;

  /// Retorna todas as séries do catálogo (atualmente ~110 itens) com cache local
  Future<List<Series>> getAllSeries({bool forceRefresh = false}) async {
    const cacheKey = 'all_series_catalog_cache';

    if (!forceRefresh && _allSeriesMemoryCache != null && _allSeriesMemoryCache!.isNotEmpty) {
      return _allSeriesMemoryCache!;
    }

    if (!forceRefresh) {
      final cached = _loadFromCache(cacheKey);
      if (cached.isNotEmpty) {
        _allSeriesMemoryCache = cached;
        return cached;
      }
    }

    try {
      final uri = Uri.parse('$_baseUrl/series?page=1&limit=200');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        if (Hive.isBoxOpen('user_prefs_box')) {
          Hive.box('user_prefs_box').put(cacheKey, response.body);
        }
        final data = json.decode(response.body);
        final List list = data['series'] ?? [];
        final parsed = list.map((j) => Series.fromApi(j)).toList();
        _allSeriesMemoryCache = parsed;
        return parsed;
      }
    } catch (e) {
      print('SeriesApiService.getAllSeries error: $e');
    }

    return _allSeriesMemoryCache ?? [];
  }

  /// Retorna séries filtradas por tag/gênero com paginação direta da API REST
  Future<List<Series>> getSeriesByTag(String tag, {int page = 1}) async {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty) return [];

    try {
      final uri = Uri.parse(
          '$_baseUrl/series?page=$page&limit=$_pageSize&tag=${Uri.encodeComponent(cleanTag)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['series'] ?? [];
        final parsed = list.map((j) => Series.fromApi(j)).toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      print('SeriesApiService.getSeriesByTag network error: $e');
    }

    // Fallback: se for página 1 e a API falhar ou não encontrar por tag exata, busca no cache local
    if (page == 1) {
      final normTag = normalizeSearchText(cleanTag);
      final all = await getAllSeries();
      return all.where((s) {
        return s.tags.any((t) {
          final norm = normalizeSearchText(t);
          return norm.contains(normTag) || normTag.contains(norm);
        });
      }).toList();
    }

    return [];
  }

  /// Busca séries pelo nome com suporte a tolerância a acentos e termos parciais
  Future<List<Series>> searchSeries(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final normalizedQuery = normalizeSearchText(cleanQuery);
    final queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

    // 1. Inicia busca na API remota e carregamento do catálogo em paralelo
    final remoteFuture = _fetchRemoteSearch(cleanQuery);
    final allSeriesFuture = getAllSeries();

    final results = await Future.wait([remoteFuture, allSeriesFuture]);
    final remoteList = results[0];
    final allSeries = results[1];

    // 2. Busca local usando texto normalizado (sem acentos e minúsculo)
    final localMatches = <Series>[];
    for (final s in allSeries) {
      final normalizedName = normalizeSearchText(s.name);
      
      // Correspondência direta por substring
      if (normalizedName.contains(normalizedQuery)) {
        localMatches.add(s);
        continue;
      }

      // Se contém todas as palavras pesquisadas
      if (queryWords.length > 1 && queryWords.every((w) => normalizedName.contains(w))) {
        localMatches.add(s);
      }
    }

    // 3. Mescla e deduplica por ID mantendo os mais relevantes primeiro
    final mergedMap = <String, Series>{};

    for (final item in remoteList) {
      mergedMap[item.id] = item;
    }
    for (final item in localMatches) {
      mergedMap[item.id] = item;
    }

    final combined = mergedMap.values.toList();

    // 4. Ordena por relevância:
    // Começa com a query normalizada > Contém a query > Demais
    combined.sort((a, b) {
      final aNorm = normalizeSearchText(a.name);
      final bNorm = normalizeSearchText(b.name);

      final aStarts = aNorm.startsWith(normalizedQuery);
      final bStarts = bNorm.startsWith(normalizedQuery);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      final aContains = aNorm.contains(normalizedQuery);
      final bContains = bNorm.contains(normalizedQuery);
      if (aContains && !bContains) return -1;
      if (!aContains && bContains) return 1;

      return a.name.compareTo(b.name);
    });

    return combined;
  }

  Future<List<Series>> _fetchRemoteSearch(String query) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/series?search=${Uri.encodeComponent(query)}&limit=20');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['series'] ?? [];
        return list.map((j) => Series.fromApi(j)).toList();
      }
    } catch (e) {
      print('SeriesApiService.searchSeries remote error: $e');
    }
    return [];
  }
}

