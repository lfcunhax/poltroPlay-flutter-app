import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/core/services/ad_service.dart';
import 'package:poltro_play/core/services/rewards_service.dart';
import 'package:poltro_play/providers/rewards_provider.dart';
import 'package:poltro_play/widgets/daily_checkin_modal.dart';

void showRewardsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const RewardsModalSheet(),
  );
}

class RewardsModalSheet extends ConsumerStatefulWidget {
  const RewardsModalSheet({super.key});

  @override
  ConsumerState<RewardsModalSheet> createState() => _RewardsModalSheetState();
}

class _RewardsModalSheetState extends ConsumerState<RewardsModalSheet> {
  bool _isLoadingAd = false;

  void _watchRewardedAd() {
    setState(() => _isLoadingAd = true);
    
    AdService().showRewardedAd(
      onUserEarnedReward: (amount) {
        ref.read(rewardsProvider.notifier).addPipocasFromAd(amount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00D4FF),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  const Text('🍿', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Parabéns! Você ganhou +$amount Pipocas!',
                      style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      onAdClosed: () {
        if (mounted) setState(() => _isLoadingAd = false);
      },
      onAdFailed: (error) {
        if (mounted) {
          setState(() => _isLoadingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFE94560),
              behavior: SnackBarBehavior.floating,
              content: Text(
                error,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          );
        }
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final rewardsState = ref.watch(rewardsProvider);
    final notifier = ref.read(rewardsProvider.notifier);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13131F).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('🍿', style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Central de Pipocas',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Junte moedas e assista sem anúncios!',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2FF7).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SEU SALDO ATUAL',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🍿', style: TextStyle(fontSize: 36)),
                          const SizedBox(width: 8),
                          Text(
                            '${rewardsState.balance}',
                            style: GoogleFonts.outfit(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pipocas',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (rewardsState.isAdFreeActive) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.amberAccent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Colors.amberAccent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'VIP ATIVO: ${_formatDuration(rewardsState.remainingAdFreeTime)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: Ganhar Pipocas
                Text(
                  'GANHAR MAIS PIPOCAS',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFF00D4FF),
                  ),
                ),
                const SizedBox(height: 12),

                // Card: Assistir Anúncio
                _buildActionCard(
                  icon: Icons.play_circle_fill,
                  iconColor: const Color(0xFF00D4FF),
                  title: 'Assistir Anúncio (+10 🍿)',
                  subtitle: rewardsState.remainingRewardedAdsToday <= 0
                      ? 'Limite diário de ${RewardsState.maxDailyRewardedAds} vídeos atingido. Volte amanhã!'
                      : rewardsState.rewardedAdCooldownRemaining > Duration.zero
                          ? 'Aguarde ${rewardsState.rewardedAdCooldownRemaining.inSeconds}s para o próximo vídeo.'
                          : 'Vídeo rápido de recompensa (${rewardsState.remainingRewardedAdsToday}/${RewardsState.maxDailyRewardedAds} hoje)',
                  buttonText: _isLoadingAd
                      ? 'Carregando...'
                      : rewardsState.remainingRewardedAdsToday <= 0
                          ? 'Limite (0/8)'
                          : rewardsState.rewardedAdCooldownRemaining > Duration.zero
                              ? '${rewardsState.rewardedAdCooldownRemaining.inSeconds}s ⏳'
                              : '+10 Pipocas 🍿',
                  buttonColor: (rewardsState.canWatchRewardedAd && !_isLoadingAd)
                      ? const Color(0xFF00D4FF)
                      : Colors.white12,
                  textColor: (rewardsState.canWatchRewardedAd && !_isLoadingAd)
                      ? Colors.black
                      : Colors.white38,
                  isLoading: _isLoadingAd,
                  onPressed: (_isLoadingAd || !rewardsState.canWatchRewardedAd) ? null : _watchRewardedAd,
                ),
                const SizedBox(height: 10),

                // Card: Bônus Diário
                _buildActionCard(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFFFFB300),
                  title: 'Bônus Diário (Dia ${rewardsState.currentEligibleStreakDay} de 7)',
                  subtitle: rewardsState.canClaimDailyBonus 
                      ? 'Sequência de 7 dias: até +${rewardsState.todayRewardAmount} Pipocas hoje!' 
                      : 'Bônus de hoje já coletado! Volte amanhã para continuar a sequência.',
                  buttonText: rewardsState.canClaimDailyBonus ? 'Coletar 📅' : 'Ver 📅',
                  buttonColor: rewardsState.canClaimDailyBonus ? const Color(0xFFFFB300) : Colors.white12,
                  textColor: rewardsState.canClaimDailyBonus ? Colors.black : Colors.white70,
                  onPressed: () {
                    Navigator.pop(context);
                    showDailyCheckInModal(context);
                  },
                ),
                const SizedBox(height: 24),

                // Section 2: Usar Pipocas
                Text(
                  'TROCAR POR TEMPO SEM ANÚNCIOS',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFF9D5CFF),
                  ),
                ),
                const SizedBox(height: 12),

                // Passe 1 Hora
                _buildAdFreePassCard(
                  title: 'Sessão Cineasta (1 Hora)',
                  subtitle: 'Assista a 1 filme ou episódios sem anúncios',
                  cost: 15,
                  hours: 1,
                  currentBalance: rewardsState.balance,
                  onActivate: () {
                    final success = notifier.activateAdFreePass(1, 15);
                    if (success) {
                      _showSuccessDialog('Sessão Cineasta Ativada!', 'Você tem 1 hora livre de qualquer anúncio!');
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Passe 3 Horas
                _buildAdFreePassCard(
                  title: 'Maratona VIP (3 Horas)',
                  subtitle: 'Ideal para maratonar séries completas sem parar',
                  cost: 25,
                  hours: 3,
                  badge: 'MAIS POPULAR',
                  currentBalance: rewardsState.balance,
                  onActivate: () {
                    final success = notifier.activateAdFreePass(3, 25);
                    if (success) {
                      _showSuccessDialog('Maratona VIP Ativada!', 'Você tem 3 horas livres de qualquer anúncio!');
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white38, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Se suas pipocas acabarem, você continua assistindo normalmente com anúncios comuns. O PoltroPlay é 100% gratuito!',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Color(0xFF00D4FF), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2FF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Aproveitar!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required Color textColor,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Text(
                    buttonText,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdFreePassCard({
    required String title,
    required String subtitle,
    required int cost,
    required int hours,
    required int currentBalance,
    String? badge,
    required VoidCallback onActivate,
  }) {
    final canAfford = currentBalance >= cost;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge != null 
              ? const Color(0xFF7B2FF7).withValues(alpha: 0.5) 
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFF9D5CFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canAfford ? onActivate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? const Color(0xFF7B2FF7) : Colors.white12,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$cost 🍿',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
