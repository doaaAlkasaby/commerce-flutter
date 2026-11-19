import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import 'package:ecommerce/main.dart';

class MockMultiTenantAdapter implements HttpClientAdapter {
  String currentSlug = 'dev81-kuwait-fashion';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('/storefront/tenants')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': [
            { 'id': 't1', 'slug': 'dev81-kuwait-fashion', 'name': 'Luma | لوما', 'currency': 'KWD', 'logoUrl': '/uploads/logos/luma.png', 'coverImageUrl': '/uploads/covers/luma.png' },
            { 'id': 't2', 'slug': 'toota-kids', 'name': 'Toota | توتة', 'currency': 'EGP', 'logoUrl': '/uploads/logos/toota.png', 'coverImageUrl': '/uploads/covers/toota.png' },
            { 'id': 't3', 'slug': 'dar-home', 'name': 'Dar | دار', 'currency': 'AED', 'logoUrl': '/uploads/logos/dar.png', 'coverImageUrl': '/uploads/covers/dar.png' },
          ],
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/storefront')) {
      final reqSlug = options.headers['X-Tenant-Slug']?.toString() ?? currentSlug;
      currentSlug = reqSlug;

      if (reqSlug == 'toota-kids') {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'id': 't2',
              'slug': 'toota-kids',
              'name': 'Toota | توتة',
              'currency': 'EGP',
              'logoUrl': '/uploads/logos/toota.png',
              'timezone': 'Africa/Cairo',
            },
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      } else if (reqSlug == 'dar-home') {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'id': 't3',
              'slug': 'dar-home',
              'name': 'Dar | دار',
              'currency': 'AED',
              'logoUrl': '/uploads/logos/dar.png',
              'timezone': 'Asia/Dubai',
            },
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 't1',
            'slug': 'dev81-kuwait-fashion',
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

    if (path.contains('/home')) {
      final reqSlug = options.headers['X-Tenant-Slug']?.toString() ?? currentSlug;
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'platform': 'mobile',
            'banners': [
              { 'id': 'b1', 'title': '$reqSlug Banner 1', 'subtitle': 'Sub 1', 'imageUrl': '/uploads/banners/b1.png', 'targetType': 'PRODUCT_LIST', 'targetId': '1' }
            ],
            'categories': [
              { 'id': 'c1', 'name': '$reqSlug Category', 'slug': 'cat-1', 'imageUrl': '/uploads/catalog/cat.png', 'hasChildren': false }
            ],
            'sections': [],
            'brands': [],
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

  group('Task 06.8.5 — Tenant Switching & Provider Invalidation Test', () {
    testWidgets('Switching Luma -> Toota -> Dar invalidates storefrontProvider and updates state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final adapter = MockMultiTenantAdapter();

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
            dio.httpClientAdapter = adapter;
            return dio;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Luma initial state
      expect(container.read(selectedTenantSlugProvider), 'dev81-kuwait-fashion');
      expect(find.byType(MainShellScreen), findsOneWidget);

      // Switch to Toota Kids
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('toota-kids');
      await tester.pumpAndSettle();

      expect(container.read(selectedTenantSlugProvider), 'toota-kids');
      expect(sharedPreferences.getString('selected_tenant_slug'), 'toota-kids');

      // Switch to Dar Home
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dar-home');
      await tester.pumpAndSettle();

      expect(container.read(selectedTenantSlugProvider), 'dar-home');
      expect(sharedPreferences.getString('selected_tenant_slug'), 'dar-home');
    });
  });
}
