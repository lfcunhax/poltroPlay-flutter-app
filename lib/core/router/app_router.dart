
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poltro_play/providers/auth_provider.dart';
import 'package:poltro_play/screens/splash_screen.dart';
import 'package:poltro_play/screens/login_screen.dart';
import 'package:poltro_play/screens/main_shell.dart';
import 'package:poltro_play/screens/home_screen.dart';
import 'package:poltro_play/screens/series_screen.dart';
import 'package:poltro_play/screens/movies_screen.dart';
import 'package:poltro_play/screens/categories_screen.dart';
import 'package:poltro_play/screens/category_detail_screen.dart';
import 'package:poltro_play/screens/favorites_screen.dart';
import 'package:poltro_play/screens/detail_screen.dart';
import 'package:poltro_play/screens/player_screen.dart';
import 'package:poltro_play/screens/settings_screen.dart';
import 'package:poltro_play/screens/search_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isSplash = state.uri.path == '/splash';
      final isLoggingIn = state.uri.path == '/login';

      // Don't redirect while on splash (initialization in progress)
      if (isSplash) return null;

      final isLoggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/series',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SeriesScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MoviesScreen(),
            ),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesScreen(),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/categories/:id',
        builder: (context, state) {
          final genreNameId = state.pathParameters['id'] ?? '';
          final genreName = state.extra as String? ?? Uri.decodeComponent(genreNameId);
          return CategoryDetailScreen(
            genreName: genreName,
          );
        },
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) {
          final contentId = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final mediaType = extra['type'] as String? ?? 'movie';
          return DetailScreen(
            contentId: contentId,
            mediaType: mediaType,
          );
        },
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PlayerScreen(
            videoUrl: extra['videoUrl'] as String? ??
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            title: extra['title'] as String? ?? 'PoltroPlay',
            contentId: extra['contentId'] as String? ?? '',
            contentType: extra['contentType'] as String? ?? 'movie',
            posterPath: extra['posterPath'] as String?,
            isTrailer: extra['isTrailer'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
});
