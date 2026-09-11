import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poltro_play/core/services/storage_service.dart';

class RewardsState {
  final int balance;
  final DateTime? adFreeUntil;
  final String? lastCheckInDate;
  final int streakDay; // 1 a 7
  final int totalEarned;
  final int rewardedAdsWatchedToday;
  final String? lastRewardedAdDate;
  final int? lastRewardedAdTimestamp;
  final bool hasSeenTutorial;
  final int tick; // Incrementado a cada segundo para atualizar contadores ao vivo

  static const List<int> streakRewards = [5, 6, 7, 8, 10, 12, 15];
  static const int maxDailyRewardedAds = 8;
  static const int cooldownSeconds = 45;

  const RewardsState({
    this.balance = 10, // Bônus de boas-vindas
    this.adFreeUntil,
    this.lastCheckInDate,
    this.streakDay = 1,
    this.totalEarned = 10,
    this.rewardedAdsWatchedToday = 0,
    this.lastRewardedAdDate,
    this.lastRewardedAdTimestamp,
    this.hasSeenTutorial = false,
    this.tick = 0,
  });

  bool get isAdFreeActive {
    if (adFreeUntil == null) return false;
    return adFreeUntil!.isAfter(DateTime.now());
  }

  Duration get remainingAdFreeTime {
    if (!isAdFreeActive) return Duration.zero;
    return adFreeUntil!.difference(DateTime.now());
  }

  static String formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Verifica se o bônus diário está disponível para coleta hoje
  bool get canClaimDailyBonus {
    final today = formatDate(DateTime.now());
    return lastCheckInDate != today;
  }

  /// Calcula o dia da sequência (1 a 7) que o usuário irá coletar
  int get currentEligibleStreakDay {
    if (lastCheckInDate == null) return 1;

    final today = formatDate(DateTime.now());
    if (lastCheckInDate == today) {
      // Já coletou hoje, retorna o dia que foi coletado
      return streakDay;
    }

    try {
      final lastDate = DateTime.parse(lastCheckInDate!);
      final nowDate = DateTime.now();
      final diff = DateTime(nowDate.year, nowDate.month, nowDate.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (diff == 1) {
        // Dia consecutivo: avança o streak
        return streakDay >= 7 ? 1 : streakDay + 1;
      } else {
        // Pulou um dia ou mais: reseta para o Dia 1
        return 1;
      }
    } catch (_) {
      return 1;
    }
  }

  /// Valor de pipocas que o usuário ganha no check-in de hoje
  int get todayRewardAmount {
    final day = currentEligibleStreakDay;
    if (day < 1 || day > 7) return 5;
    return streakRewards[day - 1];
  }

  /// Retorna o valor de recompensa para qualquer dia do calendário (1 a 7)
  static int getRewardForDay(int day) {
    if (day < 1) return 5;
    if (day > 7) return 15;
    return streakRewards[day - 1];
  }

  /// Quantos anúncios o usuário ainda pode assistir hoje
  int get remainingRewardedAdsToday {
    final today = formatDate(DateTime.now());
    if (lastRewardedAdDate != today) return maxDailyRewardedAds;
    return max(0, maxDailyRewardedAds - rewardedAdsWatchedToday);
  }

  /// Tempo de espera restante (cooldown) até poder assistir ao próximo anúncio
  Duration get rewardedAdCooldownRemaining {
    if (lastRewardedAdTimestamp == null) return Duration.zero;
    final lastAdTime = DateTime.fromMillisecondsSinceEpoch(lastRewardedAdTimestamp!);
    final elapsed = DateTime.now().difference(lastAdTime);
    final remaining = Duration(seconds: cooldownSeconds) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Pode assistir a mais um anúncio premiado agora?
  bool get canWatchRewardedAd {
    return remainingRewardedAdsToday > 0 && rewardedAdCooldownRemaining == Duration.zero;
  }

  RewardsState copyWith({
    int? balance,
    DateTime? adFreeUntil,
    String? lastCheckInDate,
    int? streakDay,
    int? totalEarned,
    int? rewardedAdsWatchedToday,
    String? lastRewardedAdDate,
    int? lastRewardedAdTimestamp,
    bool? hasSeenTutorial,
    int? tick,
  }) {
    return RewardsState(
      balance: balance ?? this.balance,
      adFreeUntil: adFreeUntil ?? this.adFreeUntil,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      streakDay: streakDay ?? this.streakDay,
      totalEarned: totalEarned ?? this.totalEarned,
      rewardedAdsWatchedToday: rewardedAdsWatchedToday ?? this.rewardedAdsWatchedToday,
      lastRewardedAdDate: lastRewardedAdDate ?? this.lastRewardedAdDate,
      lastRewardedAdTimestamp: lastRewardedAdTimestamp ?? this.lastRewardedAdTimestamp,
      hasSeenTutorial: hasSeenTutorial ?? this.hasSeenTutorial,
      tick: tick ?? this.tick,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'adFreeUntil': adFreeUntil?.millisecondsSinceEpoch,
      'lastCheckInDate': lastCheckInDate,
      'streakDay': streakDay,
      'totalEarned': totalEarned,
      'rewardedAdsWatchedToday': rewardedAdsWatchedToday,
      'lastRewardedAdDate': lastRewardedAdDate,
      'lastRewardedAdTimestamp': lastRewardedAdTimestamp,
      'hasSeenTutorial': hasSeenTutorial,
    };
  }

  factory RewardsState.fromJson(Map<String, dynamic> json) {
    DateTime? until;
    if (json['adFreeUntil'] is int && (json['adFreeUntil'] as int) > 0) {
      until = DateTime.fromMillisecondsSinceEpoch(json['adFreeUntil'] as int);
    }
    return RewardsState(
      balance: json['balance'] as int? ?? 10,
      adFreeUntil: until,
      lastCheckInDate: json['lastCheckInDate'] as String?,
      streakDay: json['streakDay'] as int? ?? 1,
      totalEarned: json['totalEarned'] as int? ?? 10,
      rewardedAdsWatchedToday: json['rewardedAdsWatchedToday'] as int? ?? 0,
      lastRewardedAdDate: json['lastRewardedAdDate'] as String?,
      lastRewardedAdTimestamp: json['lastRewardedAdTimestamp'] as int?,
      hasSeenTutorial: json['hasSeenTutorial'] as bool? ?? false,
    );
  }
}

class RewardsService extends ChangeNotifier {
  static final RewardsService _instance = RewardsService._internal();
  factory RewardsService() => _instance;
  RewardsService._internal();

  static const String _keyBalance = 'pipocas_balance';
  static const String _keyAdFreeUntil = 'pipocas_ad_free_until';
  static const String _keyLastCheckIn = 'pipocas_last_checkin';
  static const String _keyStreakDay = 'pipocas_streak_day';
  static const String _keyTotalEarned = 'pipocas_total_earned';
  static const String _keyRewardedAdsCount = 'pipocas_rewarded_ads_count';
  static const String _keyRewardedAdsDate = 'pipocas_rewarded_ads_date';
  static const String _keyRewardedAdsTimestamp = 'pipocas_rewarded_ads_ts';
  static const String _keyHasSeenTutorial = 'pipocas_has_seen_tutorial';

  final StorageService _storage = StorageService();
  RewardsState _state = const RewardsState();
  Timer? _countdownTimer;
  StreamSubscription<User?>? _authSubscription;

  RewardsState get state => _state;
  int get balance => _state.balance;
  bool get isAdFreeActive => _state.isAdFreeActive;
  Duration get remainingAdFreeTime => _state.remainingAdFreeTime;
  bool get canClaimDailyBonus => _state.canClaimDailyBonus;
  int get currentStreakDay => _state.currentEligibleStreakDay;
  bool get hasSeenTutorial => _state.hasSeenTutorial;

  void init() {
    final rawBalance = _storage.getUserPref(_keyBalance);
    final rawUntil = _storage.getUserPref(_keyAdFreeUntil);
    final rawLastCheckin = _storage.getUserPref(_keyLastCheckIn);
    final rawStreak = _storage.getUserPref(_keyStreakDay);
    final rawTotal = _storage.getUserPref(_keyTotalEarned);
    final rawAdsCount = _storage.getUserPref(_keyRewardedAdsCount);
    final rawAdsDate = _storage.getUserPref(_keyRewardedAdsDate);
    final rawAdsTs = _storage.getUserPref(_keyRewardedAdsTimestamp);
    final rawHasSeenTut = _storage.getUserPref(_keyHasSeenTutorial);

    DateTime? untilDate;
    if (rawUntil is int && rawUntil > 0) {
      untilDate = DateTime.fromMillisecondsSinceEpoch(rawUntil);
    }

    _state = RewardsState(
      balance: (rawBalance is int) ? rawBalance : 10,
      adFreeUntil: untilDate,
      lastCheckInDate: rawLastCheckin as String?,
      streakDay: (rawStreak is int && rawStreak >= 1 && rawStreak <= 7) ? rawStreak : 1,
      totalEarned: (rawTotal is int) ? rawTotal : 10,
      rewardedAdsWatchedToday: (rawAdsCount is int) ? rawAdsCount : 0,
      lastRewardedAdDate: rawAdsDate as String?,
      lastRewardedAdTimestamp: rawAdsTs as int?,
      hasSeenTutorial: (rawHasSeenTut is bool) ? rawHasSeenTut : false,
    );

    _startTimerIfNeeded();
    notifyListeners();

    // Sincroniza com o Firestore na inicialização ou login
    syncWithFirestore();
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        syncWithFirestore();
      }
    });
  }

  /// Sincroniza dados com a nuvem (Firestore)
  Future<void> syncWithFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final cloudPipocas = data['pipocas'] as int? ?? 0;
          final cloudUntilMs = data['adFreeUntil'] as int? ?? 0;
          final cloudTotal = data['pipocasTotalEarned'] as int? ?? 0;
          final cloudLastCheckin = data['pipocasLastCheckin'] as String?;
          final cloudStreak = data['pipocasStreakDay'] as int? ?? 1;
          final cloudHasSeenTut = data['hasSeenRewardsTutorial'] as bool? ?? false;

          final mergedBalance = max(_state.balance, cloudPipocas);
          final mergedTotal = max(_state.totalEarned, cloudTotal);

          DateTime? mergedUntil = _state.adFreeUntil;
          if (cloudUntilMs > 0) {
            final cloudUntilDate = DateTime.fromMillisecondsSinceEpoch(cloudUntilMs);
            if (mergedUntil == null || cloudUntilDate.isAfter(mergedUntil)) {
              mergedUntil = cloudUntilDate;
            }
          }

          _state = _state.copyWith(
            balance: mergedBalance,
            totalEarned: mergedTotal,
            adFreeUntil: mergedUntil,
            lastCheckInDate: cloudLastCheckin ?? _state.lastCheckInDate,
            streakDay: (cloudStreak >= 1 && cloudStreak <= 7) ? cloudStreak : _state.streakDay,
            hasSeenTutorial: cloudHasSeenTut || _state.hasSeenTutorial,
            tick: _state.tick + 1,
          );

          // Salva localmente
          _storage.saveUserPref(_keyBalance, mergedBalance);
          _storage.saveUserPref(_keyTotalEarned, mergedTotal);
          _storage.saveUserPref(_keyHasSeenTutorial, _state.hasSeenTutorial);
          if (mergedUntil != null) {
            _storage.saveUserPref(_keyAdFreeUntil, mergedUntil.millisecondsSinceEpoch);
          }

          _saveToFirestore();
          _startTimerIfNeeded();
          notifyListeners();
        }
      } else {
        _saveToFirestore();
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao sincronizar pipocas com Firestore: $e');
    }
  }

  void _saveToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'pipocas': _state.balance,
      'pipocasTotalEarned': _state.totalEarned,
      'adFreeUntil': _state.adFreeUntil?.millisecondsSinceEpoch ?? 0,
      'pipocasLastCheckin': _state.lastCheckInDate ?? '',
      'pipocasStreakDay': _state.streakDay,
      'hasSeenRewardsTutorial': _state.hasSeenTutorial,
      'lastRewardsUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) {
      if (kDebugMode) print('Erro ao salvar pipocas na nuvem: $e');
    });
  }

  void _startTimerIfNeeded() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Sempre atualiza o tick se houver contagem VIP ou cooldown ativo
      if (_state.isAdFreeActive || _state.rewardedAdCooldownRemaining > Duration.zero) {
        _state = _state.copyWith(tick: _state.tick + 1);
        notifyListeners();
      }
    });
  }

  /// Adiciona Pipocas ao saldo quando o usuário assiste a um anúncio premiado
  void addPipocasFromAd(int amount) {
    if (amount <= 0) return;

    final today = RewardsState.formatDate(DateTime.now());
    final currentCount = (_state.lastRewardedAdDate == today) ? _state.rewardedAdsWatchedToday : 0;
    final newCount = currentCount + 1;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final newBalance = _state.balance + amount;
    final newTotal = _state.totalEarned + amount;

    _state = _state.copyWith(
      balance: newBalance,
      totalEarned: newTotal,
      rewardedAdsWatchedToday: newCount,
      lastRewardedAdDate: today,
      lastRewardedAdTimestamp: nowMs,
      tick: _state.tick + 1,
    );

    _storage.saveUserPref(_keyBalance, newBalance);
    _storage.saveUserPref(_keyTotalEarned, newTotal);
    _storage.saveUserPref(_keyRewardedAdsCount, newCount);
    _storage.saveUserPref(_keyRewardedAdsDate, today);
    _storage.saveUserPref(_keyRewardedAdsTimestamp, nowMs);

    _saveToFirestore();
    _startTimerIfNeeded();
    notifyListeners();
  }

  /// Resgata o bônus diário na sequência do calendário (Dia 1 ao 7)
  int claimDailyBonus() {
    if (!_state.canClaimDailyBonus) return 0;

    final today = RewardsState.formatDate(DateTime.now());
    final eligibleDay = _state.currentEligibleStreakDay;
    final rewardAmount = RewardsState.getRewardForDay(eligibleDay);

    final newBalance = _state.balance + rewardAmount;
    final newTotal = _state.totalEarned + rewardAmount;

    _state = _state.copyWith(
      balance: newBalance,
      totalEarned: newTotal,
      lastCheckInDate: today,
      streakDay: eligibleDay,
      tick: _state.tick + 1,
    );

    _storage.saveUserPref(_keyBalance, newBalance);
    _storage.saveUserPref(_keyTotalEarned, newTotal);
    _storage.saveUserPref(_keyLastCheckIn, today);
    _storage.saveUserPref(_keyStreakDay, eligibleDay);

    _saveToFirestore();
    notifyListeners();
    return rewardAmount;
  }

  /// Marca que o usuário já viu o tutorial guiado inicial
  void markTutorialAsSeen() {
    _state = _state.copyWith(hasSeenTutorial: true, tick: _state.tick + 1);
    _storage.saveUserPref(_keyHasSeenTutorial, true);
    _saveToFirestore();
    notifyListeners();
  }

  /// Ativa o passe de tempo sem anúncios (ex: 1h por 15 pipocas ou 3h por 25 pipocas)
  bool activateAdFreePass(int hours, int costPipocas) {
    if (_state.balance < costPipocas) return false;

    final newBalance = _state.balance - costPipocas;
    final now = DateTime.now();
    DateTime newUntil;

    // Se já tinha tempo ativo, adiciona as novas horas
    if (_state.isAdFreeActive && _state.adFreeUntil != null) {
      newUntil = _state.adFreeUntil!.add(Duration(hours: hours));
    } else {
      newUntil = now.add(Duration(hours: hours));
    }

    _state = _state.copyWith(
      balance: newBalance,
      adFreeUntil: newUntil,
      tick: _state.tick + 1,
    );

    _storage.saveUserPref(_keyBalance, newBalance);
    _storage.saveUserPref(_keyAdFreeUntil, newUntil.millisecondsSinceEpoch);
    _saveToFirestore();

    _startTimerIfNeeded();
    notifyListeners();
    return true;
  }

  /// Consome 10 pipocas para liberar 1 sessão sem anúncios (concede 2 horas)
  bool usePipocasForMovie() {
    if (_state.balance < 10) return false;
    return activateAdFreePass(2, 10);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
