import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poltro_play/core/services/rewards_service.dart';

final rewardsServiceProvider = Provider<RewardsService>((ref) {
  final service = RewardsService();
  service.init();
  return service;
});

class RewardsNotifier extends StateNotifier<RewardsState> {
  final RewardsService _service;

  RewardsNotifier(this._service) : super(_service.state) {
    _service.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    state = _service.state;
  }

  void addPipocasFromAd(int amount) {
    _service.addPipocasFromAd(amount);
  }

  int claimDailyBonus() {
    return _service.claimDailyBonus();
  }

  void markTutorialAsSeen() {
    _service.markTutorialAsSeen();
  }

  bool activateAdFreePass(int hours, int costPipocas) {
    return _service.activateAdFreePass(hours, costPipocas);
  }

  bool usePipocasForMovie() {
    return _service.usePipocasForMovie();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }
}

final rewardsProvider = StateNotifierProvider<RewardsNotifier, RewardsState>((ref) {
  final service = ref.watch(rewardsServiceProvider);
  return RewardsNotifier(service);
});
