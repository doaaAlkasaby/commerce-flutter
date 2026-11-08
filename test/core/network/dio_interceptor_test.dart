import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/config/tenant_config.dart';

class MockAdapter implements HttpClientAdapter {
  RequestOptions? lastRequestOptions;
  int statusCode;
  Map<String, dynamic> responseBody;

  MockAdapter({
    this.statusCode = 200,
    this.responseBody = const {'success': true},
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    final jsonString = jsonEncode(responseBody);
    return ResponseBody.fromString(
      jsonString,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Real Dio Interceptor Tests', () {
    test('Injects X-Tenant-Slug header and removes X-Tenant-Id for tenant-scoped endpoints', () async {
      final mockAdapter = MockAdapter();
      final container = ProviderContainer();

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      await dio.get('/products');

      expect(mockAdapter.lastRequestOptions, isNotNull);
      final headers = mockAdapter.lastRequestOptions!.headers;
      expect(headers['X-Tenant-Slug'], 'dev81-kuwait-fashion');
      expect(headers.containsKey('X-Tenant-Id'), isFalse);

      container.dispose();
    });

    test('Omits X-Tenant-Slug on global authentication endpoints', () async {
      final mockAdapter = MockAdapter();
      final container = ProviderContainer();

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      await dio.post('/auth/login', data: {'email': 'test@example.com', 'password': 'pass'});

      expect(mockAdapter.lastRequestOptions, isNotNull);
      final headers = mockAdapter.lastRequestOptions!.headers;
      expect(headers.containsKey('X-Tenant-Slug'), isFalse);
      expect(headers.containsKey('X-Tenant-Id'), isFalse);

      container.dispose();
    });

    test('Switching tenant updates X-Tenant-Slug on subsequent calls', () async {
      final mockAdapter = MockAdapter();
      final container = ProviderContainer();

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      await dio.get('/products');
      expect(mockAdapter.lastRequestOptions!.headers['X-Tenant-Slug'], 'dev81-kuwait-fashion');

      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');

      final dio2 = container.read(dioClientProvider);
      dio2.httpClientAdapter = mockAdapter;

      await dio2.get('/products');
      expect(mockAdapter.lastRequestOptions!.headers['X-Tenant-Slug'], 'dev81-independent');

      container.dispose();
    });
  });
}
