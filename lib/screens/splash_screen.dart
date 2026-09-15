import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poltro_play/core/services/notification_service.dart';
import 'package:poltro_play/core/services/rewards_service.dart';
import 'package:poltro_play/providers/content_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();
    
    final user = FirebaseAuth.instance.currentUser;
    
    // Se o usuário estiver logado, fazemos o pré-carregamento dos dados
    if (user != null) {
      try {
        // Dispara as requisições principais do Firestore em paralelo
        // Ao usar ref.read() nestes FutureProviders, o Riverpod inicia o fetch imediatamente
        final results = await Future.wait([
          ref.read(highlightsProvider.future),
          ref.read(popularMoviesProvider.future),
          ref.read(popularSeriesProvider.future),
        ]);
        await RewardsService().syncWithFirestore();
        
        // Pega as imagens de destaque e já salva no cache de memória do celular
        // Assim, quando a home abrir, as imagens já estarão lá instantaneamente
        final highlights = results[0];
        
        for (final item in highlights.take(5)) {
          String? imageUrl;
          if (item is Map) continue; // Pular promos se não tiverem imagem clara
          
          try {
            imageUrl = item.fullPosterUrl;
          } catch (_) {}
          
          if (imageUrl != null && imageUrl.isNotEmpty && mounted) {
            // Usa o mesmo gerenciador de cache criado no ContentCard
            final cacheManager = cache.CacheManager(cache.Config('moviePostersCache', stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 2000));
            precacheImage(CachedNetworkImageProvider(imageUrl, cacheManager: cacheManager), context)
                .catchError((_) {}); // Ignora falhas individuais de imagem
          }
        }
      } catch (e) {
        print("Erro no pré-carregamento: $e");
        // O erro será tratado silenciosamente, o app continuará abrindo
      }
    }

    // Garante que a splash screen dure pelo menos 1.8 segundos
    // para a animação da logo não piscar rápido demais caso o carregamento seja rápido
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 1800) {
      await Future.delayed(Duration(milliseconds: 1800 - elapsed));
    }

    if (!mounted) return;

    if (user != null) {
      context.go('/home');
      
      if (NotificationService.pendingRoute != null) {
        context.push(NotificationService.pendingRoute!, extra: NotificationService.pendingExtra);
        NotificationService.pendingRoute = null;
        NotificationService.pendingExtra = null;
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0A0A0A),
            ],
            radius: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/logo-01-sem-fundo.png',
                  height: 120, 
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Seus filmes e séries favoritos',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7B2FF7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparando catálogo...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
