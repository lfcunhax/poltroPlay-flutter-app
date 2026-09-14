import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  IconData _getIconForGenre(String name) {
    final n = name.toLowerCase();
    if (n.contains('ação') || n.contains('action')) return Icons.bolt_rounded;
    if (n.contains('aventura') || n.contains('adventure')) return Icons.explore_rounded;
    if (n.contains('comédia') || n.contains('comedy')) return Icons.sentiment_very_satisfied_rounded;
    if (n.contains('drama')) return Icons.theater_comedy_rounded;
    if (n.contains('terror') || n.contains('horror')) return Icons.nightlight_round;
    if (n.contains('romance')) return Icons.favorite_rounded;
    if (n.contains('ficção') || n.contains('sci-fi')) return Icons.rocket_launch_rounded;
    if (n.contains('documentário')) return Icons.videocam_rounded;
    if (n.contains('animação') || n.contains('animation')) return Icons.animation_rounded;
    if (n.contains('crime') || n.contains('policial')) return Icons.local_police_rounded;
    if (n.contains('mistério') || n.contains('mystery')) return Icons.search_rounded;
    if (n.contains('família') || n.contains('family')) return Icons.family_restroom_rounded;
    if (n.contains('fantasia') || n.contains('fantasy')) return Icons.auto_awesome_rounded;
    if (n.contains('guerra') || n.contains('war')) return Icons.military_tech_rounded;
    if (n.contains('kids') || n.contains('infantil')) return Icons.child_care_rounded;
    if (n.contains('suspense') || n.contains('thriller')) return Icons.psychology_rounded;
    if (n.contains('música') || n.contains('music')) return Icons.music_note_rounded;
    if (n.contains('faroeste') || n.contains('western')) return Icons.wb_sunny_rounded;
    return Icons.movie_filter_rounded;
  }

  List<Color> _getGradientForGenre(String name) {
    final n = name.toLowerCase();
    if (n.contains('ação') || n.contains('terror')) {
      return [const Color(0xFFE94560).withValues(alpha: 0.8), const Color(0xFF7B2FF7).withValues(alpha: 0.7)];
    }
    if (n.contains('romance') || n.contains('drama')) {
      return [const Color(0xFFFF5286).withValues(alpha: 0.75), const Color(0xFF7B2FF7).withValues(alpha: 0.7)];
    }
    if (n.contains('ficção') || n.contains('sci-fi') || n.contains('fantasia')) {
      return [const Color(0xFF7B2FF7).withValues(alpha: 0.8), const Color(0xFF00D4FF).withValues(alpha: 0.75)];
    }
    if (n.contains('comédia') || n.contains('kids') || n.contains('animação')) {
      return [const Color(0xFFFF9F1C).withValues(alpha: 0.75), const Color(0xFFE94560).withValues(alpha: 0.7)];
    }
    if (n.contains('aventura') || n.contains('faroeste')) {
      return [const Color(0xFF2EC4B6).withValues(alpha: 0.75), const Color(0xFF00D4FF).withValues(alpha: 0.7)];
    }
    return [const Color(0xFF7B2FF7).withValues(alpha: 0.7), const Color(0xFF00D4FF).withValues(alpha: 0.7)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Categorias & Gêneros',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('Nenhuma categoria encontrada', style: TextStyle(color: Colors.white70)),
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.95,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final genreName = categories[index];
              final gradient = _getGradientForGenre(genreName);

              return GestureDetector(
                onTap: () {
                  context.push('/categories/${Uri.encodeComponent(genreName)}', extra: genreName);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                        child: Icon(_getIconForGenre(genreName), color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text(
                          genreName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => _buildShimmerGrid(),
        error: (err, stack) => Center(
          child: Text('Erro ao carregar categorias: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.95,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF1A1A2E),
          highlightColor: const Color(0xFF2A2A4E),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
