import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:poltro_play/widgets/content_card.dart';
import 'package:poltro_play/widgets/movie_request_modal.dart';
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
        actions: [
          IconButton(
            tooltip: 'Fazer Pedido de Filme ou Série',
            icon: const Icon(Icons.post_add_rounded, color: Color(0xFF00D4FF)),
            onPressed: () => showMovieRequestModal(
              context,
              initialTitle: _query.isNotEmpty ? _query : null,
            ),
          ),
        ],
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161326),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 42,
                        color: Color(0xFF00D4FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Não encontrou "$_query"?',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Faça o pedido agora mesmo! Nossa equipe receberá sua sugestão e você será avisado assim que estiver disponível.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => showMovieRequestModal(
                          context,
                          initialTitle: _query,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Solicitar "$_query"',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            // Banner de Pedido de Conteúdo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: GestureDetector(
                onTap: () => showMovieRequestModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B2FF7).withValues(alpha: 0.25),
                        const Color(0xFF00D4FF).withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.movie_filter_rounded, color: Color(0xFF00D4FF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Não encontrou o que procura?',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Faça um pedido e nossa equipe adicionará!',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pedir',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
