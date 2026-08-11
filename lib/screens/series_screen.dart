import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:poltro_play/models/series.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> with SingleTickerProviderStateMixin {
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
        title: Text('Séries', style: GoogleFonts.outfit(color: Colors.white)),
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
            Tab(text: 'Mais Votadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeriesGrid(popularSeriesProvider),
          _buildSeriesGrid(topRatedSeriesProvider),
        ],
      ),
    );
  }

  Widget _buildSeriesGrid(FutureProvider<List<Series>> provider) {
    final seriesAsync = ref.watch(provider);

    return RefreshIndicator(
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: () async {
        ref.invalidate(provider);
      },
      child: seriesAsync.when(
        data: (series) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: series.length,
            itemBuilder: (context, index) {
              final show = series[index];
              return ContentCard(
                imageUrl: show.fullPosterUrl,
                title: show.name,
                rating: show.voteAverage,
                tag: 'series_screen_${show.id}',
                onTap: () {
                  context.push('/detail/${show.id}', extra: {'type': 'tv'});
                },
              );
            },
          );
        },
        loading: () => _buildShimmerGrid(),
        error: (err, stack) => const Center(
          child: Text('Erro ao carregar séries', style: TextStyle(color: Colors.red)),
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
