import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/screens/categories_screen.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:shimmer/shimmer.dart';

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
    final icon = CategoriesScreen.getIconForGenre(widget.genreName);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF00D4FF), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.genreName,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF141220),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Filmes'),
                Tab(text: 'Séries'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryMoviesTab(genreName: widget.genreName),
          _CategorySeriesTab(genreName: widget.genreName),
        ],
      ),
    );
  }
}

/// Aba paginada com scroll infinito para Filmes da categoria
class _CategoryMoviesTab extends ConsumerStatefulWidget {
  final String genreName;

  const _CategoryMoviesTab({required this.genreName});

  @override
  ConsumerState<_CategoryMoviesTab> createState() => _CategoryMoviesTabState();
}

class _CategoryMoviesTabState extends ConsumerState<_CategoryMoviesTab> {
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
        _scrollController.position.maxScrollExtent - 350) {
      ref.read(categoryMoviesProvider(widget.genreName).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryMoviesProvider(widget.genreName));
    final movies = state.items;

    // Estado inicial de carregamento
    if (movies.isEmpty && state.isLoading) {
      return _buildShimmerGrid();
    }

    // Lista vazia
    if (movies.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Nenhum filme nesta categoria',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(categoryMoviesProvider(widget.genreName).notifier).refresh();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FF7),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Grid com scroll infinito suave
    return RefreshIndicator(
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: () async {
        await ref.read(categoryMoviesProvider(widget.genreName).notifier).refresh();
      },
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: movies.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= movies.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF7B2FF7),
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
            tag: 'cat_movie_${widget.genreName}_${movie.id}',
            onTap: () {
              context.push('/detail/${movie.id}', extra: {'type': 'movie'});
            },
          );
        },
      ),
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
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

/// Aba paginada com scroll infinito para Séries da categoria
class _CategorySeriesTab extends ConsumerStatefulWidget {
  final String genreName;

  const _CategorySeriesTab({required this.genreName});

  @override
  ConsumerState<_CategorySeriesTab> createState() => _CategorySeriesTabState();
}

class _CategorySeriesTabState extends ConsumerState<_CategorySeriesTab> {
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
        _scrollController.position.maxScrollExtent - 350) {
      ref.read(categorySeriesProvider(widget.genreName).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySeriesProvider(widget.genreName));
    final series = state.items;

    // Estado inicial de carregamento
    if (series.isEmpty && state.isLoading) {
      return _buildShimmerGrid();
    }

    // Lista vazia
    if (series.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Nenhuma série nesta categoria',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(categorySeriesProvider(widget.genreName).notifier).refresh();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FF7),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Grid com scroll infinito suave
    return RefreshIndicator(
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: () async {
        await ref.read(categorySeriesProvider(widget.genreName).notifier).refresh();
      },
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: series.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= series.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF7B2FF7),
                  ),
                ),
              ),
            );
          }

          final item = series[index];
          return ContentCard(
            imageUrl: item.fullPosterUrl,
            title: item.name,
            rating: item.voteAverage,
            tag: 'cat_series_${widget.genreName}_${item.id}',
            onTap: () {
              context.push('/detail/${item.id}', extra: {'type': 'tv'});
            },
          );
        },
      ),
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
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
