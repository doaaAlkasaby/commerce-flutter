import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/categories/data/categories_repository.dart';
import 'package:ecommerce/features/home/presentation/widgets/product_card.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/presentation/screens/product_list_screen.dart';
import 'package:ecommerce/main.dart';

class ProductCatalogMockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('categories/active')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': [
            {
              'id': 'cat-1',
              'name': 'Footwear',
              'imageUrl': '/uploads/development-v82/fashion/shoes-front.webp',
              'hasChildren': false,
            },
          ]
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('products/p-100')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'p-100',
            'name': 'Leather Running Shoes',
            'slug': 'leather-running-shoes',
            'description': 'High performance running shoes',
            'price': {
              'original': 120.0,
              'final': 99.0,
              'discountPercentage': 17.5,
            },
            'image': '/uploads/development-v82/fashion/shoes-front.webp',
            'images': [
              {
                'id': 'img-1',
                'url': '/uploads/development-v82/fashion/shoes-front.webp',
                'altText': 'Shoes Front',
                'isPrimary': true,
              }
            ],
            'rating': {'average': 4.7, 'count': 42},
            'isInWishlist': false,
            'hasVariants': false,
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('products')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'products': [
              {
                'id': 'p-100',
                'name': 'Leather Running Shoes',
                'slug': 'leather-running-shoes',
                'price': {
                  'original': 120.0,
                  'final': 99.0,
                },
                'image': '/uploads/development-v82/fashion/shoes-front.webp',
                'rating': {'average': 4.7, 'count': 42},
                'isInWishlist': false,
                'hasVariants': false,
              }
            ]
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

class ErrorProductCatalogMockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'message': 'Internal Server Error'}),
      500,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

class EmptyProductCatalogMockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

class ControllablePaginationMockAdapter implements HttpClientAdapter {
  bool page1Fails = false;
  bool page2Fails = false;
  int fetchCallCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCallCount++;
    final rawPage = options.queryParameters['page'];
    final page = rawPage is int ? rawPage : (int.tryParse(rawPage?.toString() ?? '1') ?? 1);

    if (page == 1 && page1Fails) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Page 1 Error'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (page == 2 && page2Fails) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Page 2 Error'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (page == 1) {
      final pList = List.generate(
        10,
        (i) => {
          'id': 'prod-$i',
          'name': 'Product $i',
          'slug': 'product-$i',
          'price': {'original': 100.0, 'final': 80.0},
          'image': 'https://example.com/p$i.png',
          'isInWishlist': false,
          'hasVariants': false,
        },
      );
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'products': pList,
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (page == 2) {
      final pList = List.generate(
        5,
        (i) => {
          'id': 'prod-${i + 10}',
          'name': 'Product ${i + 10}',
          'slug': 'product-${i + 10}',
          'price': {'original': 100.0, 'final': 80.0},
          'image': 'https://example.com/p${i + 10}.png',
          'isInWishlist': false,
          'hasVariants': false,
        },
      );
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'products': pList,
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': {'products': []}}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppEnvironment.resolveImageUrl Unit Tests', () {
    test('Absolute HTTP/HTTPS URLs are preserved as-is', () {
      const absUrl = 'https://example.com/images/shoe.jpg';
      expect(AppEnvironment.resolveImageUrl(absUrl), absUrl);
    });

    test('Relative /uploads/... paths are resolved against server origin', () {
      const relPath = '/uploads/development-v82/fashion/shoes-front.webp';
      final resolved = AppEnvironment.resolveImageUrl(relPath);

      final origin = Uri.parse(AppEnvironment.baseUrl).origin;
      expect(resolved, '$origin$relPath');
      expect(resolved.contains('/api/v1'), isFalse);
    });

    test('Null or empty image URLs return empty string', () {
      expect(AppEnvironment.resolveImageUrl(null), '');
      expect(AppEnvironment.resolveImageUrl('   '), '');
    });
  });

  group('Product & Category Catalog Integration Tests', () {
    test('CategoriesRepository fetches active categories and resolves relative image URLs', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ProductCatalogMockAdapter();
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

      final categoriesRepo = CategoriesRepository(container.read(dioClientProvider));
      final categories = await categoriesRepo.getMainCategories();

      expect(categories.length, 1);
      expect(categories.first.name, 'Footwear');
      expect(categories.first.imageUrl.startsWith('http://127.0.0.1:3000/uploads/'), isTrue);

      container.dispose();
    });

    test('ProductRepository fetches product details and resolves relative image URLs', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ProductCatalogMockAdapter();
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

      final productRepo = ProductRepository(container.read(dioClientProvider));
      final details = await productRepo.getProductDetails('p-100');

      expect(details.id, 'p-100');
      expect(details.name, 'Leather Running Shoes');
      expect(details.priceInfo.finalPrice, 99.0);
      expect(details.image.startsWith('http://127.0.0.1:3000/uploads/'), isTrue);

      container.dispose();
    });

    test('ProductRepository getProductsByEndpoint returns products without mock fallbacks', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ProductCatalogMockAdapter();
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

      final productRepo = ProductRepository(container.read(dioClientProvider));
      final products = await productRepo.getProductsByEndpoint('/products?categoryId=cat-1');

      expect(products.length, 1);
      expect(products.first.name, 'Leather Running Shoes');

      container.dispose();
    });

    test('ProductRepository rethrows DioException on HTTP 500 server error instead of swallowing', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = ErrorProductCatalogMockAdapter();

      final productRepo = ProductRepository(dio);

      expect(
        () async => await productRepo.getProductsByEndpoint('/products'),
        throwsA(isA<DioException>()),
      );
    });

    test('ProductRepository returns empty list on successful 200 response with empty data', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = EmptyProductCatalogMockAdapter();

      final productRepo = ProductRepository(dio);
      final products = await productRepo.getProductsByEndpoint('/products');

      expect(products, isEmpty);
    });

    test('CategoriesRepository rethrows DioException on HTTP 500 server error', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = ErrorProductCatalogMockAdapter();

      final categoriesRepo = CategoriesRepository(dio);

      expect(
        () async => await categoriesRepo.getMainCategories(),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('ProductListScreen Widget & Pagination Tests', () {
    testWidgets('Page 1 failure shows error view and Retry button reloads products', (tester) async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ControllablePaginationMockAdapter()..page1Fails = true;

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
            home: ProductListScreen(title: 'Footwear', endpoint: '/products'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error view with Retry button is displayed
      expect(find.text('Failed to load products. Please check network connection.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      // Fix Page 1 error and tap Retry
      mockAdapter.page1Fails = false;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      // Assert Page 1 products are now loaded
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('Page 2 pagination failure preserves Page 1 products and shows inline Retry button', (tester) async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ControllablePaginationMockAdapter()..page2Fails = true;

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
            home: ProductListScreen(title: 'Footwear', endpoint: '/products'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger Page 2 fetch and scroll until error item is visible
      await tester.scrollUntilVisible(
        find.text('Failed to load more'),
        200,
        scrollable: find.byType(Scrollable),
      );

      // Assert inline pagination error button is shown and Page 1 product cards remain
      expect(find.text('Failed to load more'), findsOneWidget);
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('Inline Retry reloads Page 2 and appends items without duplicates', (tester) async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ControllablePaginationMockAdapter()..page2Fails = true;

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
            home: ProductListScreen(title: 'Footwear', endpoint: '/products'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger Page 2 error and scroll until error item is visible
      await tester.scrollUntilVisible(
        find.text('Failed to load more'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Failed to load more'), findsOneWidget);

      // Fix Page 2 error and tap inline Retry button
      mockAdapter.page2Fails = false;
      await tester.tap(find.widgetWithIcon(IconButton, Icons.refresh));
      await tester.pumpAndSettle();

      // Scroll to bottom to view appended Page 2 product
      await tester.scrollUntilVisible(
        find.text('Product 10'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Product 10'), findsOneWidget);
    });

    testWidgets('Tenant switch clears previous tenant products and fetches new tenant products', (tester) async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ControllablePaginationMockAdapter();
      late ProviderContainer container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
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
          ),
          child: const MaterialApp(
            home: ProductListScreen(title: 'Footwear', endpoint: '/products'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsWidgets);

      // Switch tenant
      await container.read(selectedTenantSlugProvider.notifier).setTenantSlug('dev81-independent');
      await tester.pumpAndSettle();

      // Assert products reloaded for new tenant
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('Changing endpoint resets ProductListScreen state and fetches new listing', (tester) async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = ControllablePaginationMockAdapter();

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
            home: ProductListScreen(title: 'Footwear', endpoint: '/products?categoryId=cat-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsWidgets);

      // Re-pump with new endpoint
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
            home: ProductListScreen(title: 'Clothing', endpoint: '/products?categoryId=cat-2'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Clothing'), findsOneWidget);
    });
  });
}
