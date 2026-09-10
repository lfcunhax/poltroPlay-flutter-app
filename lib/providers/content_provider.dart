import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poltro_play/core/services/firestore_service.dart';
import 'package:poltro_play/core/services/series_api_service.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/cast.dart';
import 'package:poltro_play/models/video.dart';
import 'package:poltro_play/models/episode.dart';
import 'package:poltro_play/core/services/tmdb_service.dart';
import 'package:poltro_play/core/utils/string_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

final seriesApiServiceProvider = Provider<SeriesApiService>((ref) {
  return SeriesApiService();
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
  MoviesNotifier() : super(const PaginatedState<Movie>()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final query = FirebaseFirestore.instance.collection('movies')
          .orderBy('createdAt', descending: true)
          .limit(20);

      final snapshot = await query.get();
      final movies = snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();

      state = PaginatedState<Movie>(
        items: movies,
        isLoading: false,
        hasMore: movies.length >= 20,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      print("Error loading initial movies: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoading: true);

    try {
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
  return MoviesNotifier();
});

final paginatedSeriesProvider = StateNotifierProvider<SeriesNotifier, PaginatedState<Series>>((ref) {
  final api = ref.watch(seriesApiServiceProvider);
  return SeriesNotifier(api);
});

// --- PROVIDERS EXISTENTES (para home_screen e outras telas) ---

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTrendingMovies();
});

final highlightsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getHighlights();
});

final trendingSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(seriesApiServiceProvider);
  return api.getSeries(page: 1);
});

final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getPopularMovies();
});

final popularSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(seriesApiServiceProvider);
  return api.getSeries(page: 1);
});

final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTopRatedMovies();
});

final topRatedSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(seriesApiServiceProvider);
  return api.getSeries(page: 1);
});

final nowPlayingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getNowPlayingMovies();
});

final movieDetailProvider = FutureProvider.family<Movie, String>((ref, id) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getMovieDetail(id);
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
  final apiService = ref.watch(seriesApiServiceProvider);

  // Busca filmes no Firestore e séries na API em paralelo
  final results = await Future.wait([
    firestoreService.searchContent(cleanQuery),
    apiService.searchSeries(cleanQuery),
  ]);

  final movies = results[0] as List<Movie>;
  final series = results[1] as List<Series>;

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

// CATEGORIES FROM FIRESTORE
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getCategories();
});

final contentByTagProvider = FutureProvider.family<List<dynamic>, String>((ref, tag) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getContentByTag(tag);
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



