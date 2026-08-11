import 'package:poltro_play/core/constants/app_constants.dart';

class WatchProgress {
  final String contentId;
  final String contentType;
  final String title;
  final String? posterPath;
  final String videoUrl;
  final int positionMs;
  final int durationMs;
  final DateTime lastWatched;

  WatchProgress({
    required this.contentId,
    required this.contentType,
    required this.title,
    this.posterPath,
    required this.videoUrl,
    required this.positionMs,
    required this.durationMs,
    required this.lastWatched,
  });

  factory WatchProgress.fromJson(Map<String, dynamic> json) {
    return WatchProgress(
      contentId: json['contentId'].toString(),
      contentType: json['contentType'] as String,
      title: json['title'] as String,
      posterPath: json['posterPath'] as String?,
      videoUrl: json['videoUrl'] as String? ?? 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      positionMs: json['positionMs'] as int,
      durationMs: json['durationMs'] as int,
      lastWatched: DateTime.parse(json['lastWatched'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'title': title,
      'posterPath': posterPath,
      'videoUrl': videoUrl,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'lastWatched': lastWatched.toIso8601String(),
    };
  }

  double get progressPercent => durationMs > 0 ? positionMs / durationMs : 0.0;

  String get formattedRemaining {
    final remainingMs = durationMs - positionMs;
    if (remainingMs <= 0) return '0m';
    
    final minutes = (remainingMs / (1000 * 60)).floor();
    final hours = (minutes / 60).floor();
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes}m';
  }

  String get fullPosterUrl => posterPath != null
      ? '${AppConstants.imageBaseUrlW185}$posterPath'
      : '';
}
