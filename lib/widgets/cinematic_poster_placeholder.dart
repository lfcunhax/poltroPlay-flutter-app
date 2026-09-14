import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Um placeholder cinematográfico moderno com gradientes neon PoltroPlay,
/// exibido quando a capa ainda não carregou, está indisponível ou offline.
/// Substitui o antigo quadrado cinza com exclamação.
class CinematicPosterPlaceholder extends StatelessWidget {
  final String? title;
  final IconData icon;
  final bool isCompact;

  const CinematicPosterPlaceholder({
    super.key,
    this.title,
    this.icon = Icons.movie_filter_rounded,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1738), // Roxo escuro profundo
            Color(0xFF121024), // Quase preto azulado
            Color(0xFF0D0B18),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efeito de brilho de fundo ambiente
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: isCompact ? 50 : 100,
              height: isCompact ? 50 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: isCompact ? 50 : 100,
              height: isCompact ? 50 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
              ),
            ),
          ),
          // Conteúdo central
          Padding(
            padding: EdgeInsets.all(isCompact ? 6.0 : 14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
                    border: Border.all(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2FF7).withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF00D4FF),
                    size: isCompact ? 18 : 32,
                  ),
                ),
                if (!isCompact && title != null && title!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
