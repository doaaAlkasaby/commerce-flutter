import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/cart/data/cart_repository.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/cart/presentation/screens/cart_screen.dart';
import 'package:ecommerce/main.dart';

class MockCartHttpAdapter implements HttpClientAdapter {
  bool shouldFail = false;
  bool insufficientInventory = false;
  int cartCallCount = 0;
  List<Map<String, dynamic>> itemsList = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    cartCallCount++;
    final path = options.path;

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Internal Server Error'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (insufficientInventory) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Only 2 item(s) are available', 'code': 'INSUFFICIENT_INVENTORY'}),
        409,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && path.contains('cart/items')) {
      final body = options.data as Map<String, dynamic>;
      final variantId = body['variantId']?.toString() ?? '';
      final qty = (body['quantity'] as num?)?.toInt() ?? 1;

      itemsList.add({
        'id': 'item-1',
        'variantId': variantId,
        'quantity': qty,
        'unitPrice': '25.00',
        'finalUnitPrice': '25.00',
        'totalPrice': '${25.00 * qty}',
        'variant': {
          'id': variantId,
          'sku': 'SKU-TEST',
          'price': '25.00',
          'isActive': true,
          'images': [
            {'url': '/uploads/test-shoe.png'}
          ],
          'product': {
            'id': 'p-1',
            'name': 'Test Shoe',
            'slug': 'test-shoe',
            'basePrice': '25.00',
            'status': 'ACTIVE',
          }
        }
      });
    } else if (options.method == 'DELETE' && path == '/cart') {
      itemsList.clear();
    } else if (options.method == 'DELETE' && path.contains('cart/items/')) {
      itemsList.clear();
    }

    final subtotal = itemsList.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item['totalPrice']?.toString() ?? '0') ?? 0.0),
    );

    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': 'cart-1',
          'userId': 'user-1',
          'items': itemsList,
          'itemCount': itemsList.length,
          'subtotal': subtotal.toStringAsFixed(2),
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

  group('Task 04.1 — Cart Unit & Integration Tests', () {
    test('1. GET empty cart returns CartModel with empty items', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockCartHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = CartRepository(dio);
      final cart = await repo.getCart();

      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, '0.00');
    });

    test('2. GET cart rethrows DioException on HTTP 500 error', () async {
      final mockAdapter = MockCartHttpAdapter()..shouldFail = true;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = CartRepository(dio);

      expect(() async => await repo.getCart(), throwsA(isA<DioException>()));
    });

    test('3. Add item with valid variantId updates cart and subtotal', () async {
      final mockAdapter = MockCartHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = CartRepository(dio);
      final updatedCart = await repo.addToCart('3fa85f64-5717-4562-b3fc-2c963f66afa6', 2);

      expect(updatedCart.items.length, 1);
      expect(updatedCart.items.first.variantId, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(updatedCart.items.first.quantity, 2);
    });

    test('4. Clear cart sends DELETE /cart and returns empty cart', () async {
      final mockAdapter = MockCartHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = CartRepository(dio);
      await repo.addToCart('3fa85f64-5717-4562-b3fc-2c963f66afa6', 1);

      final clearedCart = await repo.clearCart();
      expect(clearedCart.items, isEmpty);
      expect(clearedCart.itemCount, 0);
    });

    test('5. Unauthenticated user does not dispatch Cart API requests', () async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockCartHttpAdapter();
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

      // Read cartProvider as unauthenticated user
      final cartValue = await container.read(cartProvider.future);
      expect(cartValue.items, isEmpty);
      expect(mockAdapter.cartCallCount, 0);

      container.dispose();
    });

    test('6. Relative cart image URL resolves against server origin', () {
      final imageModel = CartImageModel.fromJson({'url': '/uploads/test-shoe.png'});
      expect(imageModel.url.startsWith('http://'), isTrue);
      expect(imageModel.url.endsWith('/uploads/test-shoe.png'), isTrue);
    });

    testWidgets('7. Unauthenticated user in CartScreen renders Login Required prompt', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockCartHttpAdapter();

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
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Login Required'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });
  });
}
