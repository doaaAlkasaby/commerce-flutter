import 'dart:io';
import 'package:flutter/foundation.dart';

enum EnvironmentType { dev, staging, prod }

class AppEnvironment {
  static const String envRaw = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  static const String customApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String defaultTenantSlug = String.fromEnvironment(
    'DEFAULT_TENANT_SLUG',
    defaultValue: 'dev81-kuwait-fashion',
  );

  static EnvironmentType get currentEnvironment {
    switch (envRaw.toLowerCase()) {
      case 'prod':
      case 'production':
        return EnvironmentType.prod;
      case 'staging':
        return EnvironmentType.staging;
      case 'dev':
      default:
        return EnvironmentType.dev;
    }
  }

  static String get baseUrl {
    if (customApiBaseUrl.isNotEmpty) {
      return normalizeAndValidateUrl(customApiBaseUrl);
    }

    if (currentEnvironment == EnvironmentType.prod) {
      throw StateError(
        'API_BASE_URL must be configured for production build via --dart-define=API_BASE_URL=...',
      );
    }

    if (currentEnvironment == EnvironmentType.staging) {
      throw StateError(
        'API_BASE_URL must be configured for staging build via --dart-define=API_BASE_URL=...',
      );
    }

    // Dev environment defaults
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }

    return 'http://127.0.0.1:3000/api/v1';
  }

  static String normalizeAndValidateUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('URL cannot be empty');
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        'Invalid URL or unsupported scheme. Must start with http:// or https://',
      );
    }

    if (!uri.hasAuthority || uri.host.isEmpty) {
      throw const FormatException('URL must include a valid host');
    }

    if (uri.userInfo.isNotEmpty) {
      throw const FormatException('Embedded user credentials in URL are prohibited');
    }

    if (uri.hasQuery) {
      throw const FormatException('API Base URL must not include query parameters');
    }

    if (uri.hasFragment) {
      throw const FormatException('API Base URL must not include fragments');
    }

    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/api/v1')) {
      trimmed = '$trimmed/api/v1';
    }
    return trimmed;
  }
}
