import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/promotion.dart';
import 'package:poltro_play/core/utils/string_utils.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int _pageSize = 20;

  // --- MOVIES (com paginação) ---

  Future<List<Movie>> getMovies({DocumentSnapshot? lastDoc}) async {
    try {
      Query query = _db.collection('movies')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Movie.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    } catch (e) {
      print("Error fetching movies: $e");
      return [];
    }
  }

  // Mantém métodos antigos para compatibilidade com home_screen
  Future<List<Movie>> getTrendingMovies() async {
    try {
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
  
  Future<List<Movie>> getTopRatedMovies() async => getPopularMovies();
  Future<List<Movie>> getNowPlayingMovies() async => getTrendingMovies();

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

  // --- SERIES (com paginação) ---

  Future<List<Series>> getSeries({DocumentSnapshot? lastDoc}) async {
    try {
      Query query = _db.collection('series')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Series.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    } catch (e) {
      print("Error fetching series: $e");
      return [];
    }
  }

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

  Future<List<Series>> getTopRatedSeries() async => getPopularSeries();

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

  // --- SEARCH (otimizado com Firestore Range Queries + Cache Local) ---

  List<Movie>? _movieCatalogCache;
  bool _isSyncingCatalog = false;

  /// Retorna catálogo de filmes do cache em memória/Hive ou sincroniza do Firestore
  Future<List<Movie>> getCachedMovieCatalog() async {
    if (_movieCatalogCache != null && _movieCatalogCache!.isNotEmpty) {
      return _movieCatalogCache!;
    }

    try {
      if (Hive.isBoxOpen('user_prefs_box')) {
        final box = Hive.box('user_prefs_box');
        final raw = box.get('movie_catalog_cache');
        if (raw is List) {
          final list = raw
              .map((item) => Movie.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          if (list.isNotEmpty) {
            _movieCatalogCache = list;
            _syncMovieCatalogInBackground();
            return list;
          }
        }
      }
    } catch (_) {}

    return await _syncMovieCatalog();
  }

  void _syncMovieCatalogInBackground() {
    if (_isSyncingCatalog) return;
    _syncMovieCatalog().catchError((_) => <Movie>[]);
  }

  Future<List<Movie>> _syncMovieCatalog() async {
    if (_isSyncingCatalog) return _movieCatalogCache ?? [];
    _isSyncingCatalog = true;

    try {
      final snapshot = await _db.collection('movies').get();
      final movies = snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();

      if (movies.isNotEmpty) {
        _movieCatalogCache = movies;
        try {
          if (Hive.isBoxOpen('user_prefs_box')) {
            final box = Hive.box('user_prefs_box');
            final serialized = movies.map((m) => m.toJson()).toList();
            await box.put('movie_catalog_cache', serialized);
          }
        } catch (_) {}
      }
      return movies;
    } catch (e) {
      print("Error syncing movie catalog: $e");
      return _movieCatalogCache ?? [];
    } finally {
      _isSyncingCatalog = false;
    }
  }

  Future<List<Movie>> searchContent(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final normalizedQuery = normalizeSearchText(cleanQuery);
    final queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

    // 1. Busca range no Firestore por variações de prefixos no campo 'title'
    final prefixes = generateSearchPrefixes(cleanQuery);
    final firestoreFutures = prefixes.map((p) {
      return _db.collection('movies')
          .where('title', isGreaterThanOrEqualTo: p)
          .where('title', isLessThanOrEqualTo: '$p\uf8ff')
          .limit(20)
          .get()
          .then((snap) => snap.docs.map((doc) => Movie.fromFirestore(doc)).toList())
          .catchError((_) => <Movie>[]);
    });

    // 2. Busca no catálogo em cache para termos no meio do título e buscas sem acento
    final catalogFuture = getCachedMovieCatalog();

    final firestoreResults = await Future.wait(firestoreFutures);
    final catalog = await catalogFuture;

    final resultMap = <String, Movie>{};

    // Adiciona correspondências diretas do Firestore
    for (final list in firestoreResults) {
      for (final movie in list) {
        resultMap[movie.id] = movie;
      }
    }

    // Busca no catálogo completo com normalização de texto e acentos
    for (final movie in catalog) {
      final normalizedTitle = normalizeSearchText(movie.title);

      // Correspondência direta da query normalizada
      if (normalizedTitle.contains(normalizedQuery)) {
        resultMap[movie.id] = movie;
        continue;
      }

      // Se todas as palavras pesquisadas existem no título
      if (queryWords.length > 1 && queryWords.every((w) => normalizedTitle.contains(w))) {
        resultMap[movie.id] = movie;
      }
    }

    final combined = resultMap.values.toList();

    // 3. Ordenação por relevância:
    // Exato > Começa com a query > Contém a query > Desempate por avaliação
    combined.sort((a, b) {
      final aNorm = normalizeSearchText(a.title);
      final bNorm = normalizeSearchText(b.title);

      final aExact = aNorm == normalizedQuery;
      final bExact = bNorm == normalizedQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aStarts = aNorm.startsWith(normalizedQuery);
      final bStarts = bNorm.startsWith(normalizedQuery);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      final aContains = aNorm.contains(normalizedQuery);
      final bContains = bNorm.contains(normalizedQuery);
      if (aContains && !bContains) return -1;
      if (!aContains && bContains) return 1;

      return b.voteAverage.compareTo(a.voteAverage);
    });

    return combined;
  }

  // Sugestões para a tela de busca (filmes populares)
  Future<List<dynamic>> getSuggestions() async {
    try {
      final moviesSnap = await _db.collection('movies')
          .orderBy('voteAverage', descending: true)
          .limit(10)
          .get();
      final movies = moviesSnap.docs.map((doc) => Movie.fromFirestore(doc)).toList();

      final seriesSnap = await _db.collection('series')
          .orderBy('voteAverage', descending: true)
          .limit(10)
          .get();
      final series = seriesSnap.docs.map((doc) => Series.fromFirestore(doc)).toList();

      final suggestions = [...movies, ...series];
      suggestions.shuffle();
      return suggestions;
    } catch (e) {
      print("Error fetching suggestions: $e");
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
