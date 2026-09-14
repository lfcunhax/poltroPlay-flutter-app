import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;

import 'package:poltro_play/widgets/cinematic_poster_placeholder.dart';

class ContentCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double rating;
  final VoidCallback onTap;
  final double width;
  final double height;
  final String tag;

  // Gerenciador de cache customizado com capacidade para muito mais capas de filmes
  static final cache.CacheManager _movieImageCacheManager = cache.CacheManager(
    cache.Config(
      'moviePostersCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000, // Aumentado de 200 (padrão) para 2000 imagens
    ),
  );

  const ContentCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.rating,
    required this.onTap,
    this.width = 150.0,
    this.height = 225.0,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: tag,
                child: imageUrl.trim().isEmpty
                    ? CinematicPosterPlaceholder(title: title)
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        cacheManager: _movieImageCacheManager,
                        memCacheWidth: 350,
                        memCacheHeight: 525,
                        maxWidthDiskCache: 600,
                        maxHeightDiskCache: 900,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF161326),
                          child: const Center(
                            child: Icon(
                              Icons.movie_creation_outlined,
                              color: Color(0x337B2FF7),
                              size: 32,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => CinematicPosterPlaceholder(title: title),
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
