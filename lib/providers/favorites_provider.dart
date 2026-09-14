import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive.dart';
import 'package:poltro_play/core/services/firestore_service.dart';
import 'package:poltro_play/providers/auth_provider.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FavoritesNotifier extends StateNotifier<List<dynamic>> {
  final FirestoreService _firestore;
  final User? _user;
  static const String _cacheKey = 'local_favorites_list';

  FavoritesNotifier(this._firestore, this._user) : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // 1. Carrega do cache local offline imediatamente para inicialização instantânea
    final localItems = _loadFromLocalCache();
    if (localItems.isNotEmpty) {
      state = localItems;
    }

    // 2. Se logado, sincroniza com o Firestore
    if (_user != null) {
      try {
        final cloudFavorites = await _firestore.getUserFavorites(_user.uid);
        if (cloudFavorites.isNotEmpty || localItems.isEmpty) {
          state = cloudFavorites;
          _saveToLocalCache(cloudFavorites);
        }
      } catch (_) {
        // Ignora erro de rede temporário na sincronização da nuvem
      }
    }
  }

  void _saveToLocalCache(List<dynamic> list) {
    try {
      if (Hive.isBoxOpen('user_prefs_box')) {
        final box = Hive.box('user_prefs_box');
        final serialized = list.map((item) {
          final map = Map<String, dynamic>.from(item.toJson());
          map['contentType'] = item is Movie ? 'movie' : 'series';
          map['id'] = item.id.toString();
          return map;
        }).toList();
        box.put(_cacheKey, serialized);
      }
    } catch (_) {}
  }

  List<dynamic> _loadFromLocalCache() {
    try {
      if (Hive.isBoxOpen('user_prefs_box')) {
        final box = Hive.box('user_prefs_box');
        final raw = box.get(_cacheKey);
        if (raw is List) {
          return raw.map((item) {
            final map = Map<String, dynamic>.from(item);
            if (map['contentType'] == 'series') {
              return Series.fromJson(map);
            } else {
              return Movie.fromJson(map);
            }
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  bool isFavorite(dynamic item) {
    final targetId = item.id.toString().trim();
    final targetTitle = (item is Movie ? item.title : (item is Series ? item.name : '')).trim().toLowerCase();

    return state.any((e) {
      final eId = e.id.toString().trim();
      if (eId.isNotEmpty && eId == targetId) return true;
      if (targetTitle.isNotEmpty) {
        final eTitle = (e is Movie ? e.title : (e as Series).name).trim().toLowerCase();
        if (eTitle.isNotEmpty && eTitle == targetTitle) return true;
      }
      return false;
    });
  }

  Future<void> toggleFavorite(dynamic item) async {
    final targetId = item.id.toString().trim();
    final title = (item is Movie ? item.title : (item is Series ? item.name : '')).trim();

    if (isFavorite(item)) {
      await removeFavorite(targetId, title: title);
    } else {
      state = [...state, item];
      _saveToLocalCache(state);
      if (_user != null) {
        await _firestore.syncFavorite(_user.uid, item);
      }
    }
  }

  Future<void> removeFavorite(String id, {String? title}) async {
    final targetId = id.toString().trim();
    final targetTitle = title?.trim().toLowerCase() ?? '';

    state = state.where((e) {
      final eId = e.id.toString().trim();
      if (targetId.isNotEmpty && eId == targetId) return false;
      if (targetTitle.isNotEmpty) {
        final eTitle = (e is Movie ? e.title : (e as Series).name).trim().toLowerCase();
        if (eTitle == targetTitle) return false;
      }
      return true;
    }).toList();

    _saveToLocalCache(state);

    if (_user != null) {
      await _firestore.removeFavorite(_user.uid, targetId, title: title);
    }
  }

  /// Limpa itens teimosos (ex: Casa do Dragão) por busca de texto
  Future<void> removeStubbornFavorite(String query) async {
    final norm = query.toLowerCase().trim();
    state = state.where((e) {
      final eTitle = (e is Movie ? e.title : (e as Series).name).toLowerCase();
      final eId = e.id.toString().toLowerCase();
      return !eTitle.contains(norm) && !eId.contains(norm);
    }).toList();

    _saveToLocalCache(state);

    if (_user != null) {
      await _firestore.forceRemoveFavoritesMatching(_user.uid, query);
    }
  }

  Future<void> clearAllFavorites() async {
    final current = [...state];
    state = [];
    _saveToLocalCache([]);

    if (_user != null) {
      for (final item in current) {
        final title = (item is Movie ? item.title : (item is Series ? item.name : ''));
        await _firestore.removeFavorite(_user.uid, item.id.toString(), title: title);
      }
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<dynamic>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final userAsync = ref.watch(authStateProvider);
  
  return FavoritesNotifier(firestore, userAsync.value);
});
