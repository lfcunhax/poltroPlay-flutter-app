import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:poltro_play/models/movie_request.dart';

final movieRequestServiceProvider = Provider<MovieRequestService>((ref) {
  return MovieRequestService();
});

class RequestSubmissionResult {
  final bool isSuccess;
  final String? errorMessage;

  const RequestSubmissionResult({required this.isSuccess, this.errorMessage});

  factory RequestSubmissionResult.success() => const RequestSubmissionResult(isSuccess: true);
  factory RequestSubmissionResult.failure(String message) => RequestSubmissionResult(isSuccess: false, errorMessage: message);
}

class MovieRequestService {
  final FirebaseFirestore _firestore;

  MovieRequestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Registra o pedido no Firestore e dispara alerta via Resend se configurado no painel admin
  Future<RequestSubmissionResult> submitRequest({
    required String title,
    required String type, // 'movie' ou 'series'
    String? year,
    String? notes,
    String? userId,
    String? userName,
    String? userEmail,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return RequestSubmissionResult.failure('Por favor, informe o título do filme ou série.');
    }

    try {
      // 1. Grava no Firestore na coleção 'movie_requests'
      final docRef = await _firestore.collection('movie_requests').add({
        'title': cleanTitle,
        'type': type,
        'year': (year != null && year.trim().isNotEmpty) ? year.trim() : null,
        'notes': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
        'userId': userId,
        'userName': userName ?? 'Usuário do App',
        'userEmail': userEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Se usuário estiver logado, registra cópia em users/{uid}/movie_requests
      if (userId != null && userId.isNotEmpty) {
        _firestore
            .collection('users')
            .doc(userId)
            .collection('movie_requests')
            .doc(docRef.id)
            .set({
              'title': cleanTitle,
              'type': type,
              'year': year,
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            })
            .catchError((_) {});
      }

      // 2. Dispara e-mail de alerta ao administrador via Resend em background
      _sendAdminAlertEmail(
        requestId: docRef.id,
        title: cleanTitle,
        type: type,
        year: year,
        notes: notes,
        userName: userName,
        userEmail: userEmail,
      ).catchError((err) {
        // Falha no e-mail não cancela o sucesso da solicitação do usuário
        print('Erro ao enviar e-mail via Resend: $err');
      });

      return RequestSubmissionResult.success();
    } catch (e) {
      print('Erro ao salvar pedido de filme: $e');
      String msg = 'Erro ao enviar pedido.';
      final str = e.toString();
      if (str.contains('permission-denied')) {
        msg = 'Permissão negada no Firestore (permission-denied).';
      } else if (str.contains('network') || str.contains('unavailable')) {
        msg = 'Falha de rede. Verifique sua internet e tente novamente.';
      } else {
        msg = str.replaceAll('Exception:', '').trim();
      }
      return RequestSubmissionResult.failure(msg);
    }
  }

  /// Busca configurações do Resend no Firestore e envia o e-mail se ativo
  Future<void> _sendAdminAlertEmail({
    required String requestId,
    required String title,
    required String type,
    String? year,
    String? notes,
    String? userName,
    String? userEmail,
  }) async {
    try {
      final configDoc = await _firestore.collection('settings').doc('resend_config').get();
      if (!configDoc.exists) return;

      final config = configDoc.data() ?? {};
      final apiKey = config['apiKey']?.toString().trim() ?? '';
      final destinationEmail = config['notificationEmail']?.toString().trim() ?? '';
      final isEnabled = config['notifyOnNewRequest'] ?? true;
      final senderEmail = (config['senderEmail']?.toString().trim().isNotEmpty ?? false)
          ? config['senderEmail'].toString().trim()
          : 'PoltroPlay <onboarding@resend.dev>';

      if (apiKey.isEmpty || destinationEmail.isEmpty || !isEnabled) {
        return;
      }

      final typeLabel = type == 'series' ? 'Série' : 'Filme';
      final formattedDate = DateTime.now().toLocal().toString().split('.').first;

      final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0A0A0A; color: #FFFFFF; margin: 0; padding: 24px; }
    .card { background-color: #161326; border: 1px solid #2B264A; border-radius: 16px; max-width: 600px; margin: 0 auto; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
    .header { background: linear-gradient(135deg, #7B2FF7 0%, #00D4FF 100%); padding: 24px; text-align: center; }
    .header h1 { margin: 0; color: #FFFFFF; font-size: 24px; letter-spacing: -0.5px; }
    .header p { margin: 6px 0 0; color: rgba(255,255,255,0.85); font-size: 14px; }
    .content { padding: 24px; }
    .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; text-transform: uppercase; background: rgba(0, 212, 255, 0.15); color: #00D4FF; border: 1px solid #00D4FF; }
    .title-box { background: #1F1B38; border-radius: 12px; padding: 16px; margin: 16px 0; border-left: 4px solid #7B2FF7; }
    .title-box h2 { margin: 0 0 6px 0; font-size: 20px; color: #FFFFFF; }
    .title-box p { margin: 0; color: #A0A0B8; font-size: 14px; }
    .info-table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    .info-table td { padding: 10px 0; border-bottom: 1px solid #2B264A; font-size: 14px; }
    .info-table td.label { color: #8E8EA8; width: 35%; }
    .info-table td.value { color: #FFFFFF; font-weight: 500; }
    .notes-box { background: rgba(255,255,255,0.03); border-radius: 10px; padding: 14px; margin-top: 16px; color: #D1D1E0; font-size: 14px; line-height: 1.5; font-style: italic; }
    .footer { text-align: center; padding: 20px; font-size: 12px; color: #6E6E88; border-top: 1px solid #2B264A; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>PoltroPlay • Novo Pedido de Conteúdo</h1>
      <p>Um usuário solicitou a inclusão de um título no catálogo</p>
    </div>
    <div class="content">
      <span class="badge">$typeLabel</span>
      
      <div class="title-box">
        <h2>$title</h2>
        <p>${year != null && year.isNotEmpty ? 'Ano aproximado: $year' : 'Ano não especificado'}</p>
      </div>

      <table class="info-table">
        <tr>
          <td class="label">Tipo:</td>
          <td class="value">$typeLabel</td>
        </tr>
        <tr>
          <td class="label">Solicitante:</td>
          <td class="value">${userName ?? 'Usuário'}</td>
        </tr>
        <tr>
          <td class="label">E-mail:</td>
          <td class="value">${userEmail ?? 'Não informado'}</td>
        </tr>
        <tr>
          <td class="label">Data do Pedido:</td>
          <td class="value">$formattedDate</td>
        </tr>
        <tr>
          <td class="label">ID no Sistema:</td>
          <td class="value" style="font-family: monospace; font-size: 12px; color: #00D4FF;">$requestId</td>
        </tr>
      </table>

      ${(notes != null && notes.isNotEmpty) ? '''
      <div style="margin-top: 16px;">
        <strong style="font-size: 13px; color: #8E8EA8;">Observações do Usuário:</strong>
        <div class="notes-box">"$notes"</div>
      </div>
      ''' : ''}

      <div style="margin-top: 24px; text-align: center;">
        <p style="color: #A0A0B8; font-size: 13px;">Acesse o Painel Administrativo PoltroPlay para gerenciar e atualizar o status deste pedido.</p>
      </div>
    </div>
    <div class="footer">
      Este é um e-mail automático gerado pelo aplicativo PoltroPlay.<br>
      Configurado no Painel Administrativo com integração Resend.
    </div>
  </div>
</body>
</html>
''';

      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': senderEmail,
          'to': [destinationEmail],
          'subject': '🎬 Novo Pedido PoltroPlay: $title ($typeLabel)',
          'html': htmlBody,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Alerta de pedido enviado com sucesso via Resend para $destinationEmail');
      } else {
        print('Erro retornado pela API Resend (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Erro ao disparar e-mail Resend: $e');
    }
  }

  /// Retorna stream dos pedidos do usuário logado (opcional para exibir histórico)
  Stream<List<MovieRequest>> getUserRequests(String userId) {
    return _firestore
        .collection('movie_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => MovieRequest.fromFirestore(doc)).toList());
  }
}
