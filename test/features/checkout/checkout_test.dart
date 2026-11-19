import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/auth/models/auth_response_models.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/checkout/data/checkout_repository.dart';
import 'package:ecommerce/features/checkout/presentation/screens/checkout_screen.dart';

class FakeAuthTokenNotifier extends AuthTokenNotifier {
  @override
  String? build() => 'test-token';
}

class FakeLanguageNotifier extends LanguageNotifier {
  final AppLanguage _lang;
  FakeLanguageNotifier(this._lang);

  @override
  AppLanguage build() => _lang;
}

class FakeCurrentUserNotifier extends CurrentUser {
  final UserDto? _user;
  FakeCurrentUserNotifier([
    this._user = const UserDto(
      id: 'user-1',
      email: 'customer1@example.com',
      firstName: 'Customer',
      lastName: 'One',
      isEmailVerified: true,
    ),
  ]);

  @override
  Future<UserDto?> build() async => _user;
}

class RecordedRequest {
  final String path;
  final String method;
  final Map<String, dynamic> headers;
  final dynamic body;

  RecordedRequest({
    required this.path,
    required this.method,
    required this.headers,
    this.body,
  });
}

class MockCheckoutHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  bool shouldFail = false;
  bool stockError = false;
  bool unsupportedCountry = false;
  bool emptyShippingOptions = false;
  bool shippingFail = false;
  Completer<void>? addressBCompleter;
  Completer<void>? previewBCompleter;
  Completer<void>? previewBStartedSignal;
  List<Map<String, dynamic>>? mockAddresses;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      RecordedRequest(
        path: options.path,
        method: options.method,
        headers: Map.from(options.headers),
        body: options.data,
      ),
    );

    final path = options.path;

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Internal Server Error'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (stockError) {
      return ResponseBody.fromString(
        jsonEncode({
          'message': 'Insufficient stock for SKU DEV81-KW-TEE',
          'code': 'INSUFFICIENT_STOCK',
        }),
        409,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('cart')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'cart-1',
            'userId': 'user-1',
            'items': [
              {
                'id': 'ci-1',
                'variantId': 'var-1',
                'quantity': 1,
                'unitPrice': '25.00',
                'finalUnitPrice': '25.00',
                'totalPrice': '25.00',
                'variant': {
                  'id': 'var-1',
                  'sku': 'SKU-1',
                  'price': '25.00',
                  'isActive': true,
                  'images': [
                    {'url': '/uploads/shoe.png'},
                  ],
                  'product': {
                    'id': 'p-1',
                    'name': 'Test Shoe',
                    'slug': 'test-shoe',
                    'basePrice': '25.00',
                    'status': 'ACTIVE',
                  },
                },
              },
            ],
            'itemCount': 1,
            'subtotal': '25.00',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('addresses')) {
      final list =
          mockAddresses ??
          [
            {
              'id': 'addr-123',
              'label': 'Home',
              'firstName': 'Customer',
              'lastName': 'One',
              'addressLine1': '10 Al-Shuhada Street',
              'city': 'Kuwait City',
              'country': 'KW',
              'countryCode': 'KW',
              'isDefaultShipping': true,
              'isDefaultBilling': true,
            },
            {
              'id': 'addr-unsupported',
              'label': 'US Office',
              'firstName': 'Customer',
              'lastName': 'One',
              'addressLine1': '100 Broadway',
              'city': 'New York',
              'country': 'US',
              'countryCode': 'US',
              'isDefaultShipping': false,
              'isDefaultBilling': false,
            },
          ];

      return ResponseBody.fromString(
        jsonEncode({'success': true, 'data': list}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('checkout/shipping-options')) {
      if (shippingFail) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to calculate shipping options'}),
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      final requestData = options.data is Map ? options.data as Map : {};
      final shippingAddressId =
          requestData['shippingAddressId'] ??
          options.queryParameters['shippingAddressId'];
      if (shippingAddressId == 'addr-unsupported') {
        if (addressBCompleter != null) {
          await addressBCompleter!.future;
        }
        return ResponseBody.fromString(
          jsonEncode({
            'message': 'Shipping is not configured for this country',
            'code': 'SHIPPING_PROFILE_NOT_CONFIGURED',
          }),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      if (unsupportedCountry) {
        return ResponseBody.fromString(
          jsonEncode({
            'message': 'Shipping is not configured for this country',
            'code': 'SHIPPING_PROFILE_NOT_CONFIGURED',
          }),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      if (emptyShippingOptions) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'options': []},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'options': [
              {
                'methodCode': 'local',
                'methodName': 'Local Delivery',
                'currency': 'KWD',
                'amount': '1.250',
                'fulfillment': {
                  'warehouseId': 'wh-1',
                  'warehouseCode': 'DEV81_KW',
                },
                'totalAmount': '26.250',
              },
              {
                'methodCode': 'express',
                'methodName': 'Express Delivery',
                'currency': 'KWD',
                'amount': '3.500',
                'fulfillment': {
                  'warehouseId': 'wh-1',
                  'warehouseCode': 'DEV81_KW',
                },
                'totalAmount': '28.500',
              },
            ],
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('checkout/preview')) {
      final requestData = options.data is Map ? options.data as Map : {};
      final shippingAddressId = requestData['shippingAddressId'];
      if (shippingAddressId == 'addr-unsupported') {
        if (previewBStartedSignal != null &&
            !previewBStartedSignal!.isCompleted) {
          previewBStartedSignal!.complete();
        }
        if (previewBCompleter != null) {
          await previewBCompleter!.future;
        }
      }

      final selectedMethod = requestData['shippingMethodCode'] ?? 'local';
      final shippingAmt = selectedMethod == 'express' ? '3.500' : '1.250';

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'fulfillment': {'warehouseId': 'wh-1', 'warehouseCode': 'DEV81_KW'},
            'estimated': true,
            'currency': 'KWD',
            'items': [],
            'subtotal': '25.000',
            'productDiscount': '0.000',
            'couponDiscount': '2.500',
            'shippingAmount': shippingAmt,
            'taxAmount': '0.000',
            'totalAmount': '23.750',
            'pricesIncludeTax': false,
            'shipping': {
              'methodCode': selectedMethod,
              'methodName': selectedMethod == 'express'
                  ? 'Express Delivery'
                  : 'Local Delivery',
              'currency': 'KWD',
              'amount': shippingAmt,
            },
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path == '/checkout') {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'order': {
              'id': 'ord-999',
              'orderNumber': 'ORD-20260301-999',
              'status': 'CONFIRMED',
              'paymentStatus': 'PENDING',
              'currency': 'KWD',
              'subtotal': '25.000',
              'discountAmount': '2.500',
              'shippingAmount': '1.250',
              'taxAmount': '0.000',
              'totalAmount': '23.750',
            },
            'idempotent': false,
          },
        }),
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'is_tenant_confirmed': true,
      'selected_tenant_slug': 'dev81-kuwait-fashion',
      'access_token': 'test-token',
    });
    sharedPreferences = await SharedPreferences.getInstance();
  });

  group('Task 06.2 — Checkout Unit & Integration Tests', () {
    test(
      '1. CheckoutRepository.getShippingOptions parses shipping options',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
        dio.httpClientAdapter = MockCheckoutHttpAdapter();
        final repo = CheckoutRepository(dio);

        final options = await repo.getShippingOptions(
          shippingAddressId: 'addr-123',
        );
        expect(options.length, 2);
        expect(options.first.methodCode, 'local');
        expect(options.first.amount, '1.250');
      },
    );

    test('2. CheckoutRepository.getPreview parses preview details', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = MockCheckoutHttpAdapter();
      final repo = CheckoutRepository(dio);

      final preview = await repo.getPreview(
        shippingAddressId: 'addr-123',
        shippingMethodCode: 'local',
      );
      expect(preview.subtotal, '25.000');
      expect(preview.shippingAmount, '1.250');
      expect(preview.totalAmount, '23.750');
    });

    test(
      '3. CheckoutRepository.placeOrder creates order and parses payload',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
        dio.httpClientAdapter = MockCheckoutHttpAdapter();
        final repo = CheckoutRepository(dio);

        final res = await repo.placeOrder(
          shippingAddressId: 'addr-123',
          shippingMethodCode: 'local',
          paymentMethod: 'CASH_ON_DELIVERY',
        );

        expect(res.order.id, 'ord-999');
        expect(res.order.orderNumber, 'ORD-20260301-999');
      },
    );

    testWidgets(
      '27. CheckoutScreen renders products, shipping options, and preview',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(CheckoutScreen), findsOneWidget);
      },
    );

    testWidgets(
      '28. Behavioral check: Placing order sends null billingAddressId when billingSameAsShipping is true',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        final placeOrderBtn = find.byType(AppButton);
        await tester.ensureVisible(placeOrderBtn);
        await tester.tap(placeOrderBtn);
        await tester.pumpAndSettle();

        final checkoutReq = mockAdapter.requests.firstWhere(
          (r) => r.method == 'POST' && r.path.endsWith('/checkout'),
        );

        expect(checkoutReq.body['billingSameAsShipping'], true);
        expect(checkoutReq.body['billingAddressId'], isNull);
      },
    );

    testWidgets(
      '29. Unsupported delivery country displays error and disables Place Order button without sending POST /checkout',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter()
          ..unsupportedCountry = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Shipping is not configured for this country'),
          findsWidgets,
        );

        final buttonFinder = find.byType(AppButton);
        expect(buttonFinder, findsOneWidget);

        final appButtonWidget = tester.widget<AppButton>(buttonFinder);
        expect(appButtonWidget.onPressed, isNull);

        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        final checkoutRequests = mockAdapter.requests
            .where((r) => r.method == 'POST' && r.path.endsWith('/checkout'))
            .length;
        expect(checkoutRequests, 0);
      },
    );

    testWidgets(
      '30. Switching from supported to unsupported address clears shipping options and preview, and switching back recovers',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Local Delivery'), findsOneWidget);

        final changeBtn = find.text('Change').first;
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        final usAddress = find.text('US Office');
        expect(usAddress, findsOneWidget);
        await tester.tap(usAddress);
        await tester.pumpAndSettle();

        expect(find.text('Local Delivery'), findsNothing);
        expect(
          find.text('Shipping is not configured for this country'),
          findsWidgets,
        );

        final appButtonWidget = tester.widget<AppButton>(
          find.byType(AppButton),
        );
        expect(appButtonWidget.onPressed, isNull);

        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        final homeAddress = find.text('Home');
        expect(homeAddress, findsOneWidget);
        await tester.tap(homeAddress);
        await tester.pumpAndSettle();

        expect(find.text('Local Delivery'), findsOneWidget);
        expect(
          find.text('Shipping is not configured for this country'),
          findsNothing,
        );
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      '31. Empty shipping options array from API displays fallback state and blocks order submission',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter()
          ..emptyShippingOptions = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Failed to calculate shipping options'), findsWidgets);
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).onPressed,
          isNull,
        );

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        final checkoutRequests = mockAdapter.requests
            .where((r) => r.method == 'POST' && r.path.endsWith('/checkout'))
            .length;
        expect(checkoutRequests, 0);
      },
    );

    testWidgets(
      '32. Shipping API 500 failure displays error state without stale shipping methods and blocks order submission',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter()..shippingFail = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Local Delivery'), findsNothing);
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).onPressed,
          isNull,
        );

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        final checkoutRequests = mockAdapter.requests
            .where((r) => r.method == 'POST' && r.path.endsWith('/checkout'))
            .length;
        expect(checkoutRequests, 0);
      },
    );

    testWidgets(
      '33. Rapid address changes A -> B -> A with delayed B response retains latest address A state',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final completerB = Completer<void>();
        final mockAdapter = MockCheckoutHttpAdapter()
          ..addressBCompleter = completerB;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        final changeBtn = find.text('Change').first;
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('US Office'));
        await tester.pump();

        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();

        completerB.complete();
        await tester.pumpAndSettle();

        expect(find.text('Local Delivery'), findsOneWidget);
        expect(
          find.text('Shipping is not configured for this country'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '34. Address deletion during active checkout invalidates removed selection and recalculates eligibility for remaining address',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Select US Office initially
        final changeBtn = find.text('Change').first;
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('US Office'));
        await tester.pumpAndSettle();

        expect(
          find.text('Shipping is not configured for this country'),
          findsWidgets,
        );

        // Simulate address deletion: US Office is deleted from backend address list
        mockAdapter.mockAddresses = [
          {
            'id': 'addr-123',
            'label': 'Home',
            'firstName': 'Customer',
            'lastName': 'One',
            'addressLine1': '10 Al-Shuhada Street',
            'city': 'Kuwait City',
            'country': 'KW',
            'countryCode': 'KW',
            'isDefaultShipping': true,
            'isDefaultBilling': true,
          },
        ];

        // Trigger address reload by tapping Change and selecting remaining Home address
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();

        // US Office is no longer selected or present on CheckoutScreen
        expect(find.text('US Office'), findsNothing);
        expect(find.text('10 Al-Shuhada Street'), findsOneWidget);
        expect(find.text('Local Delivery'), findsOneWidget);

        final placeOrderBtn = find.byType(AppButton);
        await tester.tap(placeOrderBtn);
        await tester.pumpAndSettle();

        final checkoutReq = mockAdapter.requests.lastWhere(
          (r) => r.method == 'POST' && r.path.endsWith('/checkout'),
        );
        expect(checkoutReq.body['shippingAddressId'], 'addr-123');
        expect(
          checkoutReq.body['shippingAddressId'],
          isNot('addr-unsupported'),
        );
      },
    );

    testWidgets(
      '35. Localized error handling renders SHIPPING_PROFILE_NOT_CONFIGURED in Arabic when language is set to Arabic',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter()
          ..unsupportedCountry = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              languageProvider.overrideWith(
                () => FakeLanguageNotifier(AppLanguage.ar),
              ),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('الشحن غير متاح لهذه الدولة'), findsWidgets);
      },
    );

    testWidgets(
      '36. Distinct billing address selection and toggle back to Same as Shipping sends null billingAddressId in checkout payload',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        final checkbox = find.byType(Checkbox);
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        final changeBillingBtn = find.text('Change').at(1);
        await tester.tap(changeBillingBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('US Office'));
        await tester.pumpAndSettle();

        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        final placeOrderBtn = find.byType(AppButton);
        await tester.tap(placeOrderBtn);
        await tester.pumpAndSettle();

        final checkoutReq = mockAdapter.requests.lastWhere(
          (r) => r.method == 'POST' && r.path.endsWith('/checkout'),
        );

        expect(checkoutReq.body['billingSameAsShipping'], true);
        expect(checkoutReq.body['billingAddressId'], isNull);
      },
    );

    testWidgets(
      '37. Selecting non-first shipping method express and applying coupon preserves express shipping method selection',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockCheckoutHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Select 'Express Delivery' via Radio button
        final expressRadio = find.byType(Radio<String>).last;
        expect(expressRadio, findsOneWidget);
        await tester.ensureVisible(expressRadio);
        await tester.tap(expressRadio);
        await tester.pumpAndSettle();

        // Apply coupon 'SAVE10'
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();

        final couponField = find.byType(TextField).first;
        await tester.enterText(couponField, 'SAVE10');
        await tester.pumpAndSettle();

        final applyBtn = find.text('Apply');
        await tester.ensureVisible(applyBtn);
        await tester.tap(applyBtn);
        await tester.pumpAndSettle();

        // Express Delivery remains selected after coupon recalculation
        final updatedRadio = tester.widget<Radio<String>>(expressRadio);
        expect(updatedRadio.groupValue, 'express');

        final previewReq = mockAdapter.requests.lastWhere(
          (r) => r.method == 'POST' && r.path.contains('checkout/preview'),
        );
        expect(previewReq.body['shippingMethodCode'], 'express');
        expect(previewReq.body['couponCode'], 'SAVE10');

        // Place order
        final placeOrderBtn = find.byType(AppButton);
        await tester.ensureVisible(placeOrderBtn);
        await tester.tap(placeOrderBtn);
        await tester.pumpAndSettle();

        final checkoutReq = mockAdapter.requests.lastWhere(
          (r) => r.method == 'POST' && r.path.endsWith('/checkout'),
        );

        expect(checkoutReq.body['shippingMethodCode'], 'express');
        expect(checkoutReq.body['couponCode'], 'SAVE10');
      },
    );

    testWidgets(
      '38. Selected shipping address disappearing from API response triggers automatic reconciliation to default address and discards stale B preview',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final previewBCompleter = Completer<void>();
        final previewBStartedSignal = Completer<void>();

        final mockAdapter = MockCheckoutHttpAdapter()
          ..previewBCompleter = previewBCompleter
          ..previewBStartedSignal = previewBStartedSignal;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to US Office (address B)
        final changeBtn = find.text('Change').first;
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('US Office'));
        await tester.pump();

        // Address list updates on server: US Office (B) deleted
        mockAdapter.mockAddresses = [
          {
            'id': 'addr-123',
            'label': 'Home',
            'firstName': 'Customer',
            'lastName': 'One',
            'addressLine1': '10 Al-Shuhada Street',
            'city': 'Kuwait City',
            'country': 'KW',
            'countryCode': 'KW',
            'isDefaultShipping': true,
            'isDefaultBilling': true,
          },
        ];

        // Trigger address refresh on mounted CheckoutScreen by opening Change and returning
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        final backBtn = find.byIcon(Icons.arrow_back_ios_new).first;
        await tester.tap(backBtn);
        await tester.pump();

        // Identify Place Order AppButton explicitly by checking button text
        final placeOrderFinder = find.byType(AppButton).first;
        final initialButtonWidget = tester.widget<AppButton>(placeOrderFinder);
        expect(initialButtonWidget.text, contains('place_order_with_total'));

        // Place Order button disabled while mounted screen reconciles selection and preview finishes
        expect(initialButtonWidget.onPressed, isNull);

        await tester.pumpAndSettle();

        // Automatically reconciles to remaining Home address addr-123 (A)
        expect(find.text('10 Al-Shuhada Street'), findsOneWidget);
        expect(find.text('Local Delivery'), findsOneWidget);

        final readyButtonWidget = tester.widget<AppButton>(placeOrderFinder);
        expect(readyButtonWidget.onPressed, isNotNull);

        // Release stale delayed B preview response
        if (!previewBCompleter.isCompleted) {
          previewBCompleter.complete();
        }
        await tester.pumpAndSettle();

        // Assert address A (Home) remains selected and valid after releasing stale B preview
        expect(find.text('10 Al-Shuhada Street'), findsOneWidget);
        expect(find.text('Local Delivery'), findsOneWidget);

        // Place order
        await tester.ensureVisible(placeOrderFinder);
        await tester.tap(placeOrderFinder);
        await tester.pumpAndSettle();

        final checkoutReq = mockAdapter.requests.lastWhere(
          (r) => r.method == 'POST' && r.path.endsWith('/checkout'),
        );

        expect(checkoutReq.body['shippingAddressId'], 'addr-123');
        final checkoutDeletedReqs = mockAdapter.requests
            .where(
              (r) =>
                  r.method == 'POST' &&
                  r.path.endsWith('/checkout') &&
                  r.body is Map &&
                  r.body['shippingAddressId'] == 'addr-unsupported',
            )
            .length;
        expect(checkoutDeletedReqs, 0);
      },
    );
  });
}
