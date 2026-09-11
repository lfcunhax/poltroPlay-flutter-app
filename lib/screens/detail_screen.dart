import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/core/constants/app_constants.dart';
import 'package:poltro_play/providers/favorites_provider.dart';
import 'package:poltro_play/core/services/ad_service.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/episode.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/widgets/shimmer_loading.dart';
import 'package:poltro_play/widgets/episodes_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poltro_play/widgets/pipocas_badge.dart';
import 'package:poltro_play/providers/rewards_provider.dart';
import 'package:poltro_play/widgets/rewards_modal.dart';
class DetailScreen extends ConsumerWidget {
  final String contentId;
  final String mediaType;

  const DetailScreen({
    super.key,
    required this.contentId,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMovie = mediaType == 'movie';
    final detailAsync = isMovie
        ? ref.watch(movieDetailProvider(contentId))
        : ref.watch(seriesDetailProvider(contentId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: detailAsync.when(
        data: (detail) => _buildContent(context, ref, detail, isMovie),
        loading: () => const ShimmerDetailPage(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFE94560), size: 48),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar detalhes',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar', style: TextStyle(color: Color(0xFF00D4FF))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic detail, bool isMovie) {
    final String title = isMovie ? (detail as Movie).title : (detail as Series).name;
    final String overview = detail.overview ?? '';
    final String? backdropPath = detail.backdropPath;
    final String? posterPath = detail.posterPath;
    final double voteAverage = detail.voteAverage;
    final String year = isMovie
        ? (detail as Movie).year
        : (detail as Series).year;
    final String backdropUrl = backdropPath != null
        ? '${AppConstants.imageBaseUrlW1280}$backdropPath'
        : (posterPath != null
            ? '${AppConstants.imageBaseUrlW500}$posterPath'
            : '');
    final String videoUrl = (detail is Movie) ? (detail.videoUrl ?? AppConstants.sampleVideoUrl) : ((detail as Series).videoUrl ?? AppConstants.sampleVideoUrl);

    final isFavorite = ref.watch(favoritesProvider).any((e) => e.id == detail.id);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: const Color(0xFF0A0A0A),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: PipocasBadge(),
            ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? const Color(0xFFE94560) : Colors.white,
              ),
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(detail);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (backdropUrl.isNotEmpty)
                  Hero(
                    tag: 'poster_$contentId',
                    child: CachedNetworkImage(
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF1A1A2E),
                        child: const Center(
                          child: Icon(Icons.movie, color: Colors.white24, size: 64),
                        ),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0A0A0A).withValues(alpha: 0.7),
                        const Color(0xFF0A0A0A),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Rating, year, seasons
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      voteAverage.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      year,
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    if (!isMovie) ...[
                      const SizedBox(width: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          int? numSeasons = (detail as Series).numberOfSeasons;
                          if (numSeasons == null) {
                            final episodesAsync = ref.watch(seriesEpisodesProvider(contentId));
                            if (episodesAsync.hasValue && episodesAsync.value != null && episodesAsync.value!.isNotEmpty) {
                              numSeasons = episodesAsync.value!.map((e) => e.seasonNumber).toSet().length;
                            }
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF7B2FF7)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${numSeasons ?? '?'} Temporadas',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Genre chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (detail.tags).map<Widget>((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: const Color(0xFF1A1A2E),
                      side: const BorderSide(color: Color(0xFF7B2FF7)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Watch button with interstitial ad
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2FF7), Color(0xFF9D5CFF)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B2FF7).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Incrementa as visualizações no Firestore
                            try {
                              final collectionName = isMovie ? 'movies' : 'series';
                              await FirebaseFirestore.instance.collection(collectionName).doc(contentId).update({
                                'views': FieldValue.increment(1)
                              });
                            } catch (e) {
                              print("Erro ao atualizar views: $e");
                            }

                            AdService().showInterstitialAd(() {
                              if (context.mounted) {
                                if (isMovie) {
                                  context.push('/player', extra: {
                                    'videoUrl': videoUrl,
                                    'title': title,
                                    'contentId': contentId,
                                    'contentType': mediaType,
                                    'posterPath': posterPath,
                                  });
                                } else {
                                  // Pegar o primeiro episódio da série
                                  final episodesAsync = ref.read(seriesEpisodesProvider(contentId));
                                  episodesAsync.whenData((episodes) {
                                    if (episodes.isEmpty) return;
                                    
                                    // Ordena e pega o S01E01 (ou o primeiro disponível)
                                    final sortedEpis = List<Episode>.from(episodes)
                                      ..sort((a, b) {
                                        if (a.seasonNumber != b.seasonNumber) return a.seasonNumber.compareTo(b.seasonNumber);
                                        return a.episodeNumber.compareTo(b.episodeNumber);
                                      });
                                    
                                    final firstEp = sortedEpis.first;
                                    
                                    context.push('/player', extra: {
                                      'videoUrl': firstEp.videoUrl,
                                      'title': '$title - S${firstEp.seasonNumber}E${firstEp.episodeNumber}: ${firstEp.title}',
                                      'contentId': contentId,
                                      'contentType': 'tv',
                                      'posterPath': posterPath,
                                      'episodes': sortedEpis,
                                      'initialEpisodeIndex': 0,
                                    });
                                  });
                                }
                              }
                            });
                          },
                          icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                          label: Text(
                            'Assistir',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(27),
                        border: Border.all(color: const Color(0xFF7B2FF7)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.smart_display_rounded, color: Colors.white, size: 26),
                        tooltip: 'Ver Trailer',
                        onPressed: () async {
                           final String tmdbIdStr = isMovie ? (detail as Movie).tmdbId.toString() : (detail as Series).tmdbId.toString();
                           final videos = await ref.read(videosProvider(MediaParams(mediaType: mediaType, id: tmdbIdStr)).future);
                           if (videos.isNotEmpty) {
                             final trailer = videos.firstWhere(
                               (v) => v.type == 'Trailer' && v.site == 'YouTube', 
                               orElse: () => videos.firstWhere((v) => v.site == 'YouTube', orElse: () => videos.first)
                             );
                             if (trailer.site == 'YouTube') {
                               if (context.mounted) {
                                 context.push('/player', extra: {
                                   'videoUrl': trailer.key,
                                   'title': title,
                                   'contentId': contentId,
                                   'contentType': mediaType,
                                   'posterPath': posterPath,
                                   'isTrailer': true,
                                 });
                               }
                             }
                           } else {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trailer não encontrado')));
                             }
                           }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pipocas & VIP Status Banner
                Consumer(
                  builder: (context, ref, _) {
                    final rewards = ref.watch(rewardsProvider);
                    if (rewards.isAdFreeActive) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9900).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFF9900).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Modo VIP Ativo: assistindo 100% sem anúncios!',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFFB300),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return InkWell(
                      onTap: () {
                        if (rewards.balance >= 10) {
                          final success = ref.read(rewardsProvider.notifier).usePipocasForMovie();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF00D4FF),
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  '🍿 -10 Pipocas! Modo sem anúncios ativado por 2 horas.',
                                  style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        } else {
                          showRewardsModal(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Text('🍿', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rewards.balance >= 10
                                    ? 'Assistir esta sessão sem anúncios (-10 Pipocas)'
                                    : 'Saldo: ${rewards.balance} Pipocas. Toque para ganhar mais!',
                                style: GoogleFonts.inter(
                                  color: rewards.balance >= 10 ? const Color(0xFF00D4FF) : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Synopsis (Glassmorphism)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B2FF7).withValues(alpha: 0.05),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sinopse',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            overview.isNotEmpty ? overview : 'Sinopse não disponível.',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Episodes Section for Series
                if (!isMovie) ...[
                  EpisodesSection(
                    seriesId: contentId,
                    seriesTitle: title,
                    posterPath: posterPath,
                  ),
                ],

                // Cast Section
                const SizedBox(height: 24),
                Text(
                  'Elenco Principal',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final String tmdbIdStr = isMovie ? (detail as Movie).tmdbId.toString() : (detail as Series).tmdbId.toString();
                      final creditsAsync = ref.watch(creditsProvider(MediaParams(mediaType: mediaType, id: tmdbIdStr)));
                      return creditsAsync.when(
                        data: (cast) {
                          if (cast.isEmpty) return const Text('Elenco não disponível', style: TextStyle(color: Colors.white70));
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: cast.length > 10 ? 10 : cast.length, // top 10
                            itemBuilder: (context, index) {
                              final member = cast[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 80,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: const Color(0xFF1A1A2E),
                                        backgroundImage: member.profilePath != null 
                                            ? CachedNetworkImageProvider('${AppConstants.imageBaseUrlW185}${member.profilePath}')
                                            : null,
                                        child: member.profilePath == null ? const Icon(Icons.person, color: Colors.white54) : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        member.name,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        member.character,
                                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
                                        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FF7))),
                        error: (err, stack) => const SizedBox(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
