import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:poltro_play/models/movie.dart';
import 'package:poltro_play/models/series.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {});
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = query.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (val) {
            _debounce?.cancel();
            setState(() {
              _query = val.trim();
            });
          },
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar filmes, séries...',
            hintStyle: GoogleFonts.inter(color: Colors.white54),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Color(0xFF00D4FF)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
          autofocus: true,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Se não digitou nada, mostra sugestões
    if (_query.isEmpty) {
      return _buildSuggestions();
    }

    final searchResults = ref.watch(searchProvider(_query));

    return searchResults.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  size: 80,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum resultado encontrado',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tente buscar com outras palavras',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildResultsGrid(items);
      },
      loading: () => _buildShimmerGrid(),
      error: (err, stack) => Center(
        child: Text(
          'Erro ao realizar busca',
          style: GoogleFonts.inter(color: const Color(0xFFE94560)),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestionsAsync = ref.watch(suggestionsProvider);

    return suggestionsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 80,
                  color: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Buscar filmes e séries',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Sugestões para você',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: _buildResultsGrid(items),
            ),
          ],
        );
      },
      loading: () => _buildShimmerGrid(),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Buscar filmes e séries',
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid(List<dynamic> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        String imageUrl = '';
        String title = '';
        double rating = 0.0;
        String type = 'movie';

        if (item is Movie) {
          imageUrl = item.fullPosterUrl;
          title = item.title;
          rating = item.voteAverage;
          type = 'movie';
        } else if (item is Series) {
          imageUrl = item.fullPosterUrl;
          title = item.name;
          rating = item.voteAverage;
          type = 'tv';
        }

        return ContentCard(
          imageUrl: imageUrl,
          title: title,
          rating: rating,
          tag: 'search_screen_${item.id}',
          onTap: () => context.push('/detail/${item.id}', extra: {'type': type}),
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
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A2E),
        highlightColor: const Color(0xFF2A2A4E),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
