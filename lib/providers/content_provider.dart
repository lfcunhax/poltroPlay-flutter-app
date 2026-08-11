import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poltro_play/core/services/firestore_service.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/cast.dart';
import 'package:poltro_play/models/video.dart';
import 'package:poltro_play/models/genre.dart';
import 'package:poltro_play/models/episode.dart';
import 'package:poltro_play/core/services/tmdb_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTrendingMovies();
});

final highlightsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getHighlights();
});

final trendingSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTrendingSeries();
});

final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getPopularMovies();
});

final popularSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getPopularSeries();
});

final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTopRatedMovies();
});

final topRatedSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTopRatedSeries();
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
  final doc = await FirebaseFirestore.instance.collection('series').doc(id).get();
  if (!doc.exists) throw Exception('Série não encontrada');
  return Series.fromFirestore(doc);
});

final seriesEpisodesProvider = FutureProvider.family<List<Episode>, String>((ref, seriesId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('series')
      .doc(seriesId)
      .collection('episodes')
      .get();
      
  final episodes = querySnapshot.docs.map((doc) => Episode.fromFirestore(doc)).toList();
  
  // Ordenar no cliente para evitar erros de índice composto no Firestore
  episodes.sort((a, b) {
    if (a.seasonNumber != b.seasonNumber) return a.seasonNumber.compareTo(b.seasonNumber);
    return a.episodeNumber.compareTo(b.episodeNumber);
  });
  
  return episodes;
});

final searchProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.searchContent(query);
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
  return []; // To be implemented with Firestore tags
});

final tvGenresProvider = FutureProvider<List<dynamic>>((ref) async {
  return []; // To be implemented with Firestore tags
});

// For now, these can return empty or we could filter by tags
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
