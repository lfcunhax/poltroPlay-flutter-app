import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/core/services/rewards_service.dart';
import 'package:poltro_play/providers/rewards_provider.dart';

void showDailyCheckInModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const DailyCheckInModalSheet(),
  );
}

class DailyCheckInModalSheet extends ConsumerWidget {
  const DailyCheckInModalSheet({super.key});

  String _timeUntilTomorrow() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsState = ref.watch(rewardsProvider);
    final notifier = ref.read(rewardsProvider.notifier);

    final canClaim = rewardsState.canClaimDailyBonus;
    final eligibleDay = rewardsState.currentEligibleStreakDay;
    final todayReward = rewardsState.todayRewardAmount;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF12121E).withValues(alpha: 0.96),
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
              children: [
                // Handle bar
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('📅', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendário Semanal',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Entre todo dia para acumular mais Pipocas!',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
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

                // Streak Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Sequência: Dia $eligibleDay de 7',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          canClaim ? 'Disponível Hoje!' : 'Coletado ✓',
                          style: GoogleFonts.inter(
                            color: canClaim ? const Color(0xFF00D4FF) : Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Calendar Grid: Days 1 to 4
                Row(
                  children: [
                    for (int day = 1; day <= 4; day++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: day < 4 ? 8.0 : 0,
                          ),
                          child: _buildDayCard(
                            day: day,
                            reward: RewardsState.getRewardForDay(day),
                            eligibleDay: eligibleDay,
                            canClaim: canClaim,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Calendar Grid: Days 5 to 7
                Row(
                  children: [
                    for (int day = 5; day <= 7; day++)
                      Expanded(
                        flex: day == 7 ? 2 : 1, // Dia 7 tem destaque maior!
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: day < 7 ? 8.0 : 0,
                          ),
                          child: _buildDayCard(
                            day: day,
                            reward: RewardsState.getRewardForDay(day),
                            eligibleDay: eligibleDay,
                            canClaim: canClaim,
                            isSpecial: day == 7,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Big Claim Button
                if (canClaim)
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2FF7).withValues(alpha: 0.4),
                          blurRadius: 16,
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
                        final amount = notifier.claimDailyBonus();
                        if (amount > 0) {
                          Navigator.pop(context);
                          _showCelebrationDialog(context, amount, eligibleDay);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🍿', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            'Coletar +$todayReward Pipocas de Hoje!',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Você já coletou o bônus de hoje!',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Próxima recompensa disponível em: ${_timeUntilTomorrow()}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00D4FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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

  static void _showCelebrationDialog(BuildContext context, int amount, int day) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Dia $day Coletado!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Você ganhou +$amount Pipocas!',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF00D4FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Volte amanhã para manter sua sequência e ganhar ainda mais!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FF7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Continuar',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int day,
    required int reward,
    required int eligibleDay,
    required bool canClaim,
    bool isSpecial = false,
  }) {
    final isDone = day < eligibleDay || (day == eligibleDay && !canClaim);
    final isCurrent = day == eligibleDay && canClaim;

    Color borderColor = Colors.white.withValues(alpha: 0.08);
    Color bgColor = const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    if (isCurrent) {
      borderColor = const Color(0xFF00D4FF);
      bgColor = const Color(0xFF7B2FF7).withValues(alpha: 0.35);
    } else if (isDone) {
      borderColor = Colors.green.withValues(alpha: 0.3);
      bgColor = const Color(0xFF0E1A1A);
    } else if (isSpecial) {
      borderColor = const Color(0xFFFFB300).withValues(alpha: 0.4);
      bgColor = const Color(0xFF2E2412).withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isCurrent ? 1.8 : 1.0),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSpecial ? 'Dia 7 🏆' : 'Dia $day',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCurrent
                  ? const Color(0xFF00D4FF)
                  : (isSpecial ? const Color(0xFFFFB300) : Colors.white70),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDone ? '✓' : (isSpecial ? '🏆' : '🍿'),
            style: TextStyle(
              fontSize: isDone ? 20 : 18,
              color: isDone ? Colors.greenAccent : null,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '+$reward',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDone ? Colors.white38 : Colors.white,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'HOJE',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
