import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/storefront/data/storefront_repository.dart';
import 'package:ecommerce/features/tenant_selection/models/public_store_model.dart';
import 'package:ecommerce/features/tenant_selection/presentation/providers/tenant_selection_provider.dart';
import 'package:ecommerce/features/tenant_selection/presentation/screens/tenant_selection_screen.dart';
import 'package:ecommerce/main.dart';

class MockDiscoveryHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  bool shouldFail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Failed to fetch public stores'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.path.contains('/storefront/tenants')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': [
            {
              'id': 'tenant-1',
              'slug': 'luma-fashion',
              'name': 'Luma | لوما',
              'logoUrl': '/uploads/logos/luma.png',
              'coverImageUrl': '/uploads/covers/luma.png',
              'currency': 'KWD',
            },
            {
              'id': 'tenant-2',
              'slug': 'noura-lifestyle',
              'name': 'Noura | نورة',
              'logoUrl': '/uploads/logos/noura.png',
              'coverImageUrl': '/uploads/covers/noura.png',
              'currency': 'SAR',
            },
          ],
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.path.contains('/storefront')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'tenant-1',
            'slug': 'luma-fashion',
            'name': 'Luma | لوما',
            'currency': 'KWD',
            'logoUrl': '/uploads/logos/luma.png',
            'timezone': 'Asia/Kuwait',
          },
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': {}}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 06.8.3 — Flutter Dynamic Store Selection Tests', () {
    test('1. PublicStoreModel parses JSON correctly', () {
      final json = {
        'id': 'bd7e436f-56dc-4442-aa97-9280eb2958c7',
        'slug': 'dar-home',
        'name': 'Dar | دار',
        'logoUrl': '/uploads/logos/dar.svg',
        'coverImageUrl': '/uploads/covers/dar.webp',
        'currency': 'AED',
      };

      final model = PublicStoreModel.fromJson(json);

      expect(model.id, 'bd7e436f-56dc-4442-aa97-9280eb2958c7');
      expect(model.slug, 'dar-home');
      expect(model.name, 'Dar | دار');
      expect(model.logoUrl, '/uploads/logos/dar.svg');
      expect(model.coverImageUrl, '/uploads/covers/dar.webp');
      expect(model.currency, 'AED');
      expect(model.currencySymbol, 'AED');
    });

    test('2. StorefrontRepository getPublicStores fetches public stores list', () async {
      final adapter = MockDiscoveryHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = adapter;

      final repo = StorefrontRepository(dio);
      final stores = await repo.getPublicStores();

      expect(stores.length, 2);
      expect(stores.first.name, 'Luma | لوما');
      expect(stores.first.coverImageUrl, '/uploads/covers/luma.png');
      expect(stores.last.name, 'Noura | نورة');
      expect(adapter.requests.last.path, contains('/storefront/tenants'));
    });

    test('3. Discovery request is unauthenticated and excludes tenant headers', () async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();

      final adapter = MockDiscoveryHttpAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
          }),
          dioClientProvider.overrideWith((ref) {
            final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
            dio.httpClientAdapter = adapter;
            return dio;
          }),
        ],
      );

      final stores = await container.read(publicStoresProvider.future);

      expect(stores.length, 2);
      final requestHeaders = adapter.requests.first.headers;
      expect(requestHeaders['X-Tenant-Slug'], isNull);
      expect(requestHeaders['Authorization'], isNull);
    });

    testWidgets('4. TenantSelectionScreen renders search field and API-driven store grid', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': false,
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final adapter = MockDiscoveryHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
            }),
            dioClientProvider.overrideWith((ref) {
              final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
              dio.httpClientAdapter = adapter;
              return dio;
            }),
          ],
          child: const MaterialApp(home: TenantSelectionScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Choose Your Store'), findsOneWidget);
      expect(find.text('Search store'), findsOneWidget);
      expect(find.text('Luma | لوما'), findsOneWidget);
      expect(find.text('Noura | نورة'), findsOneWidget);
    });

    testWidgets('5. Search field filters stores dynamically by name', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': false,
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final adapter = MockDiscoveryHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
            }),
            dioClientProvider.overrideWith((ref) {
              final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
              dio.httpClientAdapter = adapter;
              return dio;
            }),
          ],
          child: const MaterialApp(home: TenantSelectionScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'Noura');
      await tester.pumpAndSettle();

      expect(find.text('Noura | نورة'), findsOneWidget);
      expect(find.text('Luma | لوما'), findsNothing);
    });

    testWidgets('6. Network error displays error state with Retry button', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': false,
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final adapter = MockDiscoveryHttpAdapter()..shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
            }),
            dioClientProvider.overrideWith((ref) {
              final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
              dio.httpClientAdapter = adapter;
              return dio;
            }),
          ],
          child: const MaterialApp(home: TenantSelectionScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load public stores'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
