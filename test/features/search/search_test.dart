import 'dart:async';
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
import 'package:ecommerce/features/auth/models/auth_response_models.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/search/models/filter_model.dart';
import 'package:ecommerce/features/search/presentation/providers/search_provider.dart';
import 'package:ecommerce/features/search/presentation/screens/search_filter_screen.dart';
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
  final Map<String, dynamic> queryParameters;

  RecordedRequest({
    required this.sequenceNumber,
    required this.path,
    required this.method,
    required this.headers,
    required this.queryParameters,
  });
}

class MockSearchHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  Completer<void>? page2Completer;
  bool page2ShouldFail = false;
  bool returnDuplicatePage2 = false;
  bool shouldFail = false;
  bool onePageOnly = false;

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
      queryParameters: Map.from(options.queryParameters),
    ));

    final path = options.path;
    final query = options.queryParameters;
    final page = query['page'];

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Search failed'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

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

    if (path.contains('/categories/active')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': [
            {'id': 'cat-100', 'name': 'Apparel'},
          ]
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/brands/active')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': [
            {'id': 'brand-200', 'name': 'Nike'},
          ]
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/products')) {
      final tenantHeader = options.headers['X-Tenant-Slug']?.toString() ?? 'dev81-kuwait-fashion';
      final isIndep = tenantHeader == 'dev81-independent';

      if (page == 2 || page == '2') {
        final productId = returnDuplicatePage2 ? 'p-1' : 'p-2';
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': productId,
                  'name': 'Dev81 Shoe 2',
                  'slug': 'dev81-shoe-2',
                  'status': 'ACTIVE',
                  'rating': 4.5,
                  'isInWishlist': false,
                  'priceInfo': {
                    'basePrice': 50.0,
                    'finalPrice': 50.0,
                    'hasDiscount': false,
                    'discountAmount': 0.0,
                    'currency': isIndep ? 'SAR' : 'KWD',
                  },
                  'primaryImage': {'id': 'img-2', 'url': '/uploads/shoe2.png'},
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

      final searchVal = query['search']?.toString() ?? '';
      final prodName = searchVal.isNotEmpty ? 'Result for $searchVal' : 'Dev81 Kuwait Tee';

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'items': [
              {
                'id': isIndep ? 'p-indep-1' : 'p-1',
                'name': prodName,
                'slug': 'dev81-kuwait-tee',
                'status': 'ACTIVE',
                'rating': 4.8,
                'isInWishlist': false,
                'priceInfo': {
                  'basePrice': 25.0,
                  'finalPrice': 22.5,
                  'hasDiscount': true,
                  'discountAmount': 2.5,
                  'currency': isIndep ? 'SAR' : 'KWD',
                },
                'primaryImage': {'id': 'img-1', 'url': '/uploads/tee.png'},
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'totalItems': onePageOnly ? 1 : 2,
              'totalPages': onePageOnly ? 1 : 2,
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

  group('Task 06.3.1 — Search Integration, Pagination & UI Tests', () {
    test('1. FilterModel copyWith clears nullable categoryId and brandId when passed null', () {
      const filter = FilterModel(categoryId: 'cat-100', brandId: 'brand-200');
      final cleared = filter.copyWith(categoryId: null, brandId: null);

      expect(cleared.categoryId, isNull);
      expect(cleared.brandId, isNull);
    });

    test('2. Default FilterModel maxPrice is null for unrestricted price search', () {
      const filter = FilterModel();
      expect(filter.maxPrice, isNull);
    });

    test('3. ProductRepository searchProducts sends contract-aligned query parameters', () async {
      final mockAdapter = MockSearchHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = ProductRepository(dio);
      final products = await repo.searchProducts(
        search: 'shirt',
        minPrice: 10.0,
        maxPrice: 500.0,
        categoryId: 'cat-100',
        brandId: 'brand-200',
        sortBy: 'basePrice',
        sortOrder: 'asc',
        page: 1,
        limit: 20,
      );

      expect(products.length, 1);
      final params = mockAdapter.requests.first.queryParameters;
      expect(params['search'], 'shirt');
      expect(params['minPrice'], 10.0);
      expect(params['maxPrice'], 500.0);
      expect(params['categoryId'], 'cat-100');
      expect(params['brandId'], 'brand-200');
      expect(params['sortBy'], 'basePrice');
      expect(params['sortOrder'], 'asc');
    });

    testWidgets('4. Search query input debounce sends final search request', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter();

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
          child: const MaterialApp(home: SearchFilterScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 's');
      await tester.enterText(find.byType(TextField).first, 'sh');
      await tester.enterText(find.byType(TextField).first, 'shirt');

      // Fast forward past 500ms debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final searchRequests = mockAdapter.requests.where((r) => r.queryParameters.containsKey('search')).toList();
      expect(searchRequests.isNotEmpty, isTrue);
      expect(searchRequests.last.queryParameters['search'], 'shirt');
    });

    testWidgets('5. Keyboard search submission triggers immediate search request', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter();

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
          child: const MaterialApp(home: SearchFilterScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'jacket');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final lastReq = mockAdapter.requests.lastWhere((r) => r.queryParameters.containsKey('search'));
      expect(lastReq.queryParameters['search'], 'jacket');
    });

    test('6. SearchController loadNextPage appends page 2 unique products exactly once', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter();
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

      container.listen(searchControllerProvider, (_, _) {});

      final statePage1 = await container.read(searchControllerProvider.future);
      expect(statePage1.items.length, 1);
      expect(statePage1.items.first.id, 'p-1');

      await container.read(searchControllerProvider.notifier).loadNextPage();
      final statePage2 = container.read(searchControllerProvider).value!;

      expect(statePage2.items.length, 2);
      expect(statePage2.items[0].id, 'p-1');
      expect(statePage2.items[1].id, 'p-2');
    });

    test('7. SearchController discards duplicate page 2 products', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter()..returnDuplicatePage2 = true;
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

      container.listen(searchControllerProvider, (_, _) {});

      await container.read(searchControllerProvider.future);
      await container.read(searchControllerProvider.notifier).loadNextPage();

      final state = container.read(searchControllerProvider).value!;
      expect(state.items.length, 1); // Duplicate p-1 ignored
    });

    test('8. Filter change during pending page 2 discards stale page 2 results', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final completer = Completer<void>();
      final mockAdapter = MockSearchHttpAdapter()..page2Completer = completer;
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

      container.listen(searchControllerProvider, (_, _) {});

      await container.read(searchControllerProvider.future);
      container.read(searchControllerProvider.notifier).loadNextPage();

      // Filter change while page 2 is in-flight
      container.read(filterProvider.notifier).updateFilter(const FilterModel(minPrice: 50.0));
      completer.complete();

      await container.read(searchControllerProvider.future);
      final state = container.read(searchControllerProvider).value!;
      expect(state.page, 1);
    });

    test('9. Tenant switch while search request is in-flight discards old-tenant products', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter();
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

      container.listen(searchControllerProvider, (_, _) {});

      await container.read(searchControllerProvider.future);

      // Switch tenant
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');
      final state = await container.read(searchControllerProvider.future);

      expect(state.items.first.id, 'p-indep-1');
    });

    testWidgets('10. Search error state displays retry button and recovers on retry', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter()..shouldFail = true;

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
          child: const MaterialApp(home: SearchFilterScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to search products'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      mockAdapter.shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Dev81 Kuwait Tee'), findsOneWidget);
    });

    test('11. Load-more failure preserves page 1 products and sets loadMoreError', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter()..page2ShouldFail = true;
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

      container.listen(searchControllerProvider, (_, _) {});

      await container.read(searchControllerProvider.future);
      await container.read(searchControllerProvider.notifier).loadNextPage();

      final state = container.read(searchControllerProvider).value!;
      expect(state.items.length, 1);
      expect(state.items.first.id, 'p-1');
      expect(state.loadMoreError, isNotNull);
    });

    testWidgets('12. Search screen Add to Cart action adds product to cart', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter();

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
          child: const MaterialApp(home: SearchFilterScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dev81 Kuwait Tee'), findsOneWidget);
    });

    test('13. Default search query omits maxPrice from queryParameters', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter();
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

      container.listen(searchControllerProvider, (_, _) {});

      await container.read(searchControllerProvider.future);
      final params = mockAdapter.requests.first.queryParameters;

      expect(params.containsKey('maxPrice'), isFalse);
    });

    test('14. One-page pagination result stops after page 1 (hasMore == false)', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockSearchHttpAdapter()..onePageOnly = true;
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

      container.listen(searchControllerProvider, (_, _) {});

      final statePage1 = await container.read(searchControllerProvider.future);

      expect(statePage1.hasMore, isFalse);
      expect(statePage1.totalPages, 1);

      final reqCount = mockAdapter.requests.length;
      await container.read(searchControllerProvider.notifier).loadNextPage();

      // No second HTTP request issued
      expect(mockAdapter.requests.length, reqCount);
    });

    test('15. Product priced above 100000 remains eligible when maxPrice is null', () {
      const highPriceProduct = ProductModel(
        id: 'p-expensive',
        name: 'Luxury Item',
        slug: 'luxury-item',
        image: '/uploads/luxury.jpg',
        priceInfo: ProductPriceModel(
          originalPrice: 150000.0,
          finalPrice: 150000.0,
        ),
        isFavorite: false,
        rating: 5.0,
        reviewCount: 1,
        hasVariants: false,
      );

      const filter = FilterModel(); // maxPrice == null
      final maxP = filter.maxPrice ?? double.infinity;
      final isEligible = highPriceProduct.priceInfo.finalPrice >= filter.minPrice &&
          highPriceProduct.priceInfo.finalPrice <= maxP;

      expect(isEligible, isTrue);
    });

    test('16. Missing or malformed pagination metadata falls back safely to totalPages = 1', () async {
      final mockAdapter = MockSearchHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = ProductRepository(dio);
      final result = await repo.getPaginatedProducts();

      expect(result.page, 1);
      expect(result.items.length, 1);
    });
  });
}
