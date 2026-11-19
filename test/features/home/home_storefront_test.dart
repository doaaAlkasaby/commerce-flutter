import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/storefront/presentation/providers/storefront_provider.dart';
import 'package:ecommerce/main.dart';

class HomeStorefrontMockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final slug = options.headers['X-Tenant-Slug']?.toString() ?? 'dev81-kuwait-fashion';

    if (slug == 'dev81-kuwait-fashion') {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'dev81-kuwait-fashion',
            'slug': 'dev81-kuwait-fashion',
            'name': 'Kuwait Fashion Store',
            'currency': 'KWD',
            'logoUrl': 'https://example.com/kuwait.png',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    } else {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'dev81-independent',
            'slug': 'dev81-independent',
            'name': 'Independent SAR Store',
            'currency': 'SAR',
            'logoUrl': 'https://example.com/sar.png',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tenant-Aware Home & Storefront Integration Tests', () {
    test('storefrontProvider updates tenantProvider with store name, logo, and currency', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = HomeStorefrontMockAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
          }),
          dioClientProvider.overrideWith((ref) {
            final tenantSlug = ref.watch(selectedTenantSlugProvider);
            final dio = Dio(BaseOptions(
              baseUrl: 'http://127.0.0.1:3000/api/v1',
              headers: {'X-Tenant-Slug': tenantSlug},
            ));
            dio.httpClientAdapter = mockAdapter;
            return dio;
          }),
        ],
      );

      final model = await container.read(storefrontProvider.future);
      expect(model.name, 'Kuwait Fashion Store');
      expect(model.currency, 'KWD');

      final tenantState = container.read(tenantProvider);
      expect(tenantState.appName, 'Kuwait Fashion Store');
      expect(tenantState.currencySymbol, 'KWD');
      expect(tenantState.logoUrl, 'https://example.com/kuwait.png');

      container.dispose();
    });

    test('Switching tenant updates tenantProvider and store branding dynamically', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = HomeStorefrontMockAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
          }),
          dioClientProvider.overrideWith((ref) {
            final tenantSlug = ref.watch(selectedTenantSlugProvider);
            final dio = Dio(BaseOptions(
              baseUrl: 'http://127.0.0.1:3000/api/v1',
              headers: {'X-Tenant-Slug': tenantSlug},
            ));
            dio.httpClientAdapter = mockAdapter;
            return dio;
          }),
        ],
      );

      // 1. Initial Kuwait tenant
      await container.read(storefrontProvider.future);
      expect(container.read(tenantProvider).currencySymbol, 'KWD');

      // 2. Switch to Saudi Independent tenant
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');

      final newModel = await container.read(storefrontProvider.future);
      expect(newModel.name, 'Independent SAR Store');
      expect(newModel.currency, 'SAR');

      final newTenantState = container.read(tenantProvider);
      expect(newTenantState.appName, 'Independent SAR Store');
      expect(newTenantState.currencySymbol, 'SAR');
      expect(newTenantState.logoUrl, 'https://example.com/sar.png');

      container.dispose();
    });
  });
}
