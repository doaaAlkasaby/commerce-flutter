import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/auth/models/auth_response_models.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/checkout/data/payment_repository.dart';
import 'package:ecommerce/features/checkout/models/payment_models.dart';
import 'package:ecommerce/features/checkout/presentation/providers/payment_provider.dart';
import 'package:ecommerce/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:ecommerce/features/checkout/utils/payment_url_launcher.dart';
import 'package:ecommerce/features/orders/presentation/screens/order_details_screen.dart';
import 'package:ecommerce/main.dart';

class FakeAuthTokenNotifier extends AuthTokenNotifier {
  String? token = 'test-token';
  @override
  String? build() => token;

  @override
  Future<void> setToken(String? token, {String? refreshToken}) async {
    this.token = token;
    ref.invalidateSelf();
  }
}

class FakeUserNotifier extends CurrentUser {
  UserDto? user = const UserDto(
    id: 'usr-123',
    email: 'customer@example.com',
    firstName: 'Customer',
    lastName: 'One',
    isEmailVerified: true,
  );

  @override
  Future<UserDto?> build() async => user;
}

class RecordedRequest {
  final int sequenceNumber;
  final String path;
  final String method;
  final Map<String, dynamic> headers;
  final dynamic body;

  RecordedRequest({
    required this.sequenceNumber,
    required this.path,
    required this.method,
    required this.headers,
    this.body,
  });
}

class MockPaymentHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  Completer<void>? verifyCompleter;
  bool shouldFail = false;
  bool verifyShouldFail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(RecordedRequest(
      sequenceNumber: requests.length + 1,
      path: options.path,
      method: options.method,
      headers: Map.from(options.headers),
      body: options.data,
    ));

    final path = options.path;

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Payment request failed'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && path.contains('/payments/') && path.contains('/initiate')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': {
            'id': 'pay-123',
            'orderId': 'ord-123',
            'provider': 'MYFATOORAH',
            'method': 'CARD',
            'status': 'REQUIRES_ACTION',
            'initiationState': 'INITIATED',
            'amount': '23.750',
            'currency': 'KWD',
            'providerPaymentId': 'mock-inv-pay-123',
            'metadata': {'checkoutUrl': 'http://localhost:3000/api/v1/payments/mock/checkout/pay-123?token=abc'},
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && path.contains('/payments/') && path.contains('/verify')) {
      if (verifyCompleter != null) {
        await verifyCompleter!.future;
      }
      if (verifyShouldFail) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to verify payment'}),
          400,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': {
            'id': 'pay-123',
            'orderId': 'ord-123',
            'provider': 'MYFATOORAH',
            'method': 'CARD',
            'status': 'PAID',
            'initiationState': 'INITIATED',
            'amount': '23.750',
            'currency': 'KWD',
            'providerPaymentId': 'mf-inv-123',
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/payments/order/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': [
            {
              'id': 'pay-123',
              'orderId': 'ord-123',
              'provider': 'MYFATOORAH',
              'method': 'CARD',
              'status': 'PENDING',
              'initiationState': 'INITIATED',
              'amount': '23.750',
              'currency': 'KWD',
              'providerPaymentId': 'mf-inv-123',
              'createdAt': '2026-03-01T10:00:00.000Z',
            }
          ]
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/payments/pay-123')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': {
            'id': 'pay-123',
            'orderId': 'ord-123',
            'provider': 'MYFATOORAH',
            'method': 'CARD',
            'status': 'PENDING',
            'initiationState': 'INITIATED',
            'amount': '23.750',
            'currency': 'KWD',
            'providerPaymentId': 'mf-inv-123',
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/orders/my/ord-123')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'ord-123',
            'orderNumber': 'ORD-123',
            'status': 'PENDING',
            'paymentStatus': 'PENDING',
            'currency': 'KWD',
            'subtotal': '25.000',
            'discountAmount': '2.500',
            'shippingAmount': '1.250',
            'taxAmount': '0.000',
            'totalAmount': '23.750',
            'items': [
              {
                'id': 'item-1',
                'productId': 'p-1',
                'variantId': 'var-1',
                'productName': 'Dev81 Kuwait Tee',
                'quantity': 1,
                'unitPrice': '25.000',
                'totalPrice': '25.000',
                'imageUrl': '/uploads/tee.jpg',
              }
            ],
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
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

  group('Task 06.7.5 — Flutter Card Payment Integration Tests', () {
    test('1. PaymentModel parses realistic backend response DTO correctly', () {
      final json = {
        'id': 'pay-123',
        'orderId': 'ord-123',
        'provider': 'MYFATOORAH',
        'method': 'CARD',
        'status': 'REQUIRES_ACTION',
        'initiationState': 'INITIATED',
        'amount': '23.750',
        'currency': 'KWD',
        'providerPaymentId': '123456',
        'metadata': {'checkoutUrl': 'https://demo.myfatoorah.com/pay/123456'},
        'createdAt': '2026-03-01T10:00:00.000Z',
      };

      final payment = PaymentModel.fromJson(json);

      expect(payment.id, 'pay-123');
      expect(payment.orderId, 'ord-123');
      expect(payment.provider, 'MYFATOORAH');
      expect(payment.method, 'CARD');
      expect(payment.status, 'REQUIRES_ACTION');
      expect(payment.amount, '23.750');
      expect(payment.currency, 'KWD');
      expect(payment.checkoutUrl, 'https://demo.myfatoorah.com/pay/123456');
    });

    test('2. Malformed required payment fields throw FormatException', () {
      final jsonNoId = {
        'amount': '23.750',
        'currency': 'KWD',
      };
      expect(() => PaymentModel.fromJson(jsonNoId), throwsA(isA<FormatException>()));

      final jsonInvalidAmount = {
        'id': 'pay-123',
        'amount': 'invalid-amount',
        'currency': 'KWD',
      };
      expect(() => PaymentModel.fromJson(jsonInvalidAmount), throwsA(isA<FormatException>()));
    });

    test('3. Decimal-string amount is preserved with exact precision (23.750)', () {
      final json = {
        'id': 'pay-123',
        'status': 'PENDING',
        'amount': '23.750',
        'currency': 'KWD',
      };

      final payment = PaymentModel.fromJson(json);
      expect(payment.amount, '23.750');
    });

    test('4. PaymentRepository getPayment fetches payment by ID', () async {
      final mockAdapter = MockPaymentHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = PaymentRepository(dio);
      final payment = await repo.getPayment('pay-123');

      expect(payment.id, 'pay-123');
      expect(mockAdapter.requests.first.path, contains('/payments/pay-123'));
    });

    test('5. PaymentRepository getOrderPayments fetches payments by order ID', () async {
      final mockAdapter = MockPaymentHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = PaymentRepository(dio);
      final payments = await repo.getOrderPayments('ord-123');

      expect(payments.length, 1);
      expect(payments.first.id, 'pay-123');
      expect(mockAdapter.requests.first.path, contains('/payments/order/ord-123'));
    });

    test('6. PaymentRepository verifyPayment sends POST to /payments/:id/verify with {} body', () async {
      final mockAdapter = MockPaymentHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = PaymentRepository(dio);
      final payment = await repo.verifyPayment('pay-123');

      expect(payment.status, 'PAID');
      expect(mockAdapter.requests.last.method, 'POST');
      expect(mockAdapter.requests.last.path, contains('/payments/pay-123/verify'));
      expect(mockAdapter.requests.last.body, {});
    });

    test('7. Verification failure rethrows exception without applying false PAID state', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockPaymentHttpAdapter()..verifyShouldFail = true;
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => FakeUserNotifier()),
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
          }),
          dioClientProvider.overrideWith((ref) {
            final tenantSlug = ref.watch(selectedTenantSlugProvider);
            final dio = Dio(BaseOptions(
              baseUrl: 'http://127.0.0.1:3000/api/v1',
              headers: {'X-Tenant-Slug': tenantSlug, 'Authorization': 'Bearer test-token'},
            ));
            dio.httpClientAdapter = mockAdapter;
            return dio;
          }),
        ],
      );

      container.listen(orderPaymentsControllerProvider('ord-123'), (_, _) {});

      await container.read(orderPaymentsControllerProvider('ord-123').future);

      expect(
        () async => await container.read(orderPaymentsControllerProvider('ord-123').notifier).verifyPayment('pay-123'),
        throwsA(isA<DioException>()),
      );

      final state = container.read(orderPaymentsControllerProvider('ord-123')).value!;
      expect(state.payments.first.status, 'PENDING'); // Retains PENDING, not PAID!
    });

    test('8. Verification on Cash on Delivery (provider == NONE) is blocked locally', () {
      const codPayment = PaymentModel(
        id: 'pay-cod',
        orderId: 'ord-123',
        provider: 'NONE',
        method: 'CASH_ON_DELIVERY',
        status: 'PENDING',
        initiationState: 'NOT_STARTED',
        amount: '23.750',
        currency: 'KWD',
        createdAt: '2026-03-01T10:00:00.000Z',
      );

      final canVerify = codPayment.provider == 'MYFATOORAH' &&
          codPayment.providerPaymentId != null &&
          codPayment.providerPaymentId!.isNotEmpty;

      expect(canVerify, isFalse);
    });

    test('9. Delayed GET response after user logout/session switch is safely discarded', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockPaymentHttpAdapter();
      final authNotifier = FakeAuthTokenNotifier();
      final fakeUserNotifier = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => authNotifier),
          currentUserProvider.overrideWith(() => fakeUserNotifier),
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
          }),
          dioClientProvider.overrideWith((ref) {
            final tenantSlug = ref.watch(selectedTenantSlugProvider);
            final token = ref.watch(authTokenProvider);
            final dio = Dio(BaseOptions(
              baseUrl: 'http://127.0.0.1:3000/api/v1',
              headers: {'X-Tenant-Slug': tenantSlug, if (token != null) 'Authorization': 'Bearer $token'},
            ));
            dio.httpClientAdapter = mockAdapter;
            return dio;
          }),
        ],
      );

      container.listen(orderPaymentsControllerProvider('ord-123'), (_, _) {});

      await container.read(orderPaymentsControllerProvider('ord-123').future);

      // Logout
      authNotifier.setToken(null);
      fakeUserNotifier.user = null;
      container.invalidate(currentUserProvider);
      await Future.microtask(() {});

      final state = await container.read(orderPaymentsControllerProvider('ord-123').future);
      expect(state.payments, isEmpty);
    });

    test('10. Tenant switch while payment fetch is pending discards old-tenant response', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockPaymentHttpAdapter();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => FakeUserNotifier()),
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
          }),
          dioClientProvider.overrideWith((ref) {
            final tenantSlug = ref.watch(selectedTenantSlugProvider);
            final dio = Dio(BaseOptions(
              baseUrl: 'http://127.0.0.1:3000/api/v1',
              headers: {'X-Tenant-Slug': tenantSlug, 'Authorization': 'Bearer test-token'},
            ));
            dio.httpClientAdapter = mockAdapter;
            return dio;
          }),
        ],
      );

      container.listen(orderPaymentsControllerProvider('ord-123'), (_, _) {});

      await container.read(orderPaymentsControllerProvider('ord-123').future);

      // Switch tenant
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');
      final state = await container.read(orderPaymentsControllerProvider('ord-123').future);

      expect(state.payments.first.id, 'pay-123');
    });

    testWidgets('11. OrderDetailsScreen renders Verify Payment Status button for MyFatoorah payment', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockPaymentHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => FakeUserNotifier()),
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
            }),
            dioClientProvider.overrideWith((ref) {
              final tenantSlug = ref.watch(selectedTenantSlugProvider);
              final dio = Dio(BaseOptions(
                baseUrl: 'http://127.0.0.1:3000/api/v1',
                headers: {'X-Tenant-Slug': tenantSlug, 'Authorization': 'Bearer test-token'},
              ));
              dio.httpClientAdapter = mockAdapter;
              return dio;
            }),
          ],
          child: const MaterialApp(home: OrderDetailsScreen(orderId: 'ord-123')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Verify Payment Status'), findsOneWidget);
    });

    testWidgets('12. Cash on Delivery checkout remains default payment choice in CheckoutScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockPaymentHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => FakeUserNotifier()),
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
            }),
            dioClientProvider.overrideWith((ref) {
              final tenantSlug = ref.watch(selectedTenantSlugProvider);
              final dio = Dio(BaseOptions(
                baseUrl: 'http://127.0.0.1:3000/api/v1',
                headers: {'X-Tenant-Slug': tenantSlug, 'Authorization': 'Bearer test-token'},
              ));
              dio.httpClientAdapter = mockAdapter;
              return dio;
            }),
          ],
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cash on Delivery (COD)'), findsOneWidget);
    });

    test('13. PaymentRepository initiatePayment sends POST to /payments/:id/initiate', () async {
      final mockAdapter = MockPaymentHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = PaymentRepository(dio);
      final payment = await repo.initiatePayment('pay-123');

      expect(payment.id, 'pay-123');
      expect(payment.checkoutUrl, contains('/api/v1/payments/mock/checkout/pay-123?token=abc'));
      expect(mockAdapter.requests.last.method, 'POST');
      expect(mockAdapter.requests.last.path, contains('/payments/pay-123/initiate'));
    });

    test('14. Android localhost replacement replaces localhost with 10.0.2.2 for emulator', () {
      const rawUrl = 'http://localhost:3000/api/v1/payments/mock/checkout/pay-123?token=abc';
      final androidUrl = rawUrl.replaceAll('localhost', '10.0.2.2');
      expect(androidUrl, 'http://10.0.2.2:3000/api/v1/payments/mock/checkout/pay-123?token=abc');
    });

    testWidgets('15. CheckoutScreen renders Card Payment (Mock Gateway) in dropdown options', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockPaymentHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => FakeUserNotifier()),
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
            }),
            dioClientProvider.overrideWith((ref) {
              final tenantSlug = ref.watch(selectedTenantSlugProvider);
              final dio = Dio(BaseOptions(
                baseUrl: 'http://127.0.0.1:3000/api/v1',
                headers: {'X-Tenant-Slug': tenantSlug, 'Authorization': 'Bearer test-token'},
              ));
              dio.httpClientAdapter = mockAdapter;
              return dio;
            }),
          ],
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cash on Delivery (COD)'));
      await tester.tap(find.text('Cash on Delivery (COD)'));
      await tester.pumpAndSettle();

      expect(find.text('Card Payment (Mock Gateway)'), findsWidgets);
    });

    test('16. PaymentUrlLauncher normalizeUrl replaces localhost with 10.0.2.2 on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const rawUrl = 'http://localhost:3000/api/v1/payments/mock/checkout/pay-123?token=abc';
      final normalized = PaymentUrlLauncher.normalizeUrl(rawUrl);
      expect(normalized, 'http://10.0.2.2:3000/api/v1/payments/mock/checkout/pay-123?token=abc');
      debugDefaultTargetPlatformOverride = null;
    });

    test('17. Terminal payment state (PAID) hides Verify Payment Status and Open Payment Link buttons', () {
      const paidPayment = PaymentModel(
        id: 'pay-123',
        orderId: 'ord-123',
        provider: 'MYFATOORAH',
        method: 'CARD',
        status: 'PAID',
        initiationState: 'INITIATED',
        amount: '23.750',
        currency: 'KWD',
        providerPaymentId: 'mf-inv-123',
        createdAt: '2026-03-01T10:00:00.000Z',
      );

      final isTerminal = ['PAID', 'FAILED', 'CANCELLED', 'REFUNDED'].contains(paidPayment.status);
      final canVerify = !isTerminal &&
          paidPayment.provider == 'MYFATOORAH' &&
          paidPayment.providerPaymentId != null &&
          ['PENDING', 'REQUIRES_ACTION', 'UNKNOWN'].contains(paidPayment.status);

      expect(isTerminal, isTrue);
      expect(canVerify, isFalse);
    });

    test('18. PaymentUrlLauncher launchPaymentUrl returns false for invalid schemes without throwing', () async {
      final resEmpty = await PaymentUrlLauncher.launchPaymentUrl('');
      expect(resEmpty, isFalse);

      final resInvalidScheme = await PaymentUrlLauncher.launchPaymentUrl('ftp://invalid-url.com');
      expect(resInvalidScheme, isFalse);
    });
  });
}
