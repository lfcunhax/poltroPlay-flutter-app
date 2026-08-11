import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/widgets/banner_ad_widget.dart';
import 'package:poltro_play/widgets/cast_button.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/series')) return 1;
    if (location.startsWith('/movies')) return 2;
    if (location.startsWith('/categories')) return 3;
    if (location.startsWith('/favorites')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/series');
        break;
      case 2:
        context.go('/movies');
        break;
      case 3:
        context.go('/categories');
        break;
      case 4:
        context.go('/favorites');
        break;
    }
  }

  Future<void> _handleAppExit(BuildContext context) async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Sair do app?',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Você tem certeza que deseja sair do PoltroPlay?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Ficar',
                style: GoogleFonts.inter(color: const Color(0xFF00D4FF), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Sair',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _calculateSelectedIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleAppExit(context);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBody: true, // Allows content to scroll behind the bottom nav bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent for glassy look if needed
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.7),
            ),
          ),
        ),
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'PoltroPlay',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/search'),
          ),
          const CastButton(
            size: 24.0,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: child),
          const BannerAdWidget(), // Always visible ad
          const SizedBox(height: 90), // Offset for the translucent bottom nav bar
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.6), // Translucent dark
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  currentIndex: currentIndex,
                  onTap: (index) => _onItemTapped(index, context),
                  selectedItemColor: const Color(0xFF00D4FF),
                  unselectedItemColor: Colors.white54,
                  selectedLabelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 12,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      activeIcon: _GlowIcon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.tv_rounded),
                      activeIcon: _GlowIcon(Icons.tv_rounded),
                      label: 'Séries',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.movie_rounded),
                      activeIcon: _GlowIcon(Icons.movie_rounded),
                      label: 'Filmes',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.category_rounded),
                      activeIcon: _GlowIcon(Icons.category_rounded),
                      label: 'Categorias',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.favorite_rounded),
                      activeIcon: _GlowIcon(Icons.favorite_rounded),
                      label: 'Favoritos',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  final IconData icon;
  
  const _GlowIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF00D4FF)),
    );
  }
}
