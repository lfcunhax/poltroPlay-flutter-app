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
