import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/storefront/models/storefront_model.dart';

void main() {
  group('Storefront Contract Validation Tests', () {
    test('StorefrontModel parses valid JSON accurately', () {
      final json = {
        'id': 'dev81-independent',
        'slug': 'dev81-independent',
        'name': 'Dev81 Independent',
        'logoUrl': 'https://example.com/logo.png',
        'currency': 'SAR',
        'timezone': 'Asia/Riyadh',
        'settings': {'allowGuestCheckout': true},
      };

      final model = StorefrontModel.fromJson(json);
      expect(model.id, 'dev81-independent');
      expect(model.slug, 'dev81-independent');
      expect(model.name, 'Dev81 Independent');
      expect(model.currency, 'SAR');
      expect(model.currencySymbol, 'SAR');
      expect(model.timezone, 'Asia/Riyadh');
    });

    test('StorefrontModel throws FormatException if required fields are missing or empty', () {
      expect(
        () => StorefrontModel.fromJson({'slug': 's', 'name': 'n', 'currency': 'SAR'}),
        throwsFormatException,
      );
      expect(
        () => StorefrontModel.fromJson({'id': 'i', 'name': 'n', 'currency': 'SAR'}),
        throwsFormatException,
      );
      expect(
        () => StorefrontModel.fromJson({'id': 'i', 'slug': 's', 'currency': 'SAR'}),
        throwsFormatException,
      );
      expect(
        () => StorefrontModel.fromJson({'id': 'i', 'slug': 's', 'name': 'n'}),
        throwsFormatException,
      );
    });
  });
}
