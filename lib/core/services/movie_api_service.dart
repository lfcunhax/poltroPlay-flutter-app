import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_ce/hive.dart';
import 'package:poltro_play/models/movie.dart';

/// Serviço que consome a API REST unificada do PostgreSQL para filmes.
/// URL Base: https://series.leflow.com.br
class MovieApiService {
  static const String _baseUrl = 'https://series.leflow.com.br';
  static const int _pageSize = 20;

  /// Lista filmes com paginação e cache offline via Hive
  Future<List<Movie>> getMovies({int page = 1}) async {
    final cacheKey = 'movies_page_$page';

    // Dispara a requisição de rede em background para atualizar o cache
    final networkFuture = _fetchAndUpdateCache(page, cacheKey);

    // Tenta carregar do cache instantaneamente
    final cached = _loadFromCache(cacheKey);
    if (cached.isNotEmpty) {
      return cached;
    }

    // Se não tem cache, espera a rede
    return await networkFuture;
  }

  Future<List<Movie>> _fetchAndUpdateCache(int page, String cacheKey) async {
    try {
      final uri = Uri.parse('$_baseUrl/movies?page=$page&limit=$_pageSize');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          if (Hive.isBoxOpen('user_prefs_box')) {
            Hive.box('user_prefs_box').put(cacheKey, response.body);
          }
        } catch (_) {}

        final data = json.decode(response.body);
        final List list = data['movies'] ?? [];
        return list.map((j) => Movie.fromApi(j)).toList();
      }
    } catch (e) {
      print('MovieApiService.getMovies network error: $e');
    }
    return [];
  }

  List<Movie> _loadFromCache(String cacheKey) {
    try {
      if (Hive.isBoxOpen('user_prefs_box')) {
        final box = Hive.box('user_prefs_box');
        final cachedBody = box.get(cacheKey);
        if (cachedBody != null) {
          final data = json.decode(cachedBody);
          final List list = data['movies'] ?? [];
          return list.map((j) => Movie.fromApi(j)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Total de filmes cadastrados no PostgreSQL
  Future<int> getTotalCount() async {
    try {
      final uri = Uri.parse('$_baseUrl/movies?page=1&limit=1');
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

  /// Busca um filme pelo ID
  Future<Movie?> getMovieById(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/movies/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return Movie.fromApi(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('MovieApiService.getMovieById error: $e');
      return null;
    }
  }

  /// Filmes em destaque (is_highlight = true)
  Future<List<Movie>> getHighlights() async {
    try {
      final uri = Uri.parse('$_baseUrl/movies/highlights');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        return list.map((j) => Movie.fromApi(j)).toList();
      }
      return [];
    } catch (e) {
      print('MovieApiService.getHighlights error: $e');
      return [];
    }
  }

  /// Filmes filtrados por categoria/tag
  Future<List<Movie>> getMoviesByTag(String tag, {int page = 1}) async {
    try {
      final uri = Uri.parse('$_baseUrl/movies?page=$page&limit=$_pageSize&tag=${Uri.encodeComponent(tag)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['movies'] ?? [];
        return list.map((j) => Movie.fromApi(j)).toList();
      }
      return [];
    } catch (e) {
      print('MovieApiService.getMoviesByTag error: $e');
      return [];
    }
  }

  /// Busca filmes por termo no PostgreSQL com fallback de busca tolerante
  Future<List<Movie>> searchMovies(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/movies?search=${Uri.encodeComponent(cleanQuery)}&limit=50');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['movies'] ?? [];
        final apiResults = list.map((j) => Movie.fromApi(j)).toList();

        if (apiResults.isNotEmpty) {
          return apiResults;
        }
      }
    } catch (e) {
      print('MovieApiService.searchMovies error: $e');
    }

    return [];
  }
}
