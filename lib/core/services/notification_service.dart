import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class AppNotificationService {
  static final AppNotificationService _instance =
      AppNotificationService._internal();

  factory AppNotificationService() => _instance;

  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description:
            'This channel is used for important e-commerce notifications.',
        importance: Importance.high,
      );

  bool _isInitialized = false;

  Function(Map<String, dynamic> data)? onNotificationTap;

  static String? mockTokenForTesting;
  static StreamController<String>? mockTokenRefreshControllerForTesting;

  FirebaseMessaging? _fcmInstance;
  FirebaseMessaging get _fcm {
    try {
      return _fcmInstance ??= FirebaseMessaging.instance;
    } catch (_) {
      return _fcmInstance ??= FirebaseMessaging.instance;
    }
  }

  Stream<String> get onTokenRefresh {
    if (mockTokenRefreshControllerForTesting != null) {
      return mockTokenRefreshControllerForTesting!.stream;
    }
    try {
      return _fcm.onTokenRefresh;
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } catch (_) {}

    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await _localNotifs.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data =
                  jsonDecode(response.payload!) as Map<String, dynamic>;
              onNotificationTap?.call(data);
            } catch (_) {}
          }
        },
      );

      await _localNotifs
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    } catch (_) {}

    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title']?.toString();
        final body = notification?.body ?? message.data['body']?.toString();

        if (title != null && body != null) {
          _localNotifs.show(
            id: message.messageId?.hashCode ?? title.hashCode,
            title: title,
            body: body,
            payload: jsonEncode(message.data),
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel.id,
                _androidChannel.name,
                channelDescription: _androidChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onNotificationTap?.call(message.data);
      });

      _fcm
          .getInitialMessage()
          .then((RemoteMessage? message) {
            if (message != null) {
              onNotificationTap?.call(message.data);
            }
          })
          .catchError((_) => null);
    } catch (_) {}

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      AppLogger.log(
        'Error requesting notification permissions: $e',
        name: 'FCM',
      );
    }
  }

  Future<String?> getDeviceToken() async {
    if (mockTokenForTesting != null) {
      return mockTokenForTesting;
    }
    try {
      final token = await _fcm.getToken();
      if (token != null && kDebugMode) {
        AppLogger.log('FCM Token retrieved successfully', name: 'FCM');
      }
      return token;
    } catch (e) {
      AppLogger.log('Error retrieving FCM token: $e', name: 'FCM');
      return null;
    }
  }
}
