import 'package:poltro_play/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Series {
  final String id;
  final int tmdbId;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? firstAirDate;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final String? videoUrl; // Sometimes useful if it's a single stream, though usually episodes handle this
  final List<String> tags;

  const Series({
    required this.id,
    required this.tmdbId,
    required this.name,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.firstAirDate,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.videoUrl,
    this.tags = const [],
  });

  factory Series.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Series(
      id: doc.id,
      tmdbId: data['tmdbId'] ?? 0,
      name: data['title'] ?? data['name'] ?? '',
      overview: data['overview'] ?? '',
      posterPath: data['posterPath'],
      backdropPath: data['backdropPath'],
      voteAverage: (data['voteAverage'] ?? 0).toDouble(),
      firstAirDate: data['firstAirDate'],
      numberOfSeasons: data['numberOfSeasons'],
      numberOfEpisodes: data['numberOfEpisodes'],
      videoUrl: data['videoUrl'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id']?.toString() ?? '',
      tmdbId: json['tmdbId'] is int ? json['tmdbId'] : (int.tryParse(json['tmdbId']?.toString() ?? '') ?? 0),
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? json['posterPath'],
      backdropPath: json['backdrop_path'] ?? json['backdropPath'],
      voteAverage: (json['vote_average'] ?? json['voteAverage'] ?? 0).toDouble(),
      firstAirDate: json['first_air_date'] ?? json['firstAirDate'],
      numberOfSeasons: json['number_of_seasons'] ?? json['numberOfSeasons'],
      numberOfEpisodes: json['number_of_episodes'] ?? json['numberOfEpisodes'],
      videoUrl: json['videoUrl'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  /// Constrói Series a partir da resposta da API REST PostgreSQL (campos em snake_case)
  factory Series.fromApi(Map<String, dynamic> json) {
    return Series(
      id: json['id']?.toString() ?? '',
      tmdbId: (json['tmdb_id'] ?? json['tmdbId'] ?? 0) is int
          ? (json['tmdb_id'] ?? json['tmdbId'] ?? 0)
          : int.tryParse((json['tmdb_id'] ?? json['tmdbId'] ?? '0').toString()) ?? 0,
      name: json['title'] ?? json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? json['posterPath'],
      backdropPath: json['backdrop_path'] ?? json['backdropPath'],
      voteAverage: json['vote_average'] != null 
          ? (double.tryParse(json['vote_average'].toString()) ?? 0.0) 
          : (json['voteAverage'] != null ? (double.tryParse(json['voteAverage'].toString()) ?? 0.0) : 0.0),
      firstAirDate: json['release_date'] ?? json['first_air_date'] ?? json['firstAirDate'],
      numberOfSeasons: null,
      numberOfEpisodes: null,
      videoUrl: null,
      tags: () {
        final t = json['tags'];
        if (t is List) {
          return t.map((e) => e.toString()).toList();
        } else if (t is String && t.trim().isNotEmpty) {
          return t
              .split(RegExp(r'[,;]|\s{2,}'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return <String>[];
      }(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'name': name,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'firstAirDate': firstAirDate,
      'numberOfSeasons': numberOfSeasons,
      'numberOfEpisodes': numberOfEpisodes,
      'videoUrl': videoUrl,
      'tags': tags,
    };
  }

  String get fullPosterUrl {
    if (posterPath == null) return 'https://via.placeholder.com/500x750.png?text=No+Poster';
    if (posterPath!.startsWith('http')) return posterPath!;
    return '${AppConstants.imageBaseUrlW500}$posterPath';
  }

  String get fullBackdropUrl {
    if (backdropPath == null) return 'https://via.placeholder.com/1280x720.png?text=No+Backdrop';
    if (backdropPath!.startsWith('http')) return backdropPath!;
    return '${AppConstants.imageBaseUrlW1280}$backdropPath';
  }

  String get year {
    if (firstAirDate == null || firstAirDate!.isEmpty) return '';
    try {
      return DateTime.parse(firstAirDate!).year.toString();
    } catch (e) {
      return firstAirDate!.split('-').first;
    }
  }
}
