import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/promotion.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- MOVIES ---

  Future<List<Movie>> getTrendingMovies() async {
    try {
      // Assuming 'xtream' or 'recent' tag means trending, or sort by createdAt
      final snapshot = await _db.collection('movies')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
          
      return snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching trending movies: $e");
      return [];
    }
  }

  Future<List<Movie>> getPopularMovies() async {
    try {
      final snapshot = await _db.collection('movies')
          .orderBy('voteAverage', descending: true)
          .limit(20)
          .get();
          
      return snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching popular movies: $e");
      return [];
    }
  }
  
  Future<List<Movie>> getTopRatedMovies() async {
    return getPopularMovies(); // Same for now
  }
  
  Future<List<Movie>> getNowPlayingMovies() async {
    return getTrendingMovies(); // Same for now
  }

  Future<Movie> getMovieDetail(String id) async {
    try {
      final doc = await _db.collection('movies').doc(id).get();
      if (doc.exists) {
        return Movie.fromFirestore(doc);
      }
      throw Exception('Filme não encontrado');
    } catch (e) {
      print("Error fetching movie details: $e");
      rethrow;
    }
  }

  // --- SERIES ---

  Future<List<Series>> getTrendingSeries() async {
    try {
      final snapshot = await _db.collection('series')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
          
      return snapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching trending series: $e");
      return [];
    }
  }

  Future<List<Series>> getPopularSeries() async {
    try {
      final snapshot = await _db.collection('series')
          .orderBy('voteAverage', descending: true)
          .limit(20)
          .get();
          
      return snapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching popular series: $e");
      return [];
    }
  }

  Future<List<Series>> getTopRatedSeries() async {
    return getPopularSeries();
  }

  Future<Series> getSeriesDetail(String id) async {
    try {
      final doc = await _db.collection('series').doc(id).get();
      if (doc.exists) {
        return Series.fromFirestore(doc);
      }
      throw Exception('Série não encontrada');
    } catch (e) {
      print("Error fetching series details: $e");
      rethrow;
    }
  }

  // --- SEARCH ---

  Future<List<dynamic>> searchContent(String query) async {
    if (query.isEmpty) return [];
    
    // Very basic search simulation (Firestore doesn't support full-text search easily)
    // In a real app, Algolia or a cloud function is better.
    // We'll fetch all and filter locally for MVP
    try {
      final lowerQuery = query.toLowerCase();
      
      final moviesSnap = await _db.collection('movies').get();
      final movies = moviesSnap.docs
          .map((doc) => Movie.fromFirestore(doc))
          .where((m) => m.title.toLowerCase().contains(lowerQuery))
          .toList();
          
      final seriesSnap = await _db.collection('series').get();
      final seriesList = seriesSnap.docs
          .map((doc) => Series.fromFirestore(doc))
          .where((s) => s.name.toLowerCase().contains(lowerQuery))
          .toList();
          
      return [...movies, ...seriesList];
    } catch (e) {
      print("Error searching content: $e");
      return [];
    }
  }

  // --- HIGHLIGHTS ---
  Future<List<dynamic>> getHighlights() async {
    try {
      final moviesSnap = await _db.collection('movies').where('isHighlight', isEqualTo: true).get();
      final movies = moviesSnap.docs.map((doc) => Movie.fromFirestore(doc)).toList();

      final seriesSnap = await _db.collection('series').where('isHighlight', isEqualTo: true).get();
      final series = seriesSnap.docs.map((doc) => Series.fromFirestore(doc)).toList();
      
      final promoSnap = await _db.collection('promotions').where('isActive', isEqualTo: true).get();
      final promos = promoSnap.docs.map((doc) => Promotion.fromFirestore(doc)).toList();

      final highlights = [...movies, ...series, ...promos];
      
      // Se não houver nenhum destaque e nenhuma promoção, retorna os mais recentes misturados
      if (highlights.isEmpty) {
        final recentMovies = await getTrendingMovies();
        final recentSeries = await getTrendingSeries();
        return [...recentMovies.take(5), ...recentSeries.take(5)];
      }
      
      highlights.shuffle();
      return highlights;
    } catch (e) {
      print("Error fetching highlights: $e");
      return [];
    }
  }

  // --- CATEGORIES (TAGS) ---
  Future<List<String>> getCategories() async {
    try {
      final snap = await _db.collection('categories').get();
      return snap.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  Future<List<dynamic>> getContentByTag(String tag) async {
    try {
      final moviesSnap = await _db.collection('movies').where('tags', arrayContains: tag).get();
      final movies = moviesSnap.docs.map((doc) => Movie.fromFirestore(doc)).toList();

      final seriesSnap = await _db.collection('series').where('tags', arrayContains: tag).get();
      final series = seriesSnap.docs.map((doc) => Series.fromFirestore(doc)).toList();

      final results = [...movies, ...series];
      results.shuffle();
      return results;
    } catch (e) {
      print("Error fetching content by tag: $e");
      return [];
    }
  }

  // --- USER SYNC (FAVORITES E WATCH PROGRESS) ---
  
  Future<void> syncFavorite(String uid, dynamic item) async {
    try {
      final isMovie = item is Movie;
      final type = isMovie ? 'movie' : 'series';
      final data = item.toJson();
      data['contentType'] = type;

      await _db.collection('users').doc(uid).collection('favorites').doc(item.id).set(data);
    } catch (e) {
      print("Error syncing favorite: $e");
    }
  }

  Future<void> removeFavorite(String uid, String contentId) async {
    try {
      await _db.collection('users').doc(uid).collection('favorites').doc(contentId).delete();
    } catch (e) {
      print("Error removing favorite: $e");
    }
  }

  Future<List<dynamic>> getUserFavorites(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid).collection('favorites').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['contentType'] == 'series') {
          return Series.fromJson(data);
        } else {
          return Movie.fromJson(data);
        }
      }).toList();
    } catch (e) {
      print("Error getting user favorites: $e");
      return [];
    }
  }

  Future<void> syncWatchProgress(String uid, Map<String, dynamic> progressJson, String contentId) async {
    try {
      await _db.collection('users').doc(uid).collection('watch_progress').doc(contentId).set(progressJson);
    } catch (e) {
      print("Error syncing watch progress: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getUserWatchProgress(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid).collection('watch_progress').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error getting user watch progress: $e");
      return [];
    }
  }
}
