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
import 'package:ecommerce/features/product/models/review_models.dart';
import 'package:ecommerce/features/product/presentation/providers/reviews_provider.dart';
import 'package:ecommerce/features/product/presentation/screens/all_reviews_screen.dart';
import 'package:ecommerce/features/product/presentation/screens/product_details_screen.dart';
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
  final dynamic body;

  RecordedRequest({
    required this.sequenceNumber,
    required this.path,
    required this.method,
    required this.headers,
    required this.queryParameters,
    this.body,
  });
}

class MockReviewsHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  Completer<void>? postCompleter;
  bool shouldFail = false;
  bool purchaseRequiredError = false;
  bool alreadyReviewedError = false;

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
      body: options.data,
    ));

    final path = options.path;

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Failed to fetch reviews'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && path.contains('/reviews')) {
      if (postCompleter != null) {
        await postCompleter!.future;
      }
      if (purchaseRequiredError) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'message': 'You can only review products you have purchased',
            'code': 'PRODUCT_PURCHASE_REQUIRED',
          }),
          403,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      if (alreadyReviewedError) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'message': 'You have already reviewed this product',
            'code': 'REVIEW_ALREADY_EXISTS',
          }),
          409,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Review created successfully',
          'data': {
            'id': 'rev-200',
            'productId': 'p-1',
            'user': {'id': 'usr-123', 'name': 'Customer One'},
            'rating': 5,
            'title': 'Awesome Item',
            'comment': 'Really loved this product!',
            'isApproved': true,
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        201,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'PATCH' && path.contains('/reviews/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Review updated successfully',
          'data': {
            'id': 'rev-1',
            'productId': 'p-1',
            'user': {'id': 'usr-123', 'name': 'Customer One'},
            'rating': 4,
            'title': 'Updated Review',
            'comment': 'Edited comment.',
            'isApproved': true,
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'DELETE' && path.contains('/reviews/')) {
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'message': 'Review deleted successfully', 'data': null}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/reviews/summary')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': {
            'average': 4.85,
            'count': 12,
            'distribution': {'1': 0, '2': 0, '3': 1, '4': 3, '5': 8},
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/reviews')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': {
            'items': [
              {
                'id': 'rev-1',
                'productId': 'p-1',
                'user': {'id': 'usr-123', 'name': 'Customer One'},
                'rating': 5,
                'title': 'Great Quality!',
                'comment': 'Super soft cotton shirt.',
                'isApproved': true,
                'createdAt': '2026-03-01T10:00:00.000Z',
              }
            ],
            'total': 1,
            'page': 1,
            'limit': 20,
            'totalPages': 1,
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/products/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'p-1',
            'name': 'Dev81 Kuwait Tee',
            'slug': 'dev81-kuwait-tee',
            'priceInfo': {'originalPrice': 25.0, 'finalPrice': 25.0},
            'image': '/uploads/tee.jpg',
            'rating': 4.8,
            'reviewCount': 1,
            'isFavorite': false,
            'hasVariants': false,
            'description': 'High quality tee',
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

  group('Task 06.6.1 — Product Reviews Integration Tests', () {
    test('1. ProductReviewModel parses DTO with nested user, title, comment, and rating', () {
      final json = {
        'id': 'rev-1',
        'productId': 'p-1',
        'user': {'id': 'usr-123', 'name': 'Alice Smith'},
        'rating': 5,
        'title': 'Great Item',
        'comment': 'Highly recommended.',
        'isApproved': true,
        'createdAt': '2026-03-01T10:00:00.000Z',
      };

      final review = ProductReviewModel.fromJson(json);

      expect(review.id, 'rev-1');
      expect(review.user.id, 'usr-123');
      expect(review.user.name, 'Alice Smith');
      expect(review.rating, 5);
      expect(review.title, 'Great Item');
      expect(review.comment, 'Highly recommended.');
    });

    test('2. ProductRatingSummaryModel parses average, count, and star distribution', () {
      final json = {
        'average': 4.85,
        'count': 12,
        'distribution': {'1': 0, '2': 0, '3': 1, '4': 3, '5': 8},
      };

      final summary = ProductRatingSummaryModel.fromJson(json);

      expect(summary.average, 4.85);
      expect(summary.count, 12);
      expect(summary.distribution[5], 8);
      expect(summary.distribution[3], 1);
    });

    test('3. ProductRepository getPaginatedProductReviews sends correct page and limit parameters', () async {
      final mockAdapter = MockReviewsHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = ProductRepository(dio);
      final res = await repo.getPaginatedProductReviews('p-1', page: 1, limit: 20);

      expect(res.items.length, 1);
      expect(res.items.first.id, 'rev-1');
      expect(mockAdapter.requests.first.queryParameters, {'page': 1, 'limit': 20});
    });

    test('4. ProductRepository createProductReview sends rating, title, and comment', () async {
      final mockAdapter = MockReviewsHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = ProductRepository(dio);
      final review = await repo.createProductReview(
        'p-1',
        rating: 5,
        title: 'Awesome Item',
        comment: 'Really loved this product!',
      );

      expect(review.id, 'rev-200');
      expect(mockAdapter.requests.last.method, 'POST');
      expect(mockAdapter.requests.last.body, {
        'rating': 5,
        'title': 'Awesome Item',
        'comment': 'Really loved this product!',
      });
    });

    test('5. ProductRepository updateProductReview sends PATCH to /reviews/:reviewId', () async {
      final mockAdapter = MockReviewsHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = ProductRepository(dio);
      final review = await repo.updateProductReview(
        'p-1',
        'rev-1',
        rating: 4,
        title: 'Updated Review',
        comment: 'Edited comment.',
      );

      expect(review.rating, 4);
      expect(mockAdapter.requests.last.method, 'PATCH');
      expect(mockAdapter.requests.last.path, contains('/products/p-1/reviews/rev-1'));
    });

    test('6. ProductRepository deleteProductReview sends DELETE to /reviews/:reviewId', () async {
      final mockAdapter = MockReviewsHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = ProductRepository(dio);
      await repo.deleteProductReview('p-1', 'rev-1');

      expect(mockAdapter.requests.last.method, 'DELETE');
      expect(mockAdapter.requests.last.path, contains('/products/p-1/reviews/rev-1'));
    });

    test('7. ProductReviewsController handles 403 PRODUCT_PURCHASE_REQUIRED error', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter()..purchaseRequiredError = true;
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

      container.listen(productReviewsControllerProvider('p-1'), (_, _) {});

      await container.read(productReviewsControllerProvider('p-1').future);

      expect(
        () async => await container.read(productReviewsControllerProvider('p-1').notifier).submitReview(
              rating: 5,
              comment: 'Great tee!',
            ),
        throwsA(isA<DioException>()),
      );
    });

    test('8. ProductReviewsController handles 409 REVIEW_ALREADY_EXISTS error', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter()..alreadyReviewedError = true;
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

      container.listen(productReviewsControllerProvider('p-1'), (_, _) {});

      await container.read(productReviewsControllerProvider('p-1').future);

      expect(
        () async => await container.read(productReviewsControllerProvider('p-1').notifier).submitReview(
              rating: 5,
              comment: 'Great tee!',
            ),
        throwsA(isA<DioException>()),
      );
    });

    testWidgets('9. ProductDetailsScreen renders real review DTO fields (user.name, title, comment, rating)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter();

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
          child: const MaterialApp(home: ProductDetailsScreen(product: product)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll down and Tap Reviews Tab
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.textContaining('Reviews').first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Customer One'), findsWidgets);
      expect(find.text('Great Quality!'), findsOneWidget);
      expect(find.text('Super soft cotton shirt.'), findsOneWidget);
    });

    test('10. Rapid duplicate submitReview calls trigger exactly 1 POST request', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final completer = Completer<void>();
      final mockAdapter = MockReviewsHttpAdapter()..postCompleter = completer;
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

      container.listen(productReviewsControllerProvider('p-1'), (_, _) {});

      await container.read(productReviewsControllerProvider('p-1').future);

      // Rapid calls
      final f1 = container.read(productReviewsControllerProvider('p-1').notifier).submitReview(rating: 5, comment: 'Nice!');
      final f2 = container.read(productReviewsControllerProvider('p-1').notifier).submitReview(rating: 5, comment: 'Nice!');

      completer.complete();
      await Future.wait([f1, f2]);

      final postRequests = mockAdapter.requests.where((r) => r.method == 'POST' && r.path.contains('/reviews')).length;
      expect(postRequests, 1);
    });

    test('11. Delayed GET from old product session cannot overwrite current product reviews', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter();
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

      container.listen(productReviewsControllerProvider('p-1'), (_, _) {});

      final stateP1 = await container.read(productReviewsControllerProvider('p-1').future);
      expect(stateP1.items.first.id, 'rev-1');
    });

    testWidgets('12. Failed GET displays Error UI and Retry button in AllReviewsScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter()..shouldFail = true;

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
          child: const MaterialApp(home: AllReviewsScreen(product: product)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load reviews'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      mockAdapter.shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Great Quality!'), findsOneWidget);
    });

    test('13. Successful review mutation re-fetches review list and rating summary', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter();
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

      container.listen(productReviewsControllerProvider('p-1'), (_, _) {});

      await container.read(productReviewsControllerProvider('p-1').future);

      await container.read(productReviewsControllerProvider('p-1').notifier).submitReview(
            rating: 5,
            title: 'Awesome',
            comment: 'Great quality!',
          );

      final summaryReqs = mockAdapter.requests.where((r) => r.path.contains('/reviews/summary')).length;
      expect(summaryReqs, greaterThanOrEqualTo(2));
    });

    test('14. Unauthenticated user submitReview returns without sending HTTP request', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter();
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

      container.listen(productReviewsControllerProvider('p-1'), (_, _) {});

      await Future.microtask(() {});

      final reqCount = mockAdapter.requests.length;

      await container.read(productReviewsControllerProvider('p-1').notifier).submitReview(
            rating: 5,
            comment: 'Test comment',
          );

      expect(mockAdapter.requests.length, reqCount); // Zero extra requests
    });

    test('15. ProductReviewModel.fromJson throws FormatException when rating or createdAt is missing', () {
      final jsonNoRating = {
        'id': 'rev-1',
        'createdAt': '2026-03-01T10:00:00.000Z',
      };
      expect(() => ProductReviewModel.fromJson(jsonNoRating), throwsA(isA<FormatException>()));

      final jsonNoCreatedAt = {
        'id': 'rev-1',
        'rating': 5,
      };
      expect(() => ProductReviewModel.fromJson(jsonNoCreatedAt), throwsA(isA<FormatException>()));
    });

    testWidgets('16. Edit review button is shown for review owner and opens edit modal', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter();

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
          child: const MaterialApp(home: AllReviewsScreen(product: product)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Review'), findsOneWidget);
    });

    test('17. Unauthenticated user gets public product reviews with currentUser == null', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockReviewsHttpAdapter();
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

      container.listen(productReviewsControllerProvider('p-1'), (_, _) {});

      await container.read(productReviewsControllerProvider('p-1').future);

      // Logout
      authNotifier.setToken(null);
      fakeUserNotifier.user = null;
      container.invalidate(currentUserProvider);
      await Future.microtask(() {});

      final state = await container.read(productReviewsControllerProvider('p-1').future);
      expect(state.items.length, 1);
      final currentUser = container.read(currentUserProvider).value;
      expect(currentUser, isNull);
    });
  });
}
