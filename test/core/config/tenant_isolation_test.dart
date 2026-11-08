import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/features/storefront/presentation/providers/storefront_provider.dart';

class ControlledMockAdapter implements HttpClientAdapter {
  final Map<String, Completer<ResponseBody>> _completers = {};

  Completer<ResponseBody> getCompleterForSlug(String slug) {
    _completers[slug] ??= Completer<ResponseBody>();
    return _completers[slug]!;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final slug = options.headers['X-Tenant-Slug']?.toString() ?? 'default';
    _completers[slug] ??= Completer<ResponseBody>();
    return _completers[slug]!.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Real In-Flight Tenant Isolation Tests', () {
    test('Tenant A pending response is discarded when active tenant switches to Tenant B and Tenant B loads its own data', () async {
      final mockAdapter = ControlledMockAdapter();

      final container = ProviderContainer(
        overrides: [
          dioClientProvider.overrideWith((ref) {
            final tenantSlug = ref.watch(selectedTenantSlugProvider);
            final dio = Dio(BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              headers: {'X-Tenant-Slug': tenantSlug},
            ));
            dio.httpClientAdapter = mockAdapter;
            return dio;
          }),
        ],
      );

      // Listen to storefrontProvider to keep it active across tenant switches
      container.listen(storefrontProvider, (previous, next) {});

      expect(container.read(selectedTenantSlugProvider), 'dev81-kuwait-fashion');

      // Switch active tenant to Tenant B BEFORE Tenant A responds
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');
      expect(container.read(selectedTenantSlugProvider), 'dev81-independent');

      final tenantAPayload = jsonEncode({
        'success': true,
        'data': {
          'id': 'dev81-kuwait-fashion',
          'slug': 'dev81-kuwait-fashion',
          'name': 'Dev81 Kuwait Fashion Store',
          'currency': 'KWD',
        }
      });

      final tenantBPayload = jsonEncode({
        'success': true,
        'data': {
          'id': 'dev81-independent',
          'slug': 'dev81-independent',
          'name': 'Dev81 Independent Store',
          'currency': 'SAR',
        }
      });

      // Complete Tenant A request (which is discarded internally by storefrontProvider guard)
      mockAdapter.getCompleterForSlug('dev81-kuwait-fashion').complete(
        ResponseBody.fromString(
          tenantAPayload,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      // Complete Tenant B request
      mockAdapter.getCompleterForSlug('dev81-independent').complete(
        ResponseBody.fromString(
          tenantBPayload,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      final tenantBModel = await container.read(storefrontProvider.future);

      // Assert Tenant B receives its own valid data and provider state is cleanly isolated
      expect(tenantBModel.slug, 'dev81-independent');
      expect(tenantBModel.name, 'Dev81 Independent Store');
      expect(tenantBModel.currency, 'SAR');

      final tenantState = container.read(tenantProvider);
      expect(tenantState.tenantSlug, 'dev81-independent');
      expect(tenantState.appName, 'Dev81 Independent Store');
      expect(tenantState.currencySymbol, 'SAR');

      container.dispose();
    });
  });
}
