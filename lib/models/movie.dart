import 'package:poltro_play/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  final String id;
  final int tmdbId;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;
  final String? videoUrl;
  final List<String> tags;

  const Movie({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    this.videoUrl,
    this.tags = const [],
  });

  factory Movie.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Movie(
      id: doc.id,
      tmdbId: data['tmdbId'] ?? 0,
      title: data['title'] ?? '',
      overview: data['overview'] ?? '',
      posterPath: data['posterPath'],
      backdropPath: data['backdropPath'],
      voteAverage: (data['voteAverage'] ?? 0).toDouble(),
      releaseDate: data['releaseDate'],
      videoUrl: data['videoUrl'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Fallback if needed for parsing direct TMDB JSON (if any)
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      tmdbId: json['tmdbId'] is int ? json['tmdbId'] : (int.tryParse(json['tmdbId']?.toString() ?? '') ?? 0),
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? json['posterPath'],
      backdropPath: json['backdrop_path'] ?? json['backdropPath'],
      voteAverage: (json['vote_average'] ?? json['voteAverage'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? json['releaseDate'],
      videoUrl: json['videoUrl'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'releaseDate': releaseDate,
      'videoUrl': videoUrl,
      'tags': tags,
    };
  }

  String get fullPosterUrl => posterPath != null 
      ? '${AppConstants.imageBaseUrlW500}$posterPath' 
      : 'https://via.placeholder.com/500x750.png?text=No+Poster';

  String get fullBackdropUrl => backdropPath != null 
      ? '${AppConstants.imageBaseUrlW1280}$backdropPath' 
      : 'https://via.placeholder.com/1280x720.png?text=No+Backdrop';

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    try {
      return DateTime.parse(releaseDate!).year.toString();
    } catch (e) {
      return releaseDate!.split('-').first;
    }
  }
}
