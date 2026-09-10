import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:shimmer/shimmer.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(paginatedMoviesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = ref.watch(paginatedMoviesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text('Filmes', style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00D4FF),
        backgroundColor: const Color(0xFF1A1A2E),
        onRefresh: () async {
          await ref.read(paginatedMoviesProvider.notifier).refresh();
        },
        child: _buildBody(moviesState),
      ),
    );
  }

  Widget _buildBody(PaginatedState moviesState) {
    final movies = moviesState.items;

    // Estado inicial de carregamento
    if (movies.isEmpty && moviesState.isLoading) {
      return _buildShimmerGrid();
    }

    // Sem filmes
    if (movies.isEmpty && !moviesState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Nenhum filme encontrado',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Grid com scroll infinito
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      // +1 para o indicador de carregamento no final
      itemCount: movies.length + (moviesState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Indicador de carregamento no final da lista
        if (index >= movies.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF7B2FF7),
                ),
              ),
            ),
          );
        }

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
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
