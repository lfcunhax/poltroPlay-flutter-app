import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:poltro_play/models/watch_progress.dart';
import 'package:poltro_play/widgets/cinematic_poster_placeholder.dart';

class ContinueWatchingCard extends StatelessWidget {
  final WatchProgress watchProgress;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const ContinueWatchingCard({
    super.key,
    required this.watchProgress,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(watchProgress.contentId.toString()),
      direction: DismissDirection.up,
      onDismissed: (_) => onRemove(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE94560),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 280,
          height: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                            ),
                            child: watchProgress.fullPosterUrl.trim().isEmpty
                                ? const SizedBox(
                                    width: 60,
                                    height: 80,
                                    child: CinematicPosterPlaceholder(
                                      isCompact: true,
                                      icon: Icons.play_arrow_rounded,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: watchProgress.fullPosterUrl,
                                    width: 60,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFF161326),
                                    ),
                                    errorWidget: (context, url, error) => const SizedBox(
                                      width: 60,
                                      height: 80,
                                      child: CinematicPosterPlaceholder(
                                        isCompact: true,
                                        icon: Icons.play_arrow_rounded,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  watchProgress.title,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  watchProgress.formattedRemaining,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                            onPressed: onRemove,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    LinearProgressIndicator(
                      value: watchProgress.progressPercent,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      color: const Color(0xFF00D4FF),
                      minHeight: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
