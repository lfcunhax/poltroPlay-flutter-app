class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'PoltroPlay';

  // TMDB API
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbApiKey = '384caf4e90af984a7c5595ea5d9bb386'; // Replace with your TMDB API key

  // TMDB Image Base URLs
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/';
  static const String imageBaseUrlW185 = '${imageBaseUrl}w185';
  static const String imageBaseUrlW342 = '${imageBaseUrl}w342';
  static const String imageBaseUrlW500 = '${imageBaseUrl}w500';
  static const String imageBaseUrlW780 = '${imageBaseUrl}w780';
  static const String imageBaseUrlOriginal = '${imageBaseUrl}original';
  static const String imageBaseUrlW1280 = '${imageBaseUrl}w1280';

  // AdMob - Test Ad Unit IDs (replace with real IDs for production)
  static const String admobAppId = 'ca-app-pub-4692366968655291~3011715254';
  static const String bannerAdUnitId = 'ca-app-pub-4692366968655291/8902336183';
  static const String interstitialAdUnitId = 'ca-app-pub-4692366968655291/1023846161';

  // Sample Video URL for testing (HLS M3U8 Stream to simulate Xtream API)
  static const String sampleVideoUrl =
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
}
