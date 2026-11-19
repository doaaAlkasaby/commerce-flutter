import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'app.dart';

late SharedPreferences sharedPreferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    final notifService = AppNotificationService();
    await notifService.initialize();
    unawaited(notifService.requestPermissions());
    unawaited(notifService.getDeviceToken());
  } catch (e, st) {
    AppLogger.log(
      'Firebase runtime initialization error: $e',
      name: 'FCM',
      error: e,
      stackTrace: st,
    );
  }

  sharedPreferences = await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: EcommerceApp()));
}
