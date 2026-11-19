import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLoggingInterceptor extends Interceptor {
  static int _requestCounter = 0;

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
    'otp',
    'apikey',
  };

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

  static String _formatJson(dynamic data) {
    if (data == null) return '';
    try {
      final sanitized = sanitizeData(data);
      if (sanitized is Map || sanitized is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(sanitized);
      }
      return sanitized.toString();
    } catch (_) {
      return data.toString();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final requestId = ++_requestCounter;
      options.extra['requestId'] = requestId;
      options.extra['requestStartTime'] = DateTime.now().millisecondsSinceEpoch;

      final fullUrl = StringBuffer('${options.baseUrl}${options.path}');
      if (options.queryParameters.isNotEmpty) {
        final queryStr = options.queryParameters.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        fullUrl.write('?$queryStr');
      }

      final buf = StringBuffer()
        ..writeln('========== API REQUEST [$requestId] ==========')
        ..writeln('${options.method} $fullUrl');

      if (options.data != null && options.data is! FormData) {
        final formattedBody = _formatJson(options.data);
        if (formattedBody.isNotEmpty) {
          buf.writeln('Body:\n$formattedBody');
        }
      }

      developer.log(buf.toString().trimRight(), name: 'API_LOGGER');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final requestId = response.requestOptions.extra['requestId'] ?? 0;
      final startTime =
          response.requestOptions.extra['requestStartTime'] as int?;
      final duration = startTime != null
          ? DateTime.now().millisecondsSinceEpoch - startTime
          : null;
      final durationStr = duration != null ? '$duration ms' : 'unknown';

      final buf = StringBuffer()
        ..writeln('========== API RESPONSE [$requestId] ==========')
        ..writeln('Status: ${response.statusCode}')
        ..writeln('Duration: $durationStr');

      if (response.data != null) {
        final formattedBody = _formatJson(response.data);
        if (formattedBody.isNotEmpty) {
          buf.writeln('Body:\n$formattedBody');
        }
      }
      buf.writeln('=======================================');

      developer.log(buf.toString().trimRight(), name: 'API_LOGGER');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final requestId = err.requestOptions.extra['requestId'] ?? 0;
      final startTime = err.requestOptions.extra['requestStartTime'] as int?;
      final duration = startTime != null
          ? DateTime.now().millisecondsSinceEpoch - startTime
          : null;
      final durationStr = duration != null ? '$duration ms' : 'unknown';

      final buf = StringBuffer()
        ..writeln('========== API ERROR [$requestId] ==========')
        ..writeln('Status: ${err.response?.statusCode ?? 'Network Error'}')
        ..writeln('Duration: $durationStr')
        ..writeln('Error: ${err.message}');

      if (err.response?.data != null) {
        final formattedBody = _formatJson(err.response?.data);
        if (formattedBody.isNotEmpty) {
          buf.writeln('Body:\n$formattedBody');
        }
      }
      buf.writeln('=======================================');

      developer.log(buf.toString().trimRight(), name: 'API_LOGGER');
    }
    handler.next(err);
  }
}
