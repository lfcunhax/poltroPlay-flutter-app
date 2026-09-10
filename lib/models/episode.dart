import 'package:cloud_firestore/cloud_firestore.dart';

class Episode {
  final String id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String videoUrl;

  const Episode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.videoUrl,
  });

  factory Episode.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Episode(
      id: doc.id,
      seasonNumber: data['seasonNumber'] ?? 1,
      episodeNumber: data['episodeNumber'] ?? 1,
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
    );
  }

  /// Constrói Episode a partir da resposta da API REST PostgreSQL (snake_case)
  factory Episode.fromApi(Map<String, dynamic> json) {
    return Episode(
      id: json['id']?.toString() ?? '',
      seasonNumber: int.tryParse((json['season_number'] ?? json['seasonNumber'] ?? '1').toString()) ?? 1,
      episodeNumber: int.tryParse((json['episode_number'] ?? json['episodeNumber'] ?? '1').toString()) ?? 1,
      title: json['title'] ?? '',
      videoUrl: json['video_url'] ?? json['videoUrl'] ?? '',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'title': title,
      'videoUrl': videoUrl,
    };
  }
}
