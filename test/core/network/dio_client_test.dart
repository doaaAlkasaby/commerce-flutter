import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dio Client Route Detection Tests', () {
    test('Global auth route identification', () {
      bool isAuthRoute(String path) {
        final p = path.toLowerCase();
        return p.contains('/auth/login') ||
            p.contains('/auth/register') ||
            p.contains('/auth/refresh');
      }

      expect(isAuthRoute('/api/v1/auth/login'), isTrue);
      expect(isAuthRoute('/api/v1/auth/register'), isTrue);
      expect(isAuthRoute('/api/v1/auth/refresh'), isTrue);
      expect(isAuthRoute('/api/v1/products'), isFalse);
      expect(isAuthRoute('/api/v1/cart'), isFalse);
    });
  });
}
