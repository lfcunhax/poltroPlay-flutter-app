import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:poltro_play/models/episode.dart';
import 'package:poltro_play/providers/content_provider.dart';

class EpisodesSection extends ConsumerStatefulWidget {
  final String seriesId;
  final String seriesTitle;
  final String? posterPath;

  const EpisodesSection({
    super.key,
    required this.seriesId,
    required this.seriesTitle,
    this.posterPath,
  });

  @override
  ConsumerState<EpisodesSection> createState() => _EpisodesSectionState();
}

class _EpisodesSectionState extends ConsumerState<EpisodesSection> {
  int _selectedSeason = 1;

  @override
  Widget build(BuildContext context) {
    final episodesAsync = ref.watch(seriesEpisodesProvider(widget.seriesId));

    return episodesAsync.when(
      data: (episodes) {
        if (episodes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Nenhum episódio disponível no momento.', style: TextStyle(color: Colors.white70)),
          );
        }

        // Extract unique seasons
        final seasons = episodes.map((e) => e.seasonNumber).toSet().toList()..sort();
        if (!seasons.contains(_selectedSeason) && seasons.isNotEmpty) {
          // If the selected season isn't in the list, default to the first one available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedSeason = seasons.first;
            });
          });
        }

        final currentEpisodes = episodes.where((e) => e.seasonNumber == _selectedSeason).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Temporadas e Episódios',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Season Selector
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: seasons.length,
                itemBuilder: (context, index) {
                  final season = seasons[index];
                  final isSelected = season == _selectedSeason;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text('Temporada $season'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSeason = season;
                          });
                        }
                      },
                      backgroundColor: const Color(0xFF1A1A2E),
                      selectedColor: const Color(0xFF7B2FF7),
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF9D5CFF) : Colors.white12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Episodes List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentEpisodes.length,
              itemBuilder: (context, index) {
                final ep = currentEpisodes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          '${ep.episodeNumber}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      ep.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'T${ep.seasonNumber.toString().padLeft(2, '0')} E${ep.episodeNumber.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Color(0xFF00D4FF), size: 36),
                      onPressed: () {
                        context.push('/player', extra: {
                          'videoUrl': ep.videoUrl,
                          'title': '${widget.seriesTitle} - S${ep.seasonNumber}E${ep.episodeNumber}: ${ep.title}',
                          'contentId': widget.seriesId,
                          'contentType': 'tv',
                          'posterPath': widget.posterPath,
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF7B2FF7)),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Erro ao carregar episódios.', style: TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}
