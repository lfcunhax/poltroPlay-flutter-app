import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/rewards_provider.dart';
import 'package:poltro_play/widgets/daily_checkin_modal.dart';

void showRewardsOnboardingModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const RewardsOnboardingDialog(),
  );
}

class RewardsOnboardingDialog extends ConsumerWidget {
  const RewardsOnboardingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131322),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🍿', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Conheça as Pipocas!',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sua moeda oficial para assistir sem anúncios no PoltroPlay.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
              ),
              const SizedBox(height: 24),

              // 3 Steps
              _buildStepItem(
                icon: Icons.movie_outlined,
                iconColor: const Color(0xFF00D4FF),
                title: 'Filmes & Séries Gratuitos',
                description: 'Assista a qualquer conteúdo do catálogo gratuitamente.',
              ),
              const SizedBox(height: 14),
              _buildStepItem(
                icon: Icons.auto_awesome,
                iconColor: const Color(0xFFFFB300),
                title: 'Junte Pipocas Facilmente',
                description: 'Faça check-in diário e assista a anúncios rápidos quando quiser.',
              ),
              const SizedBox(height: 14),
              _buildStepItem(
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF7B2FF7),
                title: 'Maratone em Modo VIP',
                description: 'Troque suas Pipocas para zerar anúncios e assistir direto sem pausas!',
              ),
              const SizedBox(height: 26),

              // Action Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ref.read(rewardsProvider.notifier).markTutorialAsSeen();
                    Navigator.pop(context);

                    // Abre o check-in do primeiro dia automaticamente!
                    showDailyCheckInModal(context);
                  },
                  child: Text(
                    'Começar e Coletar Bônus! 🍿',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
