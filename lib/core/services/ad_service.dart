
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poltro_play/core/constants/app_constants.dart';
import 'package:poltro_play/core/services/rewards_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  bool _isLoadingRewarded = false;

  bool get isRewardedAdReady => _isRewardedAdReady;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // ──────────────────────────────────────────────────────────
  // INTERSTITIAL AD
  // ──────────────────────────────────────────────────────────
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
        },
      ),
    );
  }

  void showInterstitialAd(VoidCallback onAdClosed) {
    // 👑 SE O USUÁRIO ESTIVER COM O PASSE SEM ANÚNCIOS ATIVO, PULA O ANÚNCIO!
    if (RewardsService().isAdFreeActive) {
      if (kDebugMode) print('[AdService] Modo sem anúncios ativo! Pulando intersticial.');
      onAdClosed();
      return;
    }

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

  // ──────────────────────────────────────────────────────────
  // REWARDED AD (VÍDEO RECOMPENSADO / PIPOCAS)
  // ──────────────────────────────────────────────────────────
  void loadRewardedAd() {
    if (_isLoadingRewarded || _isRewardedAdReady) return;
    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _isLoadingRewarded = false;
          if (kDebugMode) print('[AdService] RewardedAd carregado com sucesso!');
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) print('[AdService] Failed to load rewarded ad: $error');
          _rewardedAd = null;
          _isRewardedAdReady = false;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required Function(int amount) onUserEarnedReward,
    required VoidCallback onAdClosed,
    Function(String error)? onAdFailed,
  }) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;
          loadRewardedAd(); // Recarrega para a próxima
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          if (kDebugMode) print('[AdService] Erro ao exibir rewarded ad: $error');
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;
          loadRewardedAd();
          if (onAdFailed != null) onAdFailed(error.message);
          onAdClosed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          final amount = reward.amount.toInt() > 0 ? reward.amount.toInt() : 10;
          onUserEarnedReward(amount);
        },
      );
    } else {
      if (kDebugMode) print('[AdService] Rewarded ad não está pronto ainda.');
      loadRewardedAd();
      if (onAdFailed != null) {
        onAdFailed('O anúncio ainda está carregando. Tente novamente em alguns segundos.');
      }
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
    _rewardedAd?.dispose();
  }
}
