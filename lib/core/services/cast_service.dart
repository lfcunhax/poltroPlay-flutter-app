import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Serviço nativo de Google Cast via MethodChannel.
/// Não depende de nenhum pacote externo - comunica diretamente com o Android SDK.
class CastService {
  static const _channel = MethodChannel('com.poltroplay/cast');
  static final CastService _instance = CastService._internal();

  factory CastService() => _instance;
  CastService._internal() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<String?> deviceName = ValueNotifier(null);
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onSessionStarted':
        final name = call.arguments?['deviceName'] as String?;
        isConnected.value = true;
        deviceName.value = name ?? 'TV';
        lastError.value = null;
        break;
      case 'onSessionEnded':
        isConnected.value = false;
        deviceName.value = null;
        break;
      case 'onDeviceFound':
        final name = call.arguments?['name'] as String?;
        debugPrint('Cast: Dispositivo encontrado - $name');
        break;
      case 'onCastError':
        lastError.value = call.arguments as String?;
        break;
    }
  }

  /// Abre o seletor nativo de dispositivos Cast (TVs, Chromecasts, etc.)
  /// Retorna um Map com detalhes do resultado
  Future<Map<String, dynamic>> showCastDialog() async {
    try {
      final result = await _channel.invokeMethod('showCastDialog');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'success': true};
    } on PlatformException catch (e) {
      debugPrint('Cast dialog error: ${e.message}');
      return {'success': false, 'message': e.message};
    } on MissingPluginException {
      return {'success': false, 'message': 'Cast não disponível neste dispositivo'};
    }
  }

  /// Envia o vídeo para a TV conectada
  Future<void> loadMedia({
    required String url,
    required String title,
    String? posterUrl,
  }) async {
    try {
      await _channel.invokeMethod('loadMedia', {
        'url': url,
        'title': title,
        'posterUrl': posterUrl,
      });
    } on PlatformException catch (e) {
      debugPrint('Cast load error: ${e.message}');
    }
  }

  /// Verifica se há uma sessão Cast ativa
  Future<bool> checkConnection() async {
    try {
      final result = await _channel.invokeMethod<bool>('isConnected');
      isConnected.value = result ?? false;
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Desconecta da TV
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      debugPrint('Cast disconnect error: ${e.message}');
    }
  }

  Future<void> pause() async {
    try { await _channel.invokeMethod('pause'); } on PlatformException catch (_) {}
  }

  Future<void> play() async {
    try { await _channel.invokeMethod('play'); } on PlatformException catch (_) {}
  }

  Future<void> stop() async {
    try { await _channel.invokeMethod('stop'); } on PlatformException catch (_) {}
  }
}
