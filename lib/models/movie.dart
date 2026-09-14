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

  factory Movie.fromJson(Map<String, dynamic> json) => Movie.fromApi(json);

  factory Movie.fromApi(Map<String, dynamic> json) {
    int parsedTmdbId = 0;
    final rawTmdb = json['tmdb_id'] ?? json['tmdbId'];
    if (rawTmdb is int) {
      parsedTmdbId = rawTmdb;
    } else if (rawTmdb != null) {
      parsedTmdbId = int.tryParse(rawTmdb.toString()) ?? 0;
    }

    double parsedVote = 0.0;
    final rawVote = json['vote_average'] ?? json['voteAverage'];
    if (rawVote is num) {
      parsedVote = rawVote.toDouble();
    } else if (rawVote != null) {
      parsedVote = double.tryParse(rawVote.toString()) ?? 0.0;
    }

    return Movie(
      id: json['id']?.toString() ?? '',
      tmdbId: parsedTmdbId,
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? json['posterPath'],
      backdropPath: json['backdrop_path'] ?? json['backdropPath'],
      voteAverage: parsedVote,
      releaseDate: json['release_date'] ?? json['releaseDate'],
      videoUrl: json['video_url'] ?? json['videoUrl'],
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

  String get fullPosterUrl {
    if (posterPath == null) return '';
    final trimmed = posterPath!.trim();
    if (trimmed.isEmpty || trimmed == 'null') return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '${AppConstants.imageBaseUrlW500}$path';
  }

  String get fullBackdropUrl {
    if (backdropPath == null) return '';
    final trimmed = backdropPath!.trim();
    if (trimmed.isEmpty || trimmed == 'null') return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '${AppConstants.imageBaseUrlW1280}$path';
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    try {
      return DateTime.parse(releaseDate!).year.toString();
    } catch (e) {
      return releaseDate!.split('-').first;
    }
  }
}
