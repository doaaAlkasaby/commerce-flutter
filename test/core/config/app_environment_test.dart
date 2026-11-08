import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/config/app_environment.dart';

void main() {
  group('AppEnvironment Tests', () {
    test('currentEnvironment defaults to dev', () {
      expect(AppEnvironment.currentEnvironment, EnvironmentType.dev);
    });

    test('baseUrl returns standard api/v1 dev URL', () {
      final url = AppEnvironment.baseUrl;
      expect(url.endsWith('/api/v1'), isTrue);
    });

    test('normalizeAndValidateUrl normalizes valid URLs', () {
      expect(
        AppEnvironment.normalizeAndValidateUrl('http://localhost:3000'),
        'http://localhost:3000/api/v1',
      );
      expect(
        AppEnvironment.normalizeAndValidateUrl('https://api.example.com/api/v1/'),
        'https://api.example.com/api/v1',
      );
    });

    test('normalizeAndValidateUrl rejects duplicate path segments', () {
      expect(
        () => AppEnvironment.normalizeAndValidateUrl('http://localhost:3000/api/v1/api/v1'),
        throwsFormatException,
      );
    });

    test('normalizeAndValidateUrl throws FormatException for invalid URLs without interpolating raw URL', () {
      expect(
        () => AppEnvironment.normalizeAndValidateUrl('invalid-url'),
        throwsFormatException,
      );
      expect(
        () => AppEnvironment.normalizeAndValidateUrl('ftp://example.com'),
        throwsFormatException,
      );
      expect(
        () => AppEnvironment.normalizeAndValidateUrl(''),
        throwsFormatException,
      );
    });
  });
}
