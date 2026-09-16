import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/providers/watch_progress_provider.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/promotion.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:poltro_play/widgets/content_carousel.dart';
import 'package:poltro_play/widgets/continue_watching_card.dart';
import 'package:poltro_play/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights = ref.watch(highlightsProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final popularSeries = ref.watch(popularSeriesProvider);
    final topRatedMovies = ref.watch(topRatedMoviesProvider);
    final nowPlaying = ref.watch(nowPlayingMoviesProvider);
    final newlyAdded = ref.watch(newlyAddedMoviesProvider);
    final watchProgressList = ref.watch(watchProgressListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: const Color(0xFF00D4FF),
        backgroundColor: const Color(0xFF1A1A2E),
        onRefresh: () async {
          ref.invalidate(highlightsProvider);
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(popularMoviesProvider);
          ref.invalidate(popularSeriesProvider);
          ref.invalidate(topRatedMoviesProvider);
          ref.invalidate(nowPlayingMoviesProvider);
          ref.invalidate(newlyAddedMoviesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured Carousel
              highlights.when(
                data: (items) => ContentCarousel(
                  items: items.take(10).toList(),
                  onItemTap: (item) async {
                    if (item is Promotion) {
                      if (item.contentId != null && item.contentId!.isNotEmpty) {
                        final type = item.contentType ?? 'movie';
                        context.push('/detail/${item.contentId}', extra: {'type': type});
                        return;
                      }
                      if (item.targetUrl.isNotEmpty) {
                        final url = Uri.parse(item.targetUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      }
                    } else {
                      final type = item is Movie ? 'movie' : 'tv';
                      final id = item is Movie ? item.id : (item as Series).id;
                      context.push('/detail/$id', extra: {'type': type});
                    }
                  },
                ),
                loading: () => _buildCarouselShimmer(),
                error: (_, __) => _buildErrorSection('Erro ao carregar destaques'),
              ),
              
              // Botão Sortear Integrado (Roleta)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2FF7).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _spinRoulette(context, ref),
                    icon: const Icon(Icons.casino, color: Colors.white, size: 28),
                    label: Text(
                      'Roleta do Destino',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Continue Watching
              if (watchProgressList.isNotEmpty) ...[
                SectionHeader(
                  title: 'Continue Assistindo',
                  onSeeAllTap: null,
                ),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: watchProgressList.length,
                    itemBuilder: (context, index) {
                      final progress = watchProgressList[index];
                      return ContinueWatchingCard(
                        watchProgress: progress,
                        onTap: () {
                          context.push('/player', extra: {
                            'videoUrl': progress.videoUrl,
                            'title': progress.title,
                            'contentId': progress.contentId,
                            'contentType': progress.contentType,
                            'posterPath': progress.posterPath,
                          });
                        },
                        onRemove: () {
                          ref.read(watchProgressListProvider.notifier)
                              .removeProgress(progress.contentId);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Popular Movies
              _buildContentSection(
                context: context,
                title: 'Filmes Populares',
                asyncValue: popularMovies,
                mediaType: 'movie',
                sectionId: 'popular',
              ),

              // Popular Series
              _buildSeriesSection(
                context: context,
                title: 'Séries Populares',
                asyncValue: popularSeries,
                sectionId: 'popular_series',
              ),

              // Top Rated
              _buildContentSection(
                context: context,
                title: 'Mais Votados',
                asyncValue: topRatedMovies,
                mediaType: 'movie',
                sectionId: 'top_rated',
              ),

              // Lançamentos verificados por ano de lançamento
              _buildContentSection(
                context: context,
                title: 'Lançamentos',
                asyncValue: nowPlaying,
                mediaType: 'movie',
                sectionId: 'now_playing',
              ),

              // Adicionados Recentemente ao Catálogo
              _buildContentSection(
                context: context,
                title: 'Adicionados Recentemente',
                asyncValue: newlyAdded,
                mediaType: 'movie',
                sectionId: 'newly_added',
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _spinRoulette(BuildContext context, WidgetRef ref) {
    final popMovies = ref.read(popularMoviesProvider).value ?? [];
    final popSeries = ref.read(popularSeriesProvider).value ?? [];
    final allContent = [...popMovies, ...popSeries];

    if (allContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carregando catálogo, tente novamente!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.casino, size: 80, color: Color(0xFF00D4FF)),
                    const SizedBox(height: 16),
                    Text(
                      'Sorteando...',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog
      final random = Random();
      final randomIndex = random.nextInt(allContent.length);
      final selectedContent = allContent[randomIndex];
      
      final type = selectedContent is Movie ? 'movie' : 'tv';
      final id = selectedContent is Movie ? selectedContent.id : (selectedContent as Series).id;
      
      context.push('/detail/$id', extra: {'type': type});
    });
  }

  Widget _buildContentSection({
    required BuildContext context,
    required String title,
    required AsyncValue<List<Movie>> asyncValue,
    required String mediaType,
    required String sectionId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 240,
          child: asyncValue.when(
            data: (items) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final movie = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ContentCard(
                    imageUrl: movie.fullPosterUrl,
                    title: movie.title,
                    rating: movie.voteAverage,
                    tag: 'home_movie_${sectionId}_${movie.id}',
                    onTap: () {
                      context.push('/detail/${movie.id}', extra: {'type': mediaType});
                    },
                  ),
                );
              },
            ),
            loading: () => _buildListShimmer(),
            error: (_, __) => Center(
              child: Text('Erro ao carregar', style: GoogleFonts.inter(color: Colors.white54)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSeriesSection({
    required BuildContext context,
    required String title,
    required AsyncValue<List<Series>> asyncValue,
    required String sectionId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 240,
          child: asyncValue.when(
            data: (items) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final series = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ContentCard(
                    imageUrl: series.fullPosterUrl,
                    title: series.name,
                    rating: series.voteAverage,
                    tag: 'home_series_${sectionId}_${series.id}',
                    onTap: () {
                      context.push('/detail/${series.id}', extra: {'type': 'tv'});
                    },
                  ),
                );
              },
            ),
            loading: () => _buildListShimmer(),
            error: (_, __) => Center(
              child: Text('Erro ao carregar', style: GoogleFonts.inter(color: Colors.white54)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCarouselShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A2E),
      highlightColor: const Color(0xFF2A2A4E),
      child: Container(
        height: 250,
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1A1A2E),
          highlightColor: const Color(0xFF2A2A4E),
          child: Container(
            width: 150,
            height: 225,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection(String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text(message, style: GoogleFonts.inter(color: Colors.redAccent)),
    );
  }
}
