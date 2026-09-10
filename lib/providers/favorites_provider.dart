import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poltro_play/core/services/firestore_service.dart';
import 'package:poltro_play/providers/auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FavoritesNotifier extends StateNotifier<List<dynamic>> {
  final FirestoreService _firestore;
  final User? _user;

  FavoritesNotifier(this._firestore, this._user) : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_user != null) {
      final cloudFavorites = await _firestore.getUserFavorites(_user.uid);
      state = cloudFavorites;
    } else {
      state = [];
    }
  }

  bool isFavorite(dynamic item) {
    return state.any((e) => e.id == item.id);
  }

  Future<void> toggleFavorite(dynamic item) async {
    if (isFavorite(item)) {
      state = state.where((e) => e.id != item.id).toList();
      if (_user != null) {
        await _firestore.removeFavorite(_user.uid, item.id.toString());
      }
    } else {
      state = [...state, item];
      if (_user != null) {
        await _firestore.syncFavorite(_user.uid, item);
      }
    }
  }

  Future<void> removeFavorite(String id) async {
    state = state.where((e) => e.id.toString() != id).toList();
    if (_user != null) {
      await _firestore.removeFavorite(_user.uid, id.toString());
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<dynamic>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final userAsync = ref.watch(authStateProvider);
  
  return FavoritesNotifier(firestore, userAsync.value);
});
