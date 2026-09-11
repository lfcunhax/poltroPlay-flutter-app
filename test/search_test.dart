import 'package:flutter_test/flutter_test.dart';
import 'package:poltro_play/core/utils/string_utils.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/movie.dart';

void main() {
  group('String Normalization & Search Utils', () {
    test('normalizeSearchText should remove accents and diacritics', () {
      expect(normalizeSearchText('História'), equals('historia'));
      expect(normalizeSearchText('Alma Gêmea'), equals('alma gemea'));
      expect(normalizeSearchText('Geração'), equals('geracao'));
      expect(normalizeSearchText('Família Não Se Escolhe'), equals('familia nao se escolhe'));
      expect(normalizeSearchText('Café & Chá'), equals('cafe cha'));
    });

    test('normalizeSearchText should handle punctuation and hyphens', () {
      expect(normalizeSearchText('Homem-Aranha: De Volta ao Lar'), equals('homem aranha de volta ao lar'));
      expect(normalizeSearchText('Deadpool & Wolverine'), equals('deadpool wolverine'));
      expect(normalizeSearchText('Vingadores: Ultimato'), equals('vingadores ultimato'));
    });

    test('generateSearchPrefixes should generate capitalized, title-cased and uppercase variants', () {
      final prefixes = generateSearchPrefixes('deadpool');
      expect(prefixes, contains('deadpool'));
      expect(prefixes, contains('Deadpool'));
      expect(prefixes, contains('DEADPOOL'));

      final compoundPrefixes = generateSearchPrefixes('homem aranha');
      expect(compoundPrefixes, contains('Homem Aranha'));
      expect(compoundPrefixes, contains('Homem-Aranha'));
    });
  });

  group('Series.fromApi Robust Parsing', () {
    test('Series.fromApi parses string tags safely without throwing TypeError', () {
      final json = {
        'id': 418,
        'tmdb_id': 16120,
        'title': 'Alma Gêmea',
        'overview': 'Sinopse de teste',
        'poster_path': '/teste.jpg',
        'backdrop_path': '/backdrop.jpg',
        'vote_average': '6.9',
        'release_date': '2005-06-20',
        'tags': 'Soap Drama Comédia Mistério',
      };

      final series = Series.fromApi(json);
      expect(series.id, equals('418'));
      expect(series.name, equals('Alma Gêmea'));
      expect(series.voteAverage, equals(6.9));
      expect(series.tags, isNotEmpty);
    });

    test('Series.fromApi parses list tags and null tags safely', () {
      final jsonListTags = {
        'id': 419,
        'title': 'Série Lista',
        'tags': ['Drama', 'Crime'],
      };
      final seriesList = Series.fromApi(jsonListTags);
      expect(seriesList.tags, equals(['Drama', 'Crime']));

      final jsonNullTags = {
        'id': 420,
        'title': 'Série Sem Tags',
        'tags': null,
      };
      final seriesNull = Series.fromApi(jsonNullTags);
      expect(seriesNull.tags, isEmpty);
    });
  });

  group('Movie Model Serialization', () {
    test('Movie serialization and deserialization roundtrip works properly', () {
      const movie = Movie(
        id: 'test_123',
        tmdbId: 9999,
        title: 'Filme de Teste',
        overview: 'Descrição detalhada',
        posterPath: '/poster.jpg',
        backdropPath: '/backdrop.jpg',
        voteAverage: 8.5,
        releaseDate: '2024-01-01',
        videoUrl: 'http://video.mp4',
        tags: ['Ação', 'Aventura'],
      );

      final json = movie.toJson();
      final fromJson = Movie.fromJson(json);

      expect(fromJson.id, equals(movie.id));
      expect(fromJson.title, equals(movie.title));
      expect(fromJson.voteAverage, equals(movie.voteAverage));
      expect(fromJson.tags, equals(movie.tags));
    });

    test('Movie.fromApi parses PostgreSQL snake_case columns properly', () {
      final pgJson = {
        'id': 105,
        'tmdb_id': 1076601,
        'title': 'Luccas Neto em: Acampamento de Férias 4',
        'overview': 'Sinopse oficial',
        'poster_path': '/poster_pg.jpg',
        'backdrop_path': '/backdrop_pg.jpg',
        'vote_average': '7.5',
        'release_date': '2024-06-15',
        'video_url': 'http://fhd4.oneplayer.site/movie.mp4',
        'tags': ['Comédia', 'Família'],
      };

      final movie = Movie.fromApi(pgJson);
      expect(movie.id, equals('105'));
      expect(movie.tmdbId, equals(1076601));
      expect(movie.title, equals('Luccas Neto em: Acampamento de Férias 4'));
      expect(movie.videoUrl, equals('http://fhd4.oneplayer.site/movie.mp4'));
      expect(movie.voteAverage, equals(7.5));
      expect(movie.posterPath, equals('/poster_pg.jpg'));
    });
  });
}
