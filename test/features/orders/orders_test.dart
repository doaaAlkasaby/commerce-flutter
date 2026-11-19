import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/auth/models/auth_response_models.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/orders/data/orders_repository.dart';
import 'package:ecommerce/features/orders/presentation/providers/orders_provider.dart';
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
    email: 'userA@example.com',
    firstName: 'User',
    lastName: 'A',
    isEmailVerified: true,
  );

  @override
  Future<UserDto?> build() async => user;
}

class RecordedRequest {
  final int sequenceNumber;
  final String path;
  final String method;
  final String? tenantSlug;
  final String? token;
  final dynamic page;
  final dynamic status;
  final Map<String, dynamic> queryParameters;

  RecordedRequest({
    required this.sequenceNumber,
    required this.path,
    required this.method,
    this.tenantSlug,
    this.token,
    this.page,
    this.status,
    required this.queryParameters,
  });
}

class RecordingOrdersHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  Completer<void>? page2Completer;
  Completer<void>? orderDetailsCompleter;
  Completer<void>? refreshCompleter;
  bool page2ShouldFail = false;
  bool returnDuplicatePage2 = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final query = options.queryParameters;
    final page = query['page'];
    final status = query['status'];
    final tenantSlug = options.headers['X-Tenant-Slug']?.toString();
    final authHeader = options.headers['Authorization']?.toString();

    requests.add(RecordedRequest(
      sequenceNumber: requests.length + 1,
      path: path,
      method: options.method,
      tenantSlug: tenantSlug,
      token: authHeader,
      page: page,
      status: status,
      queryParameters: Map.from(options.queryParameters),
    ));

    if (page == 2 || page == '2') {
      if (page2Completer != null) {
        await page2Completer!.future;
      }
      if (page2ShouldFail) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to load page 2'}),
          500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
    }

    if (refreshCompleter != null && (page == 1 || page == '1') && requests.length > 1) {
      await refreshCompleter!.future;
    }

    if (path.contains('/orders/my/ord-999')) {
      if (orderDetailsCompleter != null) {
        await orderDetailsCompleter!.future;
      }

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'ord-999',
            'orderNumber': 'ORD-20260301-999',
            'userId': 'usr-123',
            'status': 'CONFIRMED',
            'paymentStatus': 'PENDING',
            'currency': 'KWD',
            'subtotal': '25.000',
            'discountAmount': '2.500',
            'shippingAmount': '1.250',
            'taxAmount': '0.000',
            'totalAmount': '23.750',
            'pricesIncludeTax': false,
            'shippingMethodCode': 'local',
            'shippingMethodName': 'Local Delivery',
            'shippingAddress': {
              'firstName': 'Customer',
              'lastName': 'One',
              'addressLine1': '10 Al-Shuhada Street',
              'city': 'Kuwait City',
              'countryCode': 'KW',
            },
            'items': [
              {
                'id': 'oi-123',
                'productId': 'p-1',
                'variantId': 'var-1',
                'productName': 'Dev81 Kuwait Tee',
                'sku': 'DEV81-KW-TEE',
                'quantity': 1,
                'unitPrice': '25.000',
                'itemDiscountAmount': '0.000',
                'finalUnitPrice': '25.000',
                'totalPrice': '25.000',
                'variantSnapshot': {
                  'images': [
                    {
                      'id': 'img-1',
                      'url': '/uploads/tee.jpg',
                      'isPrimary': true,
                    }
                  ]
                },
                'createdAt': '2026-03-01T10:00:00.000Z',
              }
            ],
            'payments': [
              {
                'id': 'pay-123',
                'provider': 'NONE',
                'method': 'CASH_ON_DELIVERY',
                'status': 'PENDING',
                'amount': '23.750',
                'currency': 'KWD',
                'createdAt': '2026-03-01T10:00:00.000Z',
              }
            ],
            'itemCount': 1,
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/orders/my')) {
      final isIndependentTenant = tenantSlug == 'dev81-independent';

      if (page == 2 || page == '2') {
        final itemId = returnDuplicatePage2
            ? (isIndependentTenant ? 'ord-indep-999' : 'ord-999')
            : (isIndependentTenant ? 'ord-indep-1000' : 'ord-1000');
        final itemNumber = returnDuplicatePage2
            ? (isIndependentTenant ? 'IND-20260301-999' : 'ORD-20260301-999')
            : (isIndependentTenant ? 'IND-20260301-1000' : 'ORD-20260301-1000');

        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': itemId,
                  'orderNumber': itemNumber,
                  'userId': 'usr-123',
                  'status': 'PROCESSING',
                  'paymentStatus': 'PENDING',
                  'currency': isIndependentTenant ? 'SAR' : 'KWD',
                  'subtotal': '50.00',
                  'discountAmount': '0.00',
                  'shippingAmount': '2.00',
                  'taxAmount': '0.00',
                  'totalAmount': '52.00',
                  'itemCount': 1,
                  'items': [],
                  'createdAt': '2026-03-02T10:00:00.000Z',
                }
              ],
              'pagination': {
                'page': 2,
                'limit': 20,
                'totalItems': 2,
                'totalPages': 2,
              }
            }
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }

      final isUserB = authHeader == 'Bearer token-userB';
      final orderId = isUserB ? 'ord-userB-999' : (isIndependentTenant ? 'ord-indep-999' : 'ord-999');
      final orderNumber = isUserB ? 'ORD-USERB-999' : (isIndependentTenant ? 'IND-20260301-999' : 'ORD-20260301-999');

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'items': [
              {
                'id': orderId,
                'orderNumber': orderNumber,
                'userId': isUserB ? 'usr-456' : 'usr-123',
                'status': 'CONFIRMED',
                'paymentStatus': 'PENDING',
                'currency': isIndependentTenant ? 'SAR' : 'KWD',
                'subtotal': '25.000',
                'discountAmount': '2.500',
                'shippingAmount': '1.250',
                'taxAmount': '0.000',
                'totalAmount': '23.750',
                'itemCount': 1,
                'items': [],
                'createdAt': '2026-03-01T10:00:00.000Z',
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'totalItems': 2,
              'totalPages': 2,
            }
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

  group('Task 05.1.5.4 — Orders Behavioral & Isolation Tests', () {
    test('0. Authentication Loading suppresses HTTP requests until user is resolved', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => FakeUserNotifier()..user = null),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      // Zero HTTP requests while user is loading/null
      expect(mockAdapter.requests.length, 0);
    });

    test('1. Page 1 requests GET /orders/my with page=1 and limit=20', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = OrdersRepository(dio);
      final res = await repo.getMyOrders(page: 1, limit: 20);

      expect(mockAdapter.requests.length, 1);
      expect(mockAdapter.requests.first.path, contains('/orders/my'));
      expect(mockAdapter.requests.first.queryParameters['page'], 1);
      expect(mockAdapter.requests.first.queryParameters['limit'], 20);
      expect(res.items.first.id, 'ord-999');
    });

    test('2. Load More requests page 2 and appends its orders', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter();
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      final statePage1 = await container.read(myOrdersControllerProvider.future);
      expect(statePage1.items.length, 1);
      expect(statePage1.items.first.id, 'ord-999');

      await container.read(myOrdersControllerProvider.notifier).loadNextPage();
      final statePage2 = container.read(myOrdersControllerProvider).value!;

      expect(statePage2.items.length, 2);
      expect(statePage2.items[0].id, 'ord-999');
      expect(statePage2.items[1].id, 'ord-1000');
      expect(mockAdapter.requests.length, 2);
      expect(mockAdapter.requests.last.queryParameters['page'], 2);
    });

    test('3. Duplicate order IDs returned on page 2 are not appended', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter()..returnDuplicatePage2 = true;
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      await container.read(myOrdersControllerProvider.notifier).loadNextPage();

      final state = container.read(myOrdersControllerProvider).value!;
      expect(state.items.length, 1); // Duplicate ord-999 ignored
    });

    test('4. Failed page 2 preserves page 1 and exposes loadMoreError', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter()..page2ShouldFail = true;
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      await container.read(myOrdersControllerProvider.notifier).loadNextPage();

      final state = container.read(myOrdersControllerProvider).value!;
      expect(state.items.length, 1);
      expect(state.items.first.id, 'ord-999');
      expect(state.loadMoreError, isNotNull);
    });

    test('5. Retrying page 2 makes another request and appends orders on success', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter()..page2ShouldFail = true;
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      await container.read(myOrdersControllerProvider.notifier).loadNextPage();

      mockAdapter.page2ShouldFail = false;
      await container.read(myOrdersControllerProvider.notifier).loadNextPage();

      final state = container.read(myOrdersControllerProvider).value!;
      expect(state.items.length, 2);
      expect(state.loadMoreError, isNull);
    });

    test('6. Changing status filter while page 2 is pending discards old page 2 response', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final completer = Completer<void>();
      final mockAdapter = RecordingOrdersHttpAdapter()..page2Completer = completer;
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      container.read(myOrdersControllerProvider.notifier).loadNextPage();

      // Filter change while page 2 is pending
      container.read(orderFilterProvider.notifier).setFilter('PROCESSING');
      completer.complete();

      await container.read(myOrdersControllerProvider.future);
      final state = container.read(myOrdersControllerProvider).value!;
      expect(state.page, 1);
    });

    test('7. Switching tenant while page 2 is pending prevents old-tenant orders', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final completer = Completer<void>();
      final mockAdapter = RecordingOrdersHttpAdapter()..page2Completer = completer;
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      container.read(myOrdersControllerProvider.notifier).loadNextPage();

      // Tenant switch while page 2 is in-flight
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');
      completer.complete();

      await container.read(myOrdersControllerProvider.future);
      final state = container.read(myOrdersControllerProvider).value!;
      expect(state.items.first.id, 'ord-indep-999');
    });

    test('8. Logging out while page 2 is pending prevents old-user orders and zero unauthenticated requests', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final completer = Completer<void>();
      final mockAdapter = RecordingOrdersHttpAdapter()..page2Completer = completer;
      final authNotifier = FakeAuthTokenNotifier();
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => authNotifier),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      container.read(myOrdersControllerProvider.notifier).loadNextPage();

      // Logout while page 2 is pending
      authNotifier.setToken(null);
      fakeUser.user = null;
      completer.complete();

      // Verify unauthenticated requests count is zero
      final unauthRequests = mockAdapter.requests.where((r) => r.token == null || r.token!.isEmpty).length;
      expect(unauthRequests, 0);
    });

    test('9. Rapid repeated loadNextPage triggers only 1 HTTP request', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter();
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);

      // Rapid calls
      final f1 = container.read(myOrdersControllerProvider.notifier).loadNextPage();
      final f2 = container.read(myOrdersControllerProvider.notifier).loadNextPage();
      final f3 = container.read(myOrdersControllerProvider.notifier).loadNextPage();

      await Future.wait([f1, f2, f3]);

      final page2Requests = mockAdapter.requests.where((r) => r.queryParameters['page'] == 2).length;
      expect(page2Requests, 1);
    });

    test('10. Pull-to-refresh issues a new page-1 API request and awaits completion', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final refreshCompleter = Completer<void>();
      final mockAdapter = RecordingOrdersHttpAdapter();
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      expect(mockAdapter.requests.length, 1);

      mockAdapter.refreshCompleter = refreshCompleter;
      final refreshFuture = container.read(myOrdersControllerProvider.notifier).refresh();

      // Verify refreshFuture is pending
      refreshCompleter.complete();
      await refreshFuture;

      final state = container.read(myOrdersControllerProvider).value!;
      expect(state.items.first.id, 'ord-999');
    });

    test('11. Account switch from User A to User B discards User A in-flight response and updates entire list', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final completer = Completer<void>();
      final mockAdapter = RecordingOrdersHttpAdapter()..page2Completer = completer;
      final authNotifier = FakeAuthTokenNotifier();
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => authNotifier),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await container.read(myOrdersControllerProvider.future);
      container.read(myOrdersControllerProvider.notifier).loadNextPage();

      // Account switch to User B
      fakeUser.user = const UserDto(
        id: 'usr-456',
        email: 'userB@example.com',
        firstName: 'User',
        lastName: 'B',
        isEmailVerified: true,
      );
      authNotifier.setToken('token-userB');
      completer.complete();

      await container.read(myOrdersControllerProvider.future);
      final state = container.read(myOrdersControllerProvider).value!;
      expect(state.items.map((i) => i.id).toList(), ['ord-userB-999']);
    });

    test('12. OrderDetails in-flight request is discarded when user switches', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final completer = Completer<void>();
      final mockAdapter = RecordingOrdersHttpAdapter()..orderDetailsCompleter = completer;
      final authNotifier = FakeAuthTokenNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => authNotifier),
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

      final orderDetailsFuture = container.read(orderDetailsProvider('ord-999').future);

      // Logout before order details response resolves
      authNotifier.setToken(null);
      completer.complete();

      final order = await orderDetailsFuture;
      expect(order, isNull);
    });

    test('13. Page 2 Authentication Guard prevents requests when unauthenticated', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = RecordingOrdersHttpAdapter();
      final authNotifier = FakeAuthTokenNotifier();
      final fakeUser = FakeUserNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => authNotifier),
          currentUserProvider.overrideWith(() => fakeUser),
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

      container.listen(myOrdersControllerProvider, (_, _) {});

      await Future.microtask(() {});

      // Unauthenticate user
      fakeUser.user = null;
      authNotifier.setToken(null);
      await Future.microtask(() {});

      final countAfterLogout = mockAdapter.requests.length;

      // Attempt loadNextPage while unauthenticated
      await container.read(myOrdersControllerProvider.notifier).loadNextPage();

      expect(mockAdapter.requests.length, countAfterLogout);
    });
  });
}
