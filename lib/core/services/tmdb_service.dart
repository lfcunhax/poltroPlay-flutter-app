import 'package:dio/dio.dart';
import 'package:poltro_play/core/constants/app_constants.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/genre.dart';
import 'package:poltro_play/models/cast.dart';
import 'package:poltro_play/models/video.dart';

class TmdbService {
  final Dio _dio;

  TmdbService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.tmdbBaseUrl,
          queryParameters: {
            'api_key': AppConstants.tmdbApiKey,
            'language': 'pt-BR',
          },
        ));

  Future<List<Movie>> getTrendingMovies() async {
    try {
      final response = await _dio.get('/trending/movie/day');
      final results = response.data['results'] as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load trending movies: $e');
    }
  }

  Future<List<Series>> getTrendingSeries() async {
    try {
      final response = await _dio.get('/trending/tv/day');
      final results = response.data['results'] as List;
      return results.map((e) => Series.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load trending series: $e');
    }
  }

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _dio.get('/movie/popular', queryParameters: {'page': page});
      final results = response.data['results'] as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load popular movies: $e');
    }
  }

  Future<List<Series>> getPopularSeries({int page = 1}) async {
    try {
      final response = await _dio.get('/tv/popular', queryParameters: {'page': page});
      final results = response.data['results'] as List;
      return results.map((e) => Series.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load popular series: $e');
    }
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    try {
      final response = await _dio.get('/movie/top_rated', queryParameters: {'page': page});
      final results = response.data['results'] as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load top rated movies: $e');
    }
  }

  Future<List<Series>> getTopRatedSeries({int page = 1}) async {
    try {
      final response = await _dio.get('/tv/top_rated', queryParameters: {'page': page});
      final results = response.data['results'] as List;
      return results.map((e) => Series.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load top rated series: $e');
    }
  }

  Future<List<Movie>> getNowPlayingMovies({int page = 1}) async {
    try {
      final response = await _dio.get('/movie/now_playing', queryParameters: {'page': page});
      final results = response.data['results'] as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load now playing movies: $e');
    }
  }

  Future<Movie> getMovieDetail(int id) async {
    try {
      final response = await _dio.get('/movie/$id');
      return Movie.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load movie detail: $e');
    }
  }

  Future<Series> getSeriesDetail(int id) async {
    try {
      final response = await _dio.get('/tv/$id');
      return Series.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load series detail: $e');
    }
  }

  Future<List<Genre>> getMovieGenres() async {
    try {
      final response = await _dio.get('/genre/movie/list');
      final results = response.data['genres'] as List;
      return results.map((e) => Genre.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load movie genres: $e');
    }
  }

  Future<List<Genre>> getTvGenres() async {
    try {
      final response = await _dio.get('/genre/tv/list');
      final results = response.data['genres'] as List;
      return results.map((e) => Genre.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load tv genres: $e');
    }
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _dio.get('/discover/movie', queryParameters: {
        'with_genres': genreId,
        'page': page,
      });
      final results = response.data['results'] as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load movies by genre: $e');
    }
  }

  Future<List<Series>> getSeriesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _dio.get('/discover/tv', queryParameters: {
        'with_genres': genreId,
        'page': page,
      });
      final results = response.data['results'] as List;
      return results.map((e) => Series.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load series by genre: $e');
    }
  }

  Future<List<dynamic>> searchContent(String query, {int page = 1}) async {
    try {
      final response = await _dio.get('/search/multi', queryParameters: {
        'query': query,
        'page': page,
      });
      final results = response.data['results'] as List;
      return results.where((e) => e['media_type'] == 'movie' || e['media_type'] == 'tv').map((e) {
        if (e['media_type'] == 'movie') {
          return Movie.fromJson(e);
        } else {
          return Series.fromJson(e);
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to search content: $e');
    }
  }

  Future<List<Video>> getVideos(String mediaType, int id) async {
    try {
      final response = await _dio.get('/$mediaType/$id/videos');
      final results = response.data['results'] as List;
      return results.map((e) => Video.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load videos: $e');
    }
  }

  Future<List<CastMember>> getCredits(String mediaType, int id) async {
    try {
      final response = await _dio.get('/$mediaType/$id/credits');
      final results = response.data['cast'] as List;
      return results.map((e) => CastMember.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load credits: $e');
    }
  }

  Future<List<dynamic>> getSimilar(String mediaType, int id) async {
    try {
      final response = await _dio.get('/$mediaType/$id/similar');
      final results = response.data['results'] as List;
      if (mediaType == 'movie') {
        return results.map((e) => Movie.fromJson(e)).toList();
      } else {
        return results.map((e) => Series.fromJson(e)).toList();
      }
    } catch (e) {
      throw Exception('Failed to load similar content: $e');
    }
  }
}
