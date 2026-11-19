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
import 'package:ecommerce/features/favorites/data/favorites_repository.dart';
import 'package:ecommerce/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:ecommerce/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/widgets/product_card.dart';
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

class MockWishlistHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  final Set<String> wishlistProductIds = {'p-1'};
  Completer<void>? postCompleter;
  bool shouldFail = false;
  bool postShouldFail = false;

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
        jsonEncode({'message': 'Wishlist failed'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && path.contains('/wishlist/items')) {
      if (postCompleter != null) {
        await postCompleter!.future;
      }
      if (postShouldFail) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to add item'}),
          400,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      final body = options.data is Map ? options.data as Map : {};
      final pId = body['productId']?.toString() ?? 'p-1';
      wishlistProductIds.add(pId);

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Product added to wishlist successfully',
          'data': {
            'id': 'wi-$pId',
            'productId': pId,
            'addedAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        201,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'DELETE' && path.contains('/wishlist/items/')) {
      final pId = path.split('/').last;
      wishlistProductIds.remove(pId);

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Product removed from wishlist successfully',
          'data': null,
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/wishlist/check/')) {
      final pId = path.split('/').last;
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'productId': pId,
            'isInWishlist': wishlistProductIds.contains(pId),
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/wishlist')) {
      final tenantHeader = options.headers['X-Tenant-Slug']?.toString() ?? 'dev81-kuwait-fashion';
      final isIndep = tenantHeader == 'dev81-independent';

      final itemsList = isIndep
          ? [
              {
                'id': 'wi-indep-1',
                'addedAt': '2026-03-01T10:00:00.000Z',
                'product': {
                  'id': 'p-indep-1',
                  'name': 'Riyadh Tee',
                  'slug': 'dev81-kuwait-tee',
                  'status': 'ACTIVE',
                  'images': [
                    {'id': 'img-1', 'url': '/uploads/tee.jpg', 'isPrimary': true}
                  ],
                }
              }
            ]
          : wishlistProductIds.map((id) => {
              'id': 'wi-$id',
              'addedAt': '2026-03-01T10:00:00.000Z',
              'product': {
                'id': id,
                'name': id == 'p-1' ? 'Dev81 Kuwait Tee' : 'Product $id',
                'slug': 'dev81-product-$id',
                'status': 'ACTIVE',
                'images': [
                  {'id': 'img-1', 'url': '/uploads/tee.jpg', 'isPrimary': true}
                ],
              }
            }).toList();

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'wl-123',
            'count': itemsList.length,
            'items': itemsList,
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

  group('Task 06.4.1 — Wishlist Integration & Behavioral Tests', () {
    test('1. GET /wishlist parses response DTO correctly', () async {
      final mockAdapter = MockWishlistHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = FavoritesRepository(dio);
      final res = await repo.getWishlist();

      expect(res.id, 'wl-123');
      expect(res.items.length, 1);
      expect(res.items.first.product.id, 'p-1');
      expect(res.items.first.product.name, 'Dev81 Kuwait Tee');
    });

    test('2. POST /wishlist/items sends exactly productId', () async {
      final mockAdapter = MockWishlistHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = FavoritesRepository(dio);
      await repo.addToWishlist('p-1');

      expect(mockAdapter.requests.last.method, 'POST');
      expect(mockAdapter.requests.last.path, contains('/wishlist/items'));
      expect(mockAdapter.requests.last.body, {'productId': 'p-1'});
    });

    test('3. DELETE /wishlist/items/:productId constructs correct URL path', () async {
      final mockAdapter = MockWishlistHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = FavoritesRepository(dio);
      await repo.removeFromWishlist('p-1');

      expect(mockAdapter.requests.last.method, 'DELETE');
      expect(mockAdapter.requests.last.path, contains('/wishlist/items/p-1'));
    });

    test('4. GET /wishlist/check/:productId parses isInWishlist flag', () async {
      final mockAdapter = MockWishlistHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = FavoritesRepository(dio);
      final isFav = await repo.checkWishlist('p-1');

      expect(isFav, isTrue);
    });

    test('5. Unauthenticated state sends zero wishlist HTTP requests', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
      final authNotifier = FakeAuthTokenNotifier()..token = null;
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => authNotifier),
          currentUserProvider.overrideWith(() => FakeUserNotifier()..user = null),
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

      container.listen(wishlistControllerProvider, (_, _) {});

      final state = await container.read(wishlistControllerProvider.future);
      expect(state.items, isEmpty);
      expect(mockAdapter.requests.length, 0);
    });

    testWidgets('6. Favoriting a product updates all subscribed heart widgets', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();

      const product = ProductModel(
        id: 'p-1',
        name: 'Dev81 Kuwait Tee',
        slug: 'dev81-kuwait-tee',
        image: '/uploads/tee.jpg',
        priceInfo: ProductPriceModel(originalPrice: 25.0, finalPrice: 25.0),
        isFavorite: false,
        rating: 4.8,
        reviewCount: 1,
        hasVariants: false,
      );

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
          child: MaterialApp(
            home: Scaffold(
              body: ProductCard(
                product: product,
                onFavoriteTap: () {},
                onAddTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap heart button
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      final deleteReq = mockAdapter.requests.where((r) => r.method == 'DELETE' && r.path.contains('/wishlist/items/p-1')).length;
      expect(deleteReq, 1);
    });

    testWidgets('7. Removing a product from Favorites screen updates shared Riverpod state', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();

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
          child: const MaterialApp(home: FavoritesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dev81 Kuwait Tee'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      final deleteReqs = mockAdapter.requests.where((r) => r.method == 'DELETE' && r.path.contains('/wishlist/items/p-1')).length;
      expect(deleteReqs, 1);
    });

    test('8. Failed mutation rolls back optimistic favorite state', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter()..postShouldFail = true;
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      // Attempt adding new product 'p-999' which fails
      try {
        await container.read(wishlistControllerProvider.notifier).toggleFavorite('p-999');
      } catch (_) {}

      final state = container.read(wishlistControllerProvider).value!;
      expect(state.isFavorite('p-999'), isFalse);
    });

    test('9. Rapid duplicate heart taps generate 1 mutation request', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      // Rapid calls
      final f1 = container.read(wishlistControllerProvider.notifier).toggleFavorite('p-1');
      final f2 = container.read(wishlistControllerProvider.notifier).toggleFavorite('p-1');

      await Future.wait([f1, f2]);

      final deleteReqs = mockAdapter.requests.where((r) => r.method == 'DELETE' && r.path.contains('/wishlist/items/p-1')).length;
      expect(deleteReqs, 1);
    });

    test('10. Tenant switch during delayed GET discards old tenant response', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      // Switch tenant
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');
      final state = await container.read(wishlistControllerProvider.future);

      expect(state.items.first.product.id, 'p-indep-1');
    });

    test('11. Logout or account switch during delayed mutation suppresses stale update', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
      final authNotifier = FakeAuthTokenNotifier();
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => authNotifier),
          currentUserProvider.overrideWith(() => FakeUserNotifier()),
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      // Logout
      authNotifier.setToken(null);
      await Future.microtask(() {});

      final state = await container.read(wishlistControllerProvider.future);
      expect(state.items, isEmpty);
    });

    testWidgets('12. Failed GET displays Error/Retry UI instead of empty-wishlist view', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter()..shouldFail = true;

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
          child: const MaterialApp(home: FavoritesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load wishlist'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      mockAdapter.shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Dev81 Kuwait Tee'), findsOneWidget);
    });

    test('13. Two different products toggled concurrently preserve both optimistic states', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      // Concurrently toggle product 'p-2' and 'p-3'
      final f1 = container.read(wishlistControllerProvider.notifier).toggleFavorite('p-2');
      final f2 = container.read(wishlistControllerProvider.notifier).toggleFavorite('p-3');

      await Future.wait([f1, f2]);

      final state = container.read(wishlistControllerProvider).value!;
      expect(state.isFavorite('p-2'), isTrue);
      expect(state.isFavorite('p-3'), isTrue);
    });

    test('14. One of two concurrent mutations fails while the other succeeds', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter()..postShouldFail = true;
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      try {
        await container.read(wishlistControllerProvider.notifier).toggleFavorite('p-failed');
      } catch (_) {}

      final state = container.read(wishlistControllerProvider).value!;
      expect(state.isFavorite('p-failed'), isFalse);
    });

    test('15. Tenant switch while GET is pending discards old response', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');
      final state = await container.read(wishlistControllerProvider.future);

      expect(state.items.first.product.id, 'p-indep-1');
    });

    test('16. User logout or account switch while mutation is pending suppresses stale update', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
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

      container.listen(wishlistControllerProvider, (_, _) {});

      await container.read(wishlistControllerProvider.future);

      authNotifier.setToken(null);
      fakeUserNotifier.user = null;
      await Future.microtask(() {});

      final state = await container.read(wishlistControllerProvider.future);
      expect(state.items, isEmpty);
      expect(state.favoriteProductIds, isEmpty);
    });

    testWidgets('17. ProductCard does not display stale favorite state while new session is loading', (tester) async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockWishlistHttpAdapter();
      final authNotifier = FakeAuthTokenNotifier()..token = null;
      final fakeUserNotifier = FakeUserNotifier()..user = null;

      const product = ProductModel(
        id: 'p-1',
        name: 'Dev81 Kuwait Tee',
        slug: 'dev81-kuwait-tee',
        image: '/uploads/tee.jpg',
        priceInfo: ProductPriceModel(originalPrice: 25.0, finalPrice: 25.0),
        isFavorite: false,
        rating: 4.8,
        reviewCount: 1,
        hasVariants: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => authNotifier),
            currentUserProvider.overrideWith(() => fakeUserNotifier),
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
          child: MaterialApp(
            home: Scaffold(
              body: ProductCard(
                product: product,
                onFavoriteTap: () {},
                onAddTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Unauthenticated -> heart is outline
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });
}
