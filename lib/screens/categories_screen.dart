import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  IconData _getIconForGenre(String name) {
    switch (name.toLowerCase()) {
      case 'ação': return Icons.bolt;
      case 'aventura': return Icons.explore;
      case 'comédia': return Icons.sentiment_very_satisfied;
      case 'drama': return Icons.theater_comedy;
      case 'terror': return Icons.dark_mode;
      case 'romance': return Icons.favorite;
      case 'ficção': return Icons.rocket;
      case 'ficção científica': return Icons.rocket;
      case 'documentário': return Icons.article;
      case 'animação': return Icons.animation;
      case 'crime': return Icons.local_police;
      case 'mistério': return Icons.search;
      case 'família': return Icons.family_restroom;
      default: return Icons.movie;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Categorias', style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Nenhuma categoria encontrada', style: TextStyle(color: Colors.white70)));
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final genreName = categories[index];
              return GestureDetector(
                onTap: () {
                  context.push('/categories/${Uri.encodeComponent(genreName)}', extra: genreName);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF7B2FF7).withValues(alpha: 0.7), const Color(0xFF00D4FF).withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getIconForGenre(genreName), color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        genreName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
        error: (err, stack) => Center(child: Text('Erro ao carregar categorias: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF1A1A2E),
          highlightColor: const Color(0xFF2A2A4E),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
