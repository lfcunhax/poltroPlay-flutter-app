import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/favorites_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161326),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Limpar Favoritos',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja remover todos os filmes e séries da sua lista de favoritos?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(favoritesProvider.notifier).clearAllFavorites();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: const Color(0xFF7B2FF7).withValues(alpha: 0.4)),
                    ),
                    content: const Text(
                      'Lista de favoritos limpa com sucesso',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    backgroundColor: const Color(0xFF221A3E),
                    duration: const Duration(milliseconds: 2200),
                  ),
                );
              }
            },
            child: Text(
              'Limpar Tudo',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Meus Favoritos',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (favorites.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'clear') {
                  _confirmClearAll(context, ref);
                } else if (value == 'fix_dragon') {
                  ref.read(favoritesProvider.notifier).removeStubbornFavorite('drag');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removendo itens duplicados...'),
                      backgroundColor: Color(0xFF1A1A2E),
                    ),
                  );
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'fix_dragon',
                  child: Row(
                    children: [
                      const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF00D4FF), size: 20),
                      const SizedBox(width: 10),
                      Text('Limpar "Casa do Dragão"', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_rounded, color: Color(0xFFE94560), size: 20),
                      const SizedBox(width: 10),
                      Text('Limpar todos', style: GoogleFonts.inter(color: const Color(0xFFE94560), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7B2FF7).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 64,
                        color: Color(0xFF00D4FF),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sua lista está vazia',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Salve seus filmes e séries favoritos para assistir quando quiser!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2FF7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                        shadowColor: const Color(0xFF7B2FF7).withValues(alpha: 0.4),
                      ),
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.explore_rounded, size: 20),
                      label: Text(
                        'Explorar Catálogo',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                String imageUrl = '';
                String title = '';
                double rating = 0.0;
                String type = 'movie';

                if (item is Movie) {
                  imageUrl = item.fullPosterUrl;
                  title = item.title;
                  rating = item.voteAverage;
                  type = 'movie';
                } else if (item is Series) {
                  imageUrl = item.fullPosterUrl;
                  title = item.name;
                  rating = item.voteAverage;
                  type = 'tv';
                }

                final itemId = item.id.toString();

                return Stack(
                  children: [
                    Positioned.fill(
                      child: ContentCard(
                        imageUrl: imageUrl,
                        title: title,
                        rating: rating,
                        tag: 'favorites_screen_$itemId',
                        onTap: () {
                          context.push('/detail/$itemId', extra: {'type': type});
                        },
                      ),
                    ),
                    // Botão de desfavoritar no topo do card
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await ref.read(favoritesProvider.notifier).removeFavorite(itemId, title: title);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: const Color(0xFF7B2FF7).withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF221A3E),
                                duration: const Duration(milliseconds: 2200),
                                content: Text(
                                  '"$title" removido dos favoritos',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                action: SnackBarAction(
                                  label: 'Desfazer',
                                  textColor: const Color(0xFF00D4FF),
                                  onPressed: () {
                                    ref.read(favoritesProvider.notifier).toggleFavorite(item);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE94560).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFE94560),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
