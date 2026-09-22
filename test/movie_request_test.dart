import 'package:flutter_test/flutter_test.dart';
import 'package:poltro_play/models/movie_request.dart';

void main() {
  group('MovieRequest Model Tests', () {
    test('MovieRequest parses and serializes correctly', () {
      final now = DateTime.now();
      final request = MovieRequest(
        id: 'req_123',
        title: 'Interestelar 2',
        type: 'movie',
        year: '2026',
        notes: 'Gostaria muito de ver esse filme dublado!',
        userId: 'user_456',
        userName: 'Luiz',
        userEmail: 'luiz@example.com',
        status: 'pending',
        createdAt: now,
      );

      expect(request.id, equals('req_123'));
      expect(request.title, equals('Interestelar 2'));
      expect(request.isMovie, isTrue);
      expect(request.isSeries, isFalse);
      expect(request.typeLabel, equals('Filme'));
      expect(request.statusLabel, equals('Pendente'));

      final json = request.toJson();
      expect(json['title'], equals('Interestelar 2'));
      expect(json['type'], equals('movie'));
      expect(json['year'], equals('2026'));
      expect(json['userId'], equals('user_456'));
      expect(json['userName'], equals('Luiz'));
      expect(json['userEmail'], equals('luiz@example.com'));
      expect(json['status'], equals('pending'));

      final reconstructed = MovieRequest.fromJson({
        'title': 'Stranger Things 5',
        'type': 'series',
        'status': 'in_review',
        'notes': 'Temporada final',
      }, docId: 'req_789');

      expect(reconstructed.id, equals('req_789'));
      expect(reconstructed.title, equals('Stranger Things 5'));
      expect(reconstructed.isMovie, isFalse);
      expect(reconstructed.isSeries, isTrue);
      expect(reconstructed.typeLabel, equals('Série'));
      expect(reconstructed.statusLabel, equals('Em Análise'));
    });

    test('Status labels return expected Portuguese text', () {
      const p = MovieRequest(id: '1', title: 'T', status: 'pending');
      const r = MovieRequest(id: '2', title: 'T', status: 'in_review');
      const a = MovieRequest(id: '3', title: 'T', status: 'added');
      const d = MovieRequest(id: '4', title: 'T', status: 'rejected');

      expect(p.statusLabel, equals('Pendente'));
      expect(r.statusLabel, equals('Em Análise'));
      expect(a.statusLabel, equals('Adicionado'));
      expect(d.statusLabel, equals('Recusado'));
    });
  });
}
