import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poltro_play/core/constants/app_constants.dart';
import 'package:poltro_play/providers/rewards_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final String? adUnitId;

  const BannerAdWidget({
    super.key,
    this.adUnitId,
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId ?? AppConstants.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) _loadAd();
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardsState = ref.watch(rewardsProvider);
    if (rewardsState.isAdFreeActive) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      width: double.infinity,
      color: const Color(0xFF0A0A0A),
      alignment: Alignment.center,
      child: _isLoaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : const SizedBox(),
    );
  }
}

