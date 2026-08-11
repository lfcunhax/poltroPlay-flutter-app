import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poltro_play/core/services/storage_service.dart';
import 'package:poltro_play/core/services/firestore_service.dart';
import 'package:poltro_play/models/watch_progress.dart';
import 'package:poltro_play/providers/auth_provider.dart';
import 'package:poltro_play/providers/favorites_provider.dart'; // Para acessar o firestoreServiceProvider

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final watchProgressListProvider = StateNotifierProvider<WatchProgressNotifier, List<WatchProgress>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userAsync = ref.watch(authStateProvider);
  return WatchProgressNotifier(storageService, firestoreService, userAsync.value);
});

class WatchProgressNotifier extends StateNotifier<List<WatchProgress>> {
  final StorageService _storageService;
  final FirestoreService _firestoreService;
  final User? _user;

  WatchProgressNotifier(this._storageService, this._firestoreService, this._user) : super([]) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    // 1. Carrega o progresso local (rápido)
    final localProgress = _storageService.getAllWatchProgress();
    state = localProgress;

    // 2. Se logado, busca da nuvem e mescla/atualiza o local
    if (_user != null) {
      final cloudProgressJsonList = await _firestoreService.getUserWatchProgress(_user.uid);
      if (cloudProgressJsonList.isNotEmpty) {
        final cloudProgress = cloudProgressJsonList.map((json) => WatchProgress.fromJson(json)).toList();
        
        // Mesclar local e cloud (simplificado: cloud substitui local se for mais recente)
        for (var cp in cloudProgress) {
          final lp = localProgress.where((l) => l.contentId == cp.contentId).firstOrNull;
          if (lp == null || cp.lastWatched.isAfter(lp.lastWatched)) {
            await _storageService.saveWatchProgress(cp);
          }
        }
        
        // Atualiza o estado final da UI
        state = _storageService.getAllWatchProgress();
      }
    }
  }

  Future<void> saveProgress(WatchProgress progress) async {
    // Salva local (instantâneo)
    await _storageService.saveWatchProgress(progress);
    
    // Atualiza a UI
    state = _storageService.getAllWatchProgress();

    // Salva na nuvem silenciosamente
    if (_user != null) {
      await _firestoreService.syncWatchProgress(_user.uid, progress.toJson(), progress.contentId);
    }
  }

  Future<void> removeProgress(String contentId) async {
    await _storageService.removeWatchProgress(contentId);
    state = _storageService.getAllWatchProgress();
    
    // Obs: Se quisermos deletar da nuvem também, precisaria de um método no FirestoreService.
    // Como é apenas histórico, remover local geralmente basta, mas o ideal seria sync completo.
  }

  Future<void> clearAllProgress() async {
    await _storageService.clearWatchProgress();
    state = _storageService.getAllWatchProgress();
  }
}
