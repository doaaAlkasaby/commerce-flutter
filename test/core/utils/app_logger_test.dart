import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/utils/app_logger.dart';

void main() {
  group('AppLogger Metadata-Only & Sanitization Tests', () {
    test('sanitizeUrlPath extracts path and excludes query parameters or tokens', () {
      expect(
        AppLogger.sanitizeUrlPath('https://api.example.com/api/v1/products?token=secret123'),
        '/api/v1/products',
      );
    });

    test('sanitizeData redacts sensitive keys recursively', () {
      final input = {
        'email': 'user@example.com',
        'password': 'secretPassword123',
        'token': 'bearer_token_xyz',
        'refreshToken': 'refresh_123',
      };

      final sanitized = AppLogger.sanitizeData(input) as Map<String, dynamic>;

      expect(sanitized['email'], 'user@example.com');
      expect(sanitized['password'], '***REDACTED***');
      expect(sanitized['token'], '***REDACTED***');
      expect(sanitized['refreshToken'], '***REDACTED***');
    });
  });
}
