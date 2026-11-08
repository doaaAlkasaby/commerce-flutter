import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/storefront/presentation/providers/storefront_provider.dart';

class DelayedMockAdapter implements HttpClientAdapter {
  final Completer<ResponseBody> completer = Completer<ResponseBody>();
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return completer.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Real In-Flight Tenant Isolation Tests', () {
    test('Tenant A pending response is discarded when active tenant switches to Tenant B', () async {
      final delayedAdapter = DelayedMockAdapter();
      final container = ProviderContainer();

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = delayedAdapter;

      expect(container.read(selectedTenantSlugProvider), 'dev81-kuwait-fashion');

      final storefrontFuture = container.read(storefrontProvider.future);

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

      delayedAdapter.completer.complete(
        ResponseBody.fromString(
          tenantAPayload,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      expect(storefrontFuture, throwsA(isA<StateError>()));

      final tenantState = container.read(tenantProvider);
      expect(tenantState.tenantSlug, 'dev81-independent');
      expect(tenantState.appName, isNot('Dev81 Kuwait Fashion Store'));

      container.dispose();
    });
  });
}
