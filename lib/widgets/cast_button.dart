import 'package:flutter/material.dart';
import 'package:poltro_play/core/services/cast_service.dart';

/// Botão de Transmitir para TV - Widget reutilizável.
/// Mostra o ícone de cast e abre o seletor de dispositivos.
/// Quando conectado, fica azul com animação de pulso.
class CastButton extends StatefulWidget {
  final String? videoUrl;
  final String? title;
  final String? posterUrl;
  final double size;
  final Color color;
  final Color connectedColor;

  const CastButton({
    super.key,
    this.videoUrl,
    this.title,
    this.posterUrl,
    this.size = 24.0,
    this.color = Colors.white,
    this.connectedColor = const Color(0xFF00D4FF),
  });

  @override
  State<CastButton> createState() => _CastButtonState();
}

class _CastButtonState extends State<CastButton> with SingleTickerProviderStateMixin {
  final _castService = CastService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _castService.isConnected.addListener(_onConnectionChanged);
  }

  void _onConnectionChanged() {
    if (_castService.isConnected.value) {
      _pulseController.repeat(reverse: true);
      // Se estiver conectado e tiver URL, enviar a mídia automaticamente
      if (widget.videoUrl != null) {
        _castService.loadMedia(
          url: widget.videoUrl!,
          title: widget.title ?? 'PoltroPlay',
          posterUrl: widget.posterUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transmitindo "${widget.title}" para ${_castService.deviceName.value}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF1A1A2E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _castService.isConnected.removeListener(_onConnectionChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (_castService.isConnected.value) {
      // Se já está conectado, mostra opções
      _showConnectedMenu();
    } else {
      // Se não está conectado, abre o seletor de TVs
      final result = await _castService.showCastDialog();
      if (mounted && result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Erro ao buscar dispositivos Cast',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE94560),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showConnectedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.cast_connected, size: 48, color: widget.connectedColor),
            const SizedBox(height: 12),
            Text(
              'Conectado a ${_castService.deviceName.value ?? "TV"}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.videoUrl != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('Transmitir Este Vídeo',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2FF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _castService.loadMedia(
                      url: widget.videoUrl!,
                      title: widget.title ?? 'PoltroPlay',
                      posterUrl: widget.posterUrl,
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cast_connected, color: Color(0xFFE94560)),
                label: const Text('Desconectar',
                    style: TextStyle(color: Color(0xFFE94560))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE94560)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _castService.disconnect();
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = _castService.isConnected.value;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return IconButton(
          icon: Icon(
            connected ? Icons.cast_connected : Icons.cast,
            color: connected
                ? Color.lerp(widget.connectedColor, Colors.white, _pulseController.value)
                : widget.color,
            size: widget.size,
          ),
          onPressed: _onTap,
          tooltip: connected ? 'Conectado - Toque para opções' : 'Transmitir para TV',
        );
      },
    );
  }
}
