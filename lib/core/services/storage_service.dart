import 'package:hive_ce/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poltro_play/models/watch_progress.dart';

class StorageService {
  static const String _watchProgressBox = 'watch_progress_box';
  static const String _userPrefsBox = 'user_prefs_box';

  Future<void> init() async {
    await Hive.openBox(_watchProgressBox);
    await Hive.openBox(_userPrefsBox);
  }

  Future<void> saveWatchProgress(WatchProgress progress) async {
    // Save locally
    final box = Hive.box(_watchProgressBox);
    await box.put(progress.contentId.toString(), progress.toJson());

    // Sync to Firestore remotely (fire and forget)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('watch_progress')
            .doc(progress.contentId)
            .set(progress.toJson(), SetOptions(merge: true));
      } catch (e) {
        // Ignore network errors in background sync
      }
    }
  }

  WatchProgress? getWatchProgress(String contentId) {
    final box = Hive.box(_watchProgressBox);
    final data = box.get(contentId.toString());
    if (data != null) {
      return WatchProgress.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> removeWatchProgress(String contentId) async {
    final box = Hive.box(_watchProgressBox);
    await box.delete(contentId.toString());
  }

  List<WatchProgress> getAllWatchProgress() {
    final box = Hive.box(_watchProgressBox);
    return box.values
        .map((data) => WatchProgress.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  Future<void> clearWatchProgress() async {
    final box = Hive.box(_watchProgressBox);
    await box.clear();
  }

  Future<void> saveUserPref(String key, dynamic value) async {
    final box = Hive.box(_userPrefsBox);
    await box.put(key, value);
  }

  dynamic getUserPref(String key, {dynamic defaultValue}) {
    final box = Hive.box(_userPrefsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> removeUserPref(String key) async {
    final box = Hive.box(_userPrefsBox);
    await box.delete(key);
  }
}
