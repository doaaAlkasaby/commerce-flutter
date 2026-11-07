import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String name = 'APP_LOG', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void apiLog({
    required String method,
    required String url,
    Object? queryParameters,
    Object? data,
    int? statusCode,
    Object? responseData,
    Object? error,
  }) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln('--------------------------------------------------');
      buffer.writeln('🌐 API [$method] -> $url');
      if (queryParameters != null) {
        buffer.writeln('📥 Query: ${jsonEncode(queryParameters)}');
      }
      if (data != null) {
        buffer.writeln('📦 Body: "${jsonEncode(data)}');
      }
      if (statusCode != null) {
        buffer.writeln('✅ Status: $statusCode');
      }
      if (responseData != null) {
        buffer.writeln('📤 Response: ${jsonEncode(responseData)}');
      }
      if (error != null) {
        buffer.writeln('❌ Error: $url\n$error');
      }
      buffer.writeln('--------------------------------------------------');
      developer.log(buffer.toString(), name: 'API_LOGGER');
    }
  }
}
