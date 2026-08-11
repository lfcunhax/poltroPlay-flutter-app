import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:poltro_play/models/movie.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text('Filmes', style: GoogleFonts.outfit(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7B2FF7),
          labelColor: const Color(0xFF7B2FF7),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Populares'),
            Tab(text: 'Mais Votados'),
            Tab(text: 'Lançamentos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMovieGrid(popularMoviesProvider),
          _buildMovieGrid(topRatedMoviesProvider),
          _buildMovieGrid(nowPlayingMoviesProvider),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(FutureProvider<List<Movie>> provider) {
    final moviesAsync = ref.watch(provider);

    return RefreshIndicator(
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: () async {
        ref.invalidate(provider);
      },
      child: moviesAsync.when(
        data: (movies) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return ContentCard(
                imageUrl: movie.fullPosterUrl,
                title: movie.title,
                rating: movie.voteAverage,
                tag: 'movies_screen_${movie.id}',
                onTap: () {
                  context.push('/detail/${movie.id}', extra: {'type': 'movie'});
                },
              );
            },
          );
        },
        loading: () => _buildShimmerGrid(),
        error: (err, stack) => const Center(
          child: Text('Erro ao carregar filmes', style: TextStyle(color: Colors.red)),
        ),
      ),
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
