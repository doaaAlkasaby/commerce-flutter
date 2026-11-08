import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static const Set<String> _sensitiveKeys = {
    'password',
    'currentpassword',
    'newpassword',
    'token',
    'accesstoken',
    'refreshtoken',
    'authorization',
    'secret',
    'cookie',
  };

  static void log(
    String message, {
    String name = 'APP_LOG',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(message, name: name, error: error, stackTrace: stackTrace);
    }
  }

  static dynamic sanitizeData(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final keyStr = key.toString();
        if (_sensitiveKeys.contains(keyStr.toLowerCase())) {
          sanitized[keyStr] = '***REDACTED***';
        } else {
          sanitized[keyStr] = sanitizeData(value);
        }
      });
      return sanitized;
    } else if (data is List) {
      return data.map((item) => sanitizeData(item)).toList();
    }
    return data;
  }

  static String sanitizeUrlPath(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '/sanitized-path';
    return uri.path;
  }

  static void apiLog({
    required String method,
    required String url,
    Object? queryParameters,
    Object? data,
    int? statusCode,
    Object? responseData,
    Object? error,
    Duration? duration,
  }) {
    if (kDebugMode) {
      final sanitizedPath = sanitizeUrlPath(url);
      final statusStr = statusCode != null ? ' Status: $statusCode' : '';
      final durationStr = duration != null ? ' Duration: ${duration.inMilliseconds}ms' : '';
      final errorStr = error != null ? ' [ERROR: Exception Occurred]' : '';

      developer.log(
        '🌐 API [$method] -> $sanitizedPath$statusStr$durationStr$errorStr',
        name: 'API_LOGGER',
      );
    }
  }
}
