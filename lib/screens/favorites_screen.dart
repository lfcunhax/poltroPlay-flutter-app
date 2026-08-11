import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poltro_play/providers/favorites_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Favoritos', style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 80, color: Colors.white38),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum favorito ainda',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore filmes e séries',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
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

                return Dismissible(
                  key: Key(item.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref.read(favoritesProvider.notifier).removeFavorite(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removido dos favoritos')),
                    );
                  },
                  child: ContentCard(
                    imageUrl: imageUrl,
                    title: title,
                    rating: rating,
                    tag: 'favorites_screen_${item.id}',
                    onTap: () {
                      context.push('/detail/${item.id}', extra: {'type': type});
                    },
                  ),
                );
              },
            ),
    );
  }
}
