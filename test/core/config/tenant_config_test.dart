import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/config/tenant_config.dart';

void main() {
  group('TenantConfig Tests', () {
    test('defaultTenant initializes with valid slug and empty currency default', () {
      final config = TenantConfig.defaultTenant('dev81-kuwait-fashion');
      expect(config.tenantSlug, 'dev81-kuwait-fashion');
      expect(config.tenantId, isNull);
      expect(config.currencySymbol, '');
    });

    test('copyWith updates specified fields', () {
      final config = TenantConfig.defaultTenant('dev81-kuwait-fashion');
      final updated = config.copyWith(
        appName: 'New Store Name',
        currencySymbol: 'SAR',
      );
      expect(updated.tenantSlug, 'dev81-kuwait-fashion');
      expect(updated.appName, 'New Store Name');
      expect(updated.currencySymbol, 'SAR');
    });
  });
}
