import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String genreName;

  const CategoryDetailScreen({
    super.key,
    required this.genreName,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(widget.genreName, style: const TextStyle(fontFamily: 'Outfit', color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7B2FF7),
          labelColor: const Color(0xFF7B2FF7),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Filmes'),
            Tab(text: 'Séries'),
          ],
        ),
      ),
      body: ref.watch(contentByTagProvider(widget.genreName)).when(
        data: (items) {
          final movies = items.whereType<Movie>().toList();
          final series = items.whereType<Series>().toList();
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGrid(movies, 'movie'),
              _buildGrid(series, 'tv'),
            ],
          );
        },
        loading: () => _buildShimmerGrid(),
        error: (err, stack) => Center(child: Text('Erro ao carregar: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildGrid(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo encontrado', style: TextStyle(color: Colors.white70)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        String imageUrl = '';
        String title = '';
        double rating = 0.0;

        if (item is Movie) {
          imageUrl = item.fullPosterUrl;
          title = item.title;
          rating = item.voteAverage;
        } else if (item is Series) {
          imageUrl = item.fullPosterUrl;
          title = item.name;
          rating = item.voteAverage;
        }

        return ContentCard(
          imageUrl: imageUrl,
          title: title,
          rating: rating,
          tag: 'category_detail_${item.id}',
          onTap: () {
            context.push('/detail/${item.id}', extra: {'type': type});
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF1A1A2E),
          highlightColor: const Color(0xFF2A2A4E),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
