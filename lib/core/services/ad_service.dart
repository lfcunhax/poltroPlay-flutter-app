
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poltro_play/core/constants/app_constants.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) {
                print('Failed to show interstitial ad: $error');
              }
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('Failed to load interstitial ad: $error');
          }
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          
          // Retry logic could be added here
        },
      ),
    );
  }

  void showInterstitialAd(VoidCallback onAdClosed) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd(); // Auto-reload
          Future.delayed(const Duration(milliseconds: 100), () {
            onAdClosed();
          });
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          if (kDebugMode) {
            print('Failed to show interstitial ad: $error');
          }
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd();
          Future.delayed(const Duration(milliseconds: 100), () {
            onAdClosed();
          });
        },
      );
      try {
        _interstitialAd!.show();
      } catch (e) {
        if (kDebugMode) print('Error showing interstitial: $e');
        _isInterstitialAdReady = false;
        loadInterstitialAd();
        onAdClosed();
      }
    } else {
      if (kDebugMode) {
        print('Interstitial ad not ready yet.');
      }
      onAdClosed();
    }
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('Failed to load banner ad: $error');
          }
          ad.dispose();
        },
      ),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
