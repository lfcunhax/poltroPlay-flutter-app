import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/rewards_provider.dart';
import 'package:poltro_play/widgets/banner_ad_widget.dart';
import 'package:poltro_play/widgets/daily_checkin_modal.dart';
import 'package:poltro_play/widgets/pipocas_badge.dart';
import 'package:poltro_play/widgets/rewards_onboarding_modal.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static bool _hasTriggeredInitialPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowInitialRewardsPopup();
    });
  }

  void _checkAndShowInitialRewardsPopup() {
    if (!mounted || _hasTriggeredInitialPopup) return;
    _hasTriggeredInitialPopup = true;

    final rewards = ref.read(rewardsProvider);
    if (!rewards.hasSeenTutorial) {
      showRewardsOnboardingModal(context);
    } else if (rewards.canClaimDailyBonus) {
      showDailyCheckInModal(context);
    }
  }

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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: PipocasBadge(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: widget.child),
          const BannerAdWidget(), // Always visible ad
          const SizedBox(height: 90), // Offset for the translucent bottom nav bar
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomBar(currentIndex),
    ),
    );
  }

  Widget _buildFloatingBottomBar(int currentIndex) {
    const navItems = [
      _NavItemData(icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.tv_rounded, label: 'Séries'),
      _NavItemData(icon: Icons.movie_rounded, label: 'Filmes'),
      _NavItemData(icon: Icons.category_rounded, label: 'Categorias'),
      _NavItemData(icon: Icons.favorite_rounded, label: 'Favoritos'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.25),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1F183D).withValues(alpha: 0.88),
                      const Color(0xFF100D24).withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final isSelected = currentIndex == index;

                    return _FloatingNavItem(
                      data: item,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _onItemTapped(index, context);
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}

class _FloatingNavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF7B2FF7).withValues(alpha: 0.38),
                    const Color(0xFF00D4FF).withValues(alpha: 0.18),
                  ],
                )
              : null,
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                data.icon,
                size: 22,
                color: isSelected ? const Color(0xFF00D4FF) : Colors.white54,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white54,
                letterSpacing: 0.2,
              ),
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
