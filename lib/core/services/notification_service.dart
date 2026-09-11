import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poltro_play/core/router/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static String? pendingRoute;
  static Map<String, dynamic>? pendingExtra;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await requestPermission();
    await _setupLocalNotifications();
    _configureFirebaseMessaging();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Permissão em tempo de execução para Android 13+ (Tiramisu / API 33+)
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) print('Erro ao solicitar permissao Android 13+: $e');
    }
    
    if (kDebugMode) {
      print('User granted notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _configureFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });

    // Trata caso o app seja aberto pela notificação com o app fechado (Terminated)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message.data, isInitial: true);
      }
    });
  }

  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final response = await Dio().download(url, filePath);
      if (response.statusCode == 200) {
        return filePath;
      }
    } catch (e) {
      if (kDebugMode) print('Error downloading image for notification: $e');
    }
    return null;
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    final String? title = message.notification?.title ?? message.data['title'];
    final String? body = message.notification?.body ?? message.data['body'];
    
    if (title == null && body == null) return;

    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await localNotifications.initialize(settings: initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final String? imageUrl = message.data['imageUrl'] ?? message.notification?.android?.imageUrl;
    BigPictureStyleInformation? bigPictureStyleInformation;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/notif_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final response = await Dio().download(imageUrl, filePath);
        if (response.statusCode == 200) {
          bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(filePath),
            largeIcon: FilePathAndroidBitmap(filePath),
            hideExpandedLargeIcon: true,
            contentTitle: title,
            summaryText: body,
          );
        }
      } catch (_) {}
    }

    await localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          styleInformation: bigPictureStyleInformation,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final String? title = message.notification?.title ?? message.data['title'];
    final String? body = message.notification?.body ?? message.data['body'];
    
    if (title == null && body == null) return;

    final String? imageUrl = message.data['imageUrl'] ?? message.notification?.android?.imageUrl;
    BigPictureStyleInformation? bigPictureStyleInformation;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final String? downloadedPath = await _downloadAndSaveFile(imageUrl, 'notif_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (downloadedPath != null) {
        bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(downloadedPath),
          largeIcon: FilePathAndroidBitmap(downloadedPath),
          hideExpandedLargeIcon: true,
          contentTitle: title,
          summaryText: body,
        );
      }
    }

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          styleInformation: bigPictureStyleInformation,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationClick(data);
      } catch (e) {
        if (kDebugMode) print('Erro ao decodificar payload: $e');
      }
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data, {bool isInitial = false}) {
    if (kDebugMode) {
      print('Notification clicked with data: $data');
    }
    
    if (data.containsKey('contentId') && data.containsKey('contentType')) {
      final contentId = data['contentId'].toString();
      final contentType = data['contentType'].toString(); // "movie" ou "tv"
      
      final route = '/detail/$contentId';
      final extra = {'type': contentType};

      if (isInitial) {
        pendingRoute = route;
        pendingExtra = extra;
      } else {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          context.push(route, extra: extra);
        }
      }
    } else if (data.containsKey('url')) {
       // Suporte futuro para URL externas
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    if (kDebugMode) {
      print('Subscribed to topic: $topic');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('Unsubscribed from topic: $topic');
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
