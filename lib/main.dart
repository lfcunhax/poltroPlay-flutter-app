import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:poltro_play/core/theme/app_theme.dart';
import 'package:poltro_play/core/router/app_router.dart';
import 'package:poltro_play/core/services/ad_service.dart';
import 'package:poltro_play/core/services/notification_service.dart';
import 'package:poltro_play/core/services/storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Evita notificação duplicada: se message.notification for não-nulo, 
  // o próprio Android já exibiu a notificação na bandeja do sistema.
  if (message.notification == null) {
    await NotificationService.showBackgroundNotification(message);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for premium dark look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Otimização de Cache: Mantém os dados locais para carregar instantaneamente 
  // e economizar banda e leituras do Firebase
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService().init();

  // Initialize AdMob (await is safe here as it doesn't show UI)
  await AdService().initialize();
  AdService().loadInterstitialAd();

  // Initialize push notifications asynchronously so it doesn't block the first frame
  Future.microtask(() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('[FCM] NotificationService initialized successfully');
      
      await notificationService.subscribeToTopic('all');
      debugPrint('[FCM] Subscribed to topic: all');
      await notificationService.subscribeToTopic('new_movies');
      debugPrint('[FCM] Subscribed to topic: new_movies');
      await notificationService.subscribeToTopic('new_episodes');
      debugPrint('[FCM] Subscribed to topic: new_episodes');
      await notificationService.subscribeToTopic('announcements');
      debugPrint('[FCM] Subscribed to topic: announcements');
      
      final token = await notificationService.getToken();
      debugPrint('[FCM] Device token: ${token?.substring(0, 30)}...');
      if (token != null) {
        await FirebaseFirestore.instance.collection('device_tokens').doc(token).set({
          'token': token,
          'platform': 'android',
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[FCM] Token saved to Firestore successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('[FCM] ERROR during notification setup: $e');
      debugPrint('[FCM] Stack: $stackTrace');
    }
  });

  runApp(
    const ProviderScope(
      child: PoltroPlayApp(),
    ),
  );
}

class PoltroPlayApp extends ConsumerWidget {
  const PoltroPlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'PoltroPlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
