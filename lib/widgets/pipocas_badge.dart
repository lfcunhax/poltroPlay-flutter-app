import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/rewards_provider.dart';
import 'package:poltro_play/widgets/rewards_modal.dart';

class PipocasBadge extends ConsumerWidget {
  const PipocasBadge({super.key});

  String _formatRemaining(Duration duration) {
    final h = duration.inHours;
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsState = ref.watch(rewardsProvider);
    final isVip = rewardsState.isAdFreeActive;

    return GestureDetector(
      onTap: () => showRewardsModal(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isVip
              ? const LinearGradient(
                  colors: [Color(0xFFFF9900), Color(0xFFFF5E3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    const Color(0xFF7B2FF7).withValues(alpha: 0.25),
                    const Color(0xFF00D4FF).withValues(alpha: 0.25),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVip ? const Color(0xFFFFD700) : const Color(0xFF7B2FF7).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: isVip
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF9900).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVip ? '👑' : '🍿',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              isVip 
                  ? 'VIP (${_formatRemaining(rewardsState.remainingAdFreeTime)})' 
                  : '${rewardsState.balance}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
