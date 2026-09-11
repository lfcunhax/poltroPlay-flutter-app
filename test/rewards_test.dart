import 'package:flutter_test/flutter_test.dart';
import 'package:poltro_play/core/services/rewards_service.dart';

void main() {
  group('RewardsState & Service Unit Tests', () {
    test('Initial balance has welcome bonus of 10 pipocas', () {
      const state = RewardsState();
      expect(state.balance, 10);
      expect(state.isAdFreeActive, isFalse);
      expect(state.canClaimDailyBonus, isTrue);
    });

    test('Adding pipocas increases balance correctly', () {
      final state = const RewardsState().copyWith(balance: 20);
      expect(state.balance, 20);
    });

    test('Ad free pass activation calculates remaining time', () {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final state = RewardsState(
        balance: 20,
        adFreeUntil: futureDate,
      );

      expect(state.isAdFreeActive, isTrue);
      expect(state.remainingAdFreeTime.inMinutes, greaterThan(115));
    });

    test('Expired ad free pass is not active', () {
      final pastDate = DateTime.now().subtract(const Duration(minutes: 5));
      final state = RewardsState(
        balance: 10,
        adFreeUntil: pastDate,
      );

      expect(state.isAdFreeActive, isFalse);
      expect(state.remainingAdFreeTime, Duration.zero);
    });

    test('7-Day Streak calculation and rewards progression', () {
      // First day
      const stateDay1 = RewardsState();
      expect(stateDay1.currentEligibleStreakDay, 1);
      expect(stateDay1.todayRewardAmount, 5);

      // Yesterday check-in advances streak to day 2
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final stateDay2 = RewardsState(
        lastCheckInDate: RewardsState.formatDate(yesterday),
        streakDay: 1,
      );
      expect(stateDay2.currentEligibleStreakDay, 2);
      expect(stateDay2.todayRewardAmount, 6);

      // Day 7 advances back to Day 1 after completing the week
      final stateDay7 = RewardsState(
        lastCheckInDate: RewardsState.formatDate(yesterday),
        streakDay: 7,
      );
      expect(stateDay7.currentEligibleStreakDay, 1);
      expect(stateDay7.todayRewardAmount, 5);

      // Missed day resets streak to 1
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final stateReset = RewardsState(
        lastCheckInDate: RewardsState.formatDate(twoDaysAgo),
        streakDay: 4,
      );
      expect(stateReset.currentEligibleStreakDay, 1);
      expect(stateReset.todayRewardAmount, 5);
    });

    test('Daily Rewarded Ads limit and cooldown rules', () {
      const freshState = RewardsState();
      expect(freshState.remainingRewardedAdsToday, 8);
      expect(freshState.canWatchRewardedAd, isTrue);

      // 8 ads watched today hits max limit
      final today = RewardsState.formatDate(DateTime.now());
      final maxedState = RewardsState(
        lastRewardedAdDate: today,
        rewardedAdsWatchedToday: 8,
      );
      expect(maxedState.remainingRewardedAdsToday, 0);
      expect(maxedState.canWatchRewardedAd, isFalse);

      // Active cooldown (e.g. ad watched 10 seconds ago)
      final tenSecondsAgo = DateTime.now().subtract(const Duration(seconds: 10)).millisecondsSinceEpoch;
      final cooldownState = RewardsState(
        lastRewardedAdDate: today,
        rewardedAdsWatchedToday: 2,
        lastRewardedAdTimestamp: tenSecondsAgo,
      );
      expect(cooldownState.canWatchRewardedAd, isFalse);
      expect(cooldownState.rewardedAdCooldownRemaining.inSeconds, inInclusiveRange(30, 35));
    });

    test('Serialization roundtrip preserves all fields', () {
      final original = RewardsState(
        balance: 45,
        adFreeUntil: DateTime.now().add(const Duration(hours: 3)),
        lastCheckInDate: '2026-09-11',
        streakDay: 5,
        totalEarned: 120,
        rewardedAdsWatchedToday: 3,
        lastRewardedAdDate: '2026-09-11',
        lastRewardedAdTimestamp: 1726070000000,
        hasSeenTutorial: true,
      );

      final json = original.toJson();
      final restored = RewardsState.fromJson(json);

      expect(restored.balance, original.balance);
      expect(restored.streakDay, original.streakDay);
      expect(restored.totalEarned, original.totalEarned);
      expect(restored.rewardedAdsWatchedToday, original.rewardedAdsWatchedToday);
      expect(restored.hasSeenTutorial, isTrue);
      expect(restored.isAdFreeActive, isTrue);
    });
  });
}
