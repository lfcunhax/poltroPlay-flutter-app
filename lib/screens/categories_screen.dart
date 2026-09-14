import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static IconData getIconForGenre(String name) {
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

  static List<Color> getGradientForGenre(String name) {
    final n = name.toLowerCase();
    if (n.contains('ação') || n.contains('terror')) {
      return [const Color(0xFFE94560).withValues(alpha: 0.85), const Color(0xFF7B2FF7).withValues(alpha: 0.75)];
    }
    if (n.contains('romance') || n.contains('drama')) {
      return [const Color(0xFFFF5286).withValues(alpha: 0.85), const Color(0xFF7B2FF7).withValues(alpha: 0.75)];
    }
    if (n.contains('ficção') || n.contains('sci-fi') || n.contains('fantasia')) {
      return [const Color(0xFF7B2FF7).withValues(alpha: 0.85), const Color(0xFF00D4FF).withValues(alpha: 0.8)];
    }
    if (n.contains('comédia') || n.contains('kids') || n.contains('animação')) {
      return [const Color(0xFFFF9F1C).withValues(alpha: 0.85), const Color(0xFFE94560).withValues(alpha: 0.75)];
    }
    if (n.contains('aventura') || n.contains('faroeste')) {
      return [const Color(0xFF2EC4B6).withValues(alpha: 0.85), const Color(0xFF00D4FF).withValues(alpha: 0.8)];
    }
    return [const Color(0xFF7B2FF7).withValues(alpha: 0.8), const Color(0xFF00D4FF).withValues(alpha: 0.75)];
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
              return _AnimatedCategoryCard(
                index: index,
                genreName: genreName,
                onTap: () {
                  context.push('/categories/${Uri.encodeComponent(genreName)}', extra: genreName);
                },
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

/// Card de Categoria com Microanimações táteis e feedback visual dinâmico
class _AnimatedCategoryCard extends StatefulWidget {
  final int index;
  final String genreName;
  final VoidCallback onTap;

  const _AnimatedCategoryCard({
    required this.index,
    required this.genreName,
    required this.onTap,
  });

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = CategoriesScreen.getGradientForGenre(widget.genreName);
    final icon = CategoriesScreen.getIconForGenre(widget.genreName);

    // Efeito de entrada suave escalonada
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (widget.index % 9) * 35),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isPressed
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.16),
                width: _isPressed ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: _isPressed ? 0.45 : 0.22),
                  blurRadius: _isPressed ? 18 : 10,
                  offset: Offset(0, _isPressed ? 2 : 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Brilho no topo do card
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Conteúdo central do Card
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: _isPressed ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.3),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text(
                          widget.genreName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            letterSpacing: 0.2,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
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
}
