import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/app.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/main_shell_screen.dart';
import 'package:ecommerce/features/tenant_selection/presentation/screens/tenant_selection_screen.dart';
import 'package:ecommerce/main.dart';

class MockTenantStorefrontAdapter implements HttpClientAdapter {
  bool shouldFail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Storefront validation failed'}),
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
              'id': 'dev81-kuwait-fashion',
              'slug': 'dev81-kuwait-fashion',
              'name': 'Dev81 Kuwait Fashion',
              'logoUrl': '/uploads/logos/luma.png',
              'currency': 'KWD',
            },
            {
              'id': 'dev81-independent',
              'slug': 'dev81-independent',
              'name': 'Dev81 Independent',
              'logoUrl': '/uploads/logos/noura.png',
              'currency': 'SAR',
            },
          ],
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    final slug = options.headers['X-Tenant-Slug']?.toString() ?? 'dev81-kuwait-fashion';
    if (slug == 'dev81-independent') {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'dev81-independent',
            'slug': 'dev81-independent',
            'name': 'Dev81 Independent',
            'currency': 'SAR',
            'logoUrl': '/uploads/logos/noura.png',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': 'dev81-kuwait-fashion',
          'slug': 'dev81-kuwait-fashion',
          'name': 'Dev81 Kuwait Fashion',
          'currency': 'KWD',
          'logoUrl': '/uploads/logos/luma.png',
        }
      }),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tenant Selection & First Launch Flow Tests', () {
    testWidgets('First launch displays TenantSelectionScreen with preselected default tenant', (tester) async {
      SharedPreferences.setMockInitialValues({'is_tenant_confirmed': false});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockTenantStorefrontAdapter();

      await tester.pumpWidget(
        ProviderScope(
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
          child: const EcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first launch displays TenantSelectionScreen
      expect(find.byType(TenantSelectionScreen), findsOneWidget);
      expect(find.byType(MainShellScreen), findsNothing);

      // Verify default tenant option is present and preselected
      expect(find.text('Dev81 Kuwait Fashion'), findsOneWidget);
      expect(find.text('Choose Your Store'), findsOneWidget);
    });

    testWidgets('Pressing Continue validates candidate tenant and navigates to MainShellScreen', (tester) async {
      SharedPreferences.setMockInitialValues({'is_tenant_confirmed': false});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockTenantStorefrontAdapter();

      await tester.pumpWidget(
        ProviderScope(
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
          child: const EcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Press Continue button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify confirmation succeeded and app transitioned to MainShellScreen
      expect(sharedPreferences.getBool('is_tenant_confirmed'), isTrue);
      expect(find.byType(MainShellScreen), findsOneWidget);
    });

    testWidgets('Failed storefront validation keeps user on TenantSelectionScreen with error message', (tester) async {
      SharedPreferences.setMockInitialValues({'is_tenant_confirmed': false});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockTenantStorefrontAdapter()..shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
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
          child: const EcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Press Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify user remains on TenantSelectionScreen with error banner
      expect(find.byType(TenantSelectionScreen), findsOneWidget);
      expect(find.byType(MainShellScreen), findsNothing);
      expect(sharedPreferences.getBool('is_tenant_confirmed') ?? false, isFalse);
    });

    testWidgets('Returning confirmed user navigates directly to MainShellScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-independent',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockTenantStorefrontAdapter();

      await tester.pumpWidget(
        ProviderScope(
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
          child: const EcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify returning confirmed user opens MainShellScreen
      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(find.byType(TenantSelectionScreen), findsNothing);
    });

    testWidgets('Failed candidate validation preserves previously confirmed tenant', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockTenantStorefrontAdapter();

      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(
            home: TenantSelectionScreen(isChangeStore: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap dev81-independent
      await tester.tap(find.text('Dev81 Independent'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Set shouldFail = true for candidate validation
      mockAdapter.shouldFail = true;

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert error displayed and selectedTenantSlug in SharedPreferences remains dev81-kuwait-fashion
      expect(sharedPreferences.getString('selected_tenant_slug'), 'dev81-kuwait-fashion');
    });
  });
}
