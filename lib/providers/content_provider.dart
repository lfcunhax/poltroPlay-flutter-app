import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poltro_play/core/services/firestore_service.dart';
import 'package:poltro_play/core/services/series_api_service.dart';
import 'package:poltro_play/core/services/movie_api_service.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/cast.dart';
import 'package:poltro_play/models/video.dart';
import 'package:poltro_play/models/episode.dart';
import 'package:poltro_play/models/promotion.dart';
import 'package:poltro_play/core/services/tmdb_service.dart';
import 'package:poltro_play/core/utils/string_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

final seriesApiServiceProvider = Provider<SeriesApiService>((ref) {
  return SeriesApiService();
});

final movieApiServiceProvider = Provider<MovieApiService>((ref) {
  return MovieApiService();
});

// --- ESTADO PAGINADO PARA FILMES ---

class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final int currentPage; // para API REST (séries)

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
    this.currentPage = 1,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    int? currentPage,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class MoviesNotifier extends StateNotifier<PaginatedState<Movie>> {
  final MovieApiService _api;

  MoviesNotifier(this._api) : super(const PaginatedState<Movie>()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, currentPage: 1);

    try {
      // 1. Tenta carregar da API REST PostgreSQL
      final movies = await _api.getMovies(page: 1);
      if (movies.isNotEmpty) {
        state = PaginatedState<Movie>(
          items: movies,
          isLoading: false,
          hasMore: movies.length >= 20,
          currentPage: 1,
        );
        return;
      }

      // 2. Fallback temporário para o Firestore caso o banco ainda esteja migrando
      final query = FirebaseFirestore.instance.collection('movies')
          .orderBy('createdAt', descending: true)
          .limit(20);

      final snapshot = await query.get();
      final firestoreMovies = snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();

      state = PaginatedState<Movie>(
        items: firestoreMovies,
        isLoading: false,
        hasMore: firestoreMovies.length >= 20,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      print("Error loading initial movies: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      // Se estava usando a API REST
      if (state.currentPage > 0 && state.lastDoc == null) {
        final nextPage = state.currentPage + 1;
        final newMovies = await _api.getMovies(page: nextPage);

        state = state.copyWith(
          items: [...state.items, ...newMovies],
          isLoading: false,
          hasMore: newMovies.length >= 20,
          currentPage: nextPage,
        );
        return;
      }

      // Fallback Firestore
      if (state.lastDoc != null) {
        final query = FirebaseFirestore.instance.collection('movies')
            .orderBy('createdAt', descending: true)
            .startAfterDocument(state.lastDoc!)
            .limit(20);

        final snapshot = await query.get();
        final newMovies = snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();

        state = state.copyWith(
          items: [...state.items, ...newMovies],
          isLoading: false,
          hasMore: newMovies.length >= 20,
          lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDoc,
        );
      }
    } catch (e) {
      print("Error loading more movies: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedState<Movie>();
    await loadInitial();
  }
}

// ──────────────────────────────────────────────────────────
// SERIES NOTIFIER → Usa a API REST PostgreSQL
// ──────────────────────────────────────────────────────────
class SeriesNotifier extends StateNotifier<PaginatedState<Series>> {
  final SeriesApiService _api;

  SeriesNotifier(this._api) : super(const PaginatedState<Series>()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, currentPage: 1);

    try {
      final series = await _api.getSeries(page: 1);
      state = PaginatedState<Series>(
        items: series,
        isLoading: false,
        hasMore: series.length >= 20,
        currentPage: 1,
      );
    } catch (e) {
      print("Error loading initial series from API: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newSeries = await _api.getSeries(page: nextPage);

      state = state.copyWith(
        items: [...state.items, ...newSeries],
        isLoading: false,
        hasMore: newSeries.length >= 20,
        currentPage: nextPage,
      );
    } catch (e) {
      print("Error loading more series from API: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedState<Series>();
    await loadInitial();
  }
}

final paginatedMoviesProvider = StateNotifierProvider<MoviesNotifier, PaginatedState<Movie>>((ref) {
  final api = ref.watch(movieApiServiceProvider);
  return MoviesNotifier(api);
});

final paginatedSeriesProvider = StateNotifierProvider<SeriesNotifier, PaginatedState<Series>>((ref) {
  final api = ref.watch(seriesApiServiceProvider);
  return SeriesNotifier(api);
});

// ──────────────────────────────────────────────────────────
// NOTIFIERS PAGINADOS POR CATEGORIA / TAG
// ──────────────────────────────────────────────────────────

class CategoryMoviesNotifier extends StateNotifier<PaginatedState<Movie>> {
  final MovieApiService _api;
  final String tag;

  CategoryMoviesNotifier(this._api, this.tag) : super(const PaginatedState<Movie>()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, currentPage: 1);

    try {
      final movies = await _api.getMoviesByTag(tag, page: 1);
      state = PaginatedState<Movie>(
        items: movies,
        isLoading: false,
        hasMore: movies.length >= 20,
        currentPage: 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newMovies = await _api.getMoviesByTag(tag, page: nextPage);

      final existingIds = state.items.map((m) => m.id).toSet();
      final uniqueNew = newMovies.where((m) => !existingIds.contains(m.id)).toList();

      state = state.copyWith(
        items: [...state.items, ...uniqueNew],
        isLoading: false,
        hasMore: newMovies.length >= 20,
        currentPage: nextPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedState<Movie>();
    await loadInitial();
  }
}

class CategorySeriesNotifier extends StateNotifier<PaginatedState<Series>> {
  final SeriesApiService _api;
  final String tag;

  CategorySeriesNotifier(this._api, this.tag) : super(const PaginatedState<Series>()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, currentPage: 1);

    try {
      final series = await _api.getSeriesByTag(tag, page: 1);
      state = PaginatedState<Series>(
        items: series,
        isLoading: false,
        hasMore: series.length >= 20,
        currentPage: 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newSeries = await _api.getSeriesByTag(tag, page: nextPage);

      final existingIds = state.items.map((s) => s.id).toSet();
      final uniqueNew = newSeries.where((s) => !existingIds.contains(s.id)).toList();

      state = state.copyWith(
        items: [...state.items, ...uniqueNew],
        isLoading: false,
        hasMore: newSeries.length >= 20,
        currentPage: nextPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedState<Series>();
    await loadInitial();
  }
}

final categoryMoviesProvider = StateNotifierProvider.family<CategoryMoviesNotifier, PaginatedState<Movie>, String>((ref, tag) {
  final api = ref.watch(movieApiServiceProvider);
  return CategoryMoviesNotifier(api, tag);
});

final categorySeriesProvider = StateNotifierProvider.family<CategorySeriesNotifier, PaginatedState<Series>, String>((ref, tag) {
  final api = ref.watch(seriesApiServiceProvider);
  return CategorySeriesNotifier(api, tag);
});

// --- PROVIDERS EXISTENTES (para home_screen e outras telas) ---

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final movieApi = ref.watch(movieApiServiceProvider);
  final movies = await movieApi.getMovies(page: 1);
  if (movies.isNotEmpty) return movies;
  final service = ref.watch(firestoreServiceProvider);
  return service.getTrendingMovies();
});

final highlightsProvider = FutureProvider<List<dynamic>>((ref) async {
  final movieApi = ref.watch(movieApiServiceProvider);
  final seriesApi = ref.watch(seriesApiServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  // 1. Busca promoções e destaques ativos do Firestore configurados no Painel de Controle
  List<Promotion> activePromos = [];
  try {
    final promoSnap = await FirebaseFirestore.instance
        .collection('promotions')
        .where('isActive', isEqualTo: true)
        .get();
    final rawPromos = promoSnap.docs.map((doc) => Promotion.fromFirestore(doc)).toList();

    // Enriquece os itens de catálogo com sinopse e nota caso não tenham sido salvos diretamente no Firestore
    activePromos = await Future.wait(rawPromos.map((promo) async {
      if (promo.contentId != null && promo.contentId!.isNotEmpty) {
        final needsOverview = promo.overview == null || promo.overview!.isEmpty;
        final needsRating = promo.rating == null || promo.rating == 0.0;
        
        if (needsOverview || needsRating) {
          try {
            if (promo.contentType == 'tv') {
              final seriesId = int.tryParse(promo.contentId!) ?? 0;
              final series = await seriesApi.getSeriesById(seriesId);
              if (series != null) {
                return promo.copyWith(
                  overview: needsOverview ? series.overview : promo.overview,
                  rating: needsRating ? series.voteAverage : promo.rating,
                  backdropPath: promo.backdropPath ?? series.backdropPath,
                );
              }
            } else {
              final intId = int.tryParse(promo.contentId!);
              Movie? movie;
              if (intId != null) {
                movie = await movieApi.getMovieById(intId);
              }
              if (movie == null) {
                try {
                  movie = await firestoreService.getMovieDetail(promo.contentId!);
                } catch (_) {}
              }
              if (movie != null) {
                return promo.copyWith(
                  overview: needsOverview ? movie.overview : promo.overview,
                  rating: needsRating ? movie.voteAverage : promo.rating,
                  backdropPath: promo.backdropPath ?? movie.backdropPath,
                );
              }
            }
          } catch (e) {
            if (kDebugMode) print('Erro ao enriquecer destaque ${promo.title}: $e');
          }
        }
      }
      return promo;
    }));
  } catch (e) {
    if (kDebugMode) print('Erro ao buscar promoções para carrossel: $e');
  }

  // Se o painel de controle tiver destaques ativos, exibe EXATAMENTE o que o administrador definiu
  if (activePromos.isNotEmpty) {
    return activePromos;
  }

  // 2. Se o painel NÃO tiver nenhum destaque ativo cadastrado, busca destaques automáticos da API como fallback
  List<dynamic> apiHighlights = [];
  try {
    final movieHighlights = await movieApi.getHighlights();
    final seriesHighlights = await seriesApi.getHighlights();
    apiHighlights = [...movieHighlights, ...seriesHighlights];
    if (apiHighlights.isNotEmpty) {
      apiHighlights.shuffle();
      return apiHighlights;
    }
  } catch (e) {
    if (kDebugMode) print('Erro ao buscar destaques da API: $e');
  }

  return firestoreService.getHighlights();
});

final trendingSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(seriesApiServiceProvider);
  return api.getSeries(page: 1);
});

final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final movieApi = ref.watch(movieApiServiceProvider);
  final movies = await movieApi.getMovies(page: 1);
  if (movies.isNotEmpty) return movies;
  final service = ref.watch(firestoreServiceProvider);
  return service.getPopularMovies();
});

final popularSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(seriesApiServiceProvider);
  return api.getSeries(page: 1);
});

final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final movieApi = ref.watch(movieApiServiceProvider);
  final movies = await movieApi.getMovies(page: 1);
  if (movies.isNotEmpty) {
    final sorted = [...movies]..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    return sorted;
  }
  final service = ref.watch(firestoreServiceProvider);
  return service.getTopRatedMovies();
});

final topRatedSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(seriesApiServiceProvider);
  return api.getSeries(page: 1);
});

/// Filmes que são de fato LANÇAMENTOS (verificados pelo ano de lançamento real releaseDate >= 2024)
final nowPlayingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final movieApi = ref.watch(movieApiServiceProvider);
  final movies = await movieApi.getMovies(page: 1);

  final currentYear = DateTime.now().year;
  final minYear = currentYear - 2; // 2024 em diante

  final genuineReleases = movies.where((m) {
    final year = int.tryParse(m.year);
    return year != null && year >= minYear;
  }).toList();

  // Ordena por data de lançamento mais recente primeiro
  genuineReleases.sort((a, b) {
    final dA = a.releaseDate ?? '';
    final dB = b.releaseDate ?? '';
    return dB.compareTo(dA);
  });

  if (genuineReleases.isNotEmpty) return genuineReleases;

  // Fallback: se na página 1 tiver poucos, ordena todo o catálogo por ano decrescente
  final sorted = [...movies]..sort((a, b) {
    final yA = int.tryParse(a.year) ?? 0;
    final yB = int.tryParse(b.year) ?? 0;
    return yB.compareTo(yA);
  });
  return sorted;
});

/// Filmes adicionados recentemente no catálogo da plataforma
final newlyAddedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final movieApi = ref.watch(movieApiServiceProvider);
  return movieApi.getMovies(page: 1);
});

final movieDetailProvider = FutureProvider.family<Movie, String>((ref, id) async {
  final movieApi = ref.watch(movieApiServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  // 1. Tenta buscar pela API REST PostgreSQL primeiro (se id for numérico)
  final intId = int.tryParse(id);
  if (intId != null) {
    try {
      final movie = await movieApi.getMovieById(intId);
      if (movie != null) return movie;
    } catch (e) {
      print("MovieApiService.getMovieById failed: $e");
    }
  }

  // 2. Fallback para o Firestore
  try {
    return await firestoreService.getMovieDetail(id);
  } catch (e) {
    if (intId != null) {
      throw Exception('Filme não encontrado');
    }
    rethrow;
  }
});

final seriesDetailProvider = FutureProvider.family<Series, String>((ref, id) async {
  final api = ref.watch(seriesApiServiceProvider);
  final series = await api.getSeriesById(int.tryParse(id) ?? 0);
  if (series == null) throw Exception('Série não encontrada');
  return series;
});

/// Episódios via API REST → banco PostgreSQL (sem duplicatas garantido)
final seriesEpisodesProvider = FutureProvider.family<List<Episode>, String>((ref, seriesId) async {
  final api = ref.watch(seriesApiServiceProvider);
  return api.getEpisodes(int.tryParse(seriesId) ?? 0);
});

final searchProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  final seriesApiService = ref.watch(seriesApiServiceProvider);
  final movieApiService = ref.watch(movieApiServiceProvider);

  // Busca filmes e séries em paralelo na API PostgreSQL
  final results = await Future.wait([
    movieApiService.searchMovies(cleanQuery),
    seriesApiService.searchSeries(cleanQuery),
  ]);

  var movies = results[0] as List<Movie>;
  final series = results[1] as List<Series>;

  // Fallback para o Firestore caso a API de filmes ainda não tenha retornado itens
  if (movies.isEmpty) {
    try {
      movies = await firestoreService.searchContent(cleanQuery);
    } catch (_) {}
  }

  // Evita sobrescrita de chaves entre filmes e séries usando prefixo de tipo
  final combined = <String, dynamic>{};
  for (final movie in movies) {
    combined['movie_${movie.id}'] = movie;
  }
  for (final serie in series) {
    combined['series_${serie.id}'] = serie;
  }

  final list = combined.values.toList();

  // Reordena a lista combinada por relevância com o termo pesquisado
  final normalizedQuery = normalizeSearchText(cleanQuery);
  list.sort((a, b) {
    final titleA = a is Movie ? a.title : (a as Series).name;
    final titleB = b is Movie ? b.title : (b as Series).name;

    final normA = normalizeSearchText(titleA);
    final normB = normalizeSearchText(titleB);

    final exactA = normA == normalizedQuery;
    final exactB = normB == normalizedQuery;
    if (exactA && !exactB) return -1;
    if (!exactA && exactB) return 1;

    final startsA = normA.startsWith(normalizedQuery);
    final startsB = normB.startsWith(normalizedQuery);
    if (startsA && !startsB) return -1;
    if (!startsA && startsB) return 1;

    final containsA = normA.contains(normalizedQuery);
    final containsB = normB.contains(normalizedQuery);
    if (containsA && !containsB) return -1;
    if (!containsA && containsB) return 1;

    final ratingA = a is Movie ? a.voteAverage : (a as Series).voteAverage;
    final ratingB = b is Movie ? b.voteAverage : (b as Series).voteAverage;
    return ratingB.compareTo(ratingA);
  });

  return list;
});

final suggestionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  final apiService = ref.watch(seriesApiServiceProvider);

  final movies = await service.getTrendingMovies();
  final series = await apiService.getSeries(page: 1);

  final combined = [...movies.take(5), ...series.take(5)];
  combined.shuffle();
  return combined;
});

// CATEGORIES DINÂMICAS (Unificando Firestore, API e Catálogo)
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final seriesApiService = ref.watch(seriesApiServiceProvider);

  final categorySet = <String>{
    'Ação',
    'Aventura',
    'Animação',
    'Comédia',
    'Crime',
    'Documentário',
    'Drama',
    'Família',
    'Fantasia',
    'Ficção Científica',
    'Guerra',
    'Kids',
    'Mistério',
    'Música',
    'Romance',
    'Suspense',
    'Terror',
  };

  try {
    final firestoreCategories = await firestoreService.getCategories();
    for (final c in firestoreCategories) {
      if (c.trim().isNotEmpty) categorySet.add(c.trim());
    }
  } catch (_) {}

  try {
    final series = await seriesApiService.getAllSeries();
    for (final s in series) {
      for (final tag in s.tags) {
        final clean = tag.trim();
        if (clean.isNotEmpty && !clean.toLowerCase().contains('sci-fi & fantasy')) {
          categorySet.add(clean);
        }
      }
    }
  } catch (_) {}

  final list = categorySet.toList();
  list.sort((a, b) => a.compareTo(b));
  return list;
});

final contentByTagProvider = FutureProvider.family<List<dynamic>, String>((ref, tag) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final movieApiService = ref.watch(movieApiServiceProvider);
  final seriesApiService = ref.watch(seriesApiServiceProvider);

  final List<dynamic> results = [];
  final Set<String> seenIds = {};

  try {
    final apiMovies = await movieApiService.getMoviesByTag(tag);
    for (final m in apiMovies) {
      if (seenIds.add('m_${m.id}')) results.add(m);
    }
  } catch (_) {}

  try {
    final apiSeries = await seriesApiService.getSeriesByTag(tag);
    for (final s in apiSeries) {
      if (seenIds.add('s_${s.id}')) results.add(s);
    }
  } catch (_) {}

  try {
    final firestoreItems = await firestoreService.getContentByTag(tag);
    for (final item in firestoreItems) {
      final key = item is Movie ? 'm_${item.id}' : 's_${item.id}';
      if (seenIds.add(key)) results.add(item);
    }
  } catch (_) {}

  return results;
});

final movieGenresProvider = FutureProvider<List<dynamic>>((ref) async {
  return [];
});

final tvGenresProvider = FutureProvider<List<dynamic>>((ref) async {
  return [];
});

final moviesByGenreProvider = FutureProvider.family<List<Movie>, int>((ref, genreId) async {
  return [];
});

final seriesByGenreProvider = FutureProvider.family<List<Series>, int>((ref, genreId) async {
  return [];
});

class MediaParams {
  final String mediaType;
  final String id;
  const MediaParams({required this.mediaType, required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaParams &&
          runtimeType == other.runtimeType &&
          mediaType == other.mediaType &&
          id == other.id;

  @override
  int get hashCode => mediaType.hashCode ^ id.hashCode;
}

final creditsProvider = FutureProvider.family<List<CastMember>, MediaParams>((ref, params) async {
  if (params.id.isEmpty || params.id == '0') return [];
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getCredits(params.mediaType, int.parse(params.id));
});

final videosProvider = FutureProvider.family<List<Video>, MediaParams>((ref, params) async {
  if (params.id.isEmpty || params.id == '0') return [];
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getVideos(params.mediaType, int.parse(params.id));
});



