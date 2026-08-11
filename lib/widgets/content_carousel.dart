import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';
import 'package:poltro_play/models/promotion.dart';

class ContentCarousel extends StatefulWidget {
  final List<dynamic> items; // Can be a strongly typed model in real usage
  final Function(dynamic) onItemTap;

  const ContentCarousel({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  State<ContentCarousel> createState() => _ContentCarouselState();
}

class _ContentCarouselState extends State<ContentCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox(height: 250);
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index, realIndex) {
            final item = widget.items[index];
            final isPromo = item is Promotion;
            
            String imageUrl = '';
            String title = '';
            String overview = '';
            double rating = 0.0;
            String buttonText = 'Assistir';
            IconData buttonIcon = Icons.play_arrow;

            if (isPromo) {
              imageUrl = item.imageUrl;
              title = item.title;
              overview = 'Patrocinado';
              buttonText = 'Acessar';
              buttonIcon = Icons.open_in_new;
            } else {
              final String? backdropPath = item.backdropPath;
              imageUrl = backdropPath != null && backdropPath.isNotEmpty 
                  ? 'https://image.tmdb.org/t/p/w1280$backdropPath' 
                  : '';
              title = item is Movie ? item.title : (item is Series ? item.name : 'No Title');
              overview = item.overview ?? '';
              rating = (item.voteAverage ?? 0.0) as double;
            }

            return GestureDetector(
              onTap: () => widget.onItemTap(item),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7B2FF7),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Icon(Icons.error, color: Colors.white),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.95),
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPromo) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFFFD700),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (overview.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                overview,
                                style: GoogleFonts.inter(
                                  color: isPromo ? const Color(0xFF00D4FF) : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isPromo ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => widget.onItemTap(item),
                              icon: Icon(buttonIcon, color: Colors.white),
                              label: Text(
                                buttonText,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B2FF7), // primary
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 250,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.items.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key
                    ? const Color(0xFF00D4FF) // accent
                    : Colors.white.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
