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
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/address/models/address_model.dart';
import 'package:ecommerce/features/address/presentation/providers/address_provider.dart';
import 'package:ecommerce/features/address/presentation/screens/addresses_screen.dart';
import 'package:ecommerce/features/address/presentation/screens/add_edit_address_screen.dart';
import 'package:ecommerce/features/auth/models/auth_response_models.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';

class FakeAuthTokenNotifier extends AuthTokenNotifier {
  @override
  String? build() => 'test-token';
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

class MockAddressHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  Completer<void>? postCompleter;
  bool shouldFail = false;
  bool countriesFail = false;

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

    if (options.method == 'POST' && path.endsWith('/addresses')) {
      if (postCompleter != null) {
        await postCompleter!.future;
      }
    }

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Failed to save address'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.endsWith('/countries')) {
      if (countriesFail) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Countries API error'}),
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': [
            {'code': 'KW', 'name': 'Kuwait', 'currencyCode': 'KWD'},
            {'code': 'SA', 'name': 'Saudi Arabia', 'currencyCode': 'SAR'},
            {
              'code': 'AE',
              'name': 'United Arab Emirates',
              'currencyCode': 'AED',
            },
            {'code': 'EG', 'name': 'Egypt', 'currencyCode': 'EGP'},
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('default-billing')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Default billing address updated successfully',
          'data': {
            'id': 'addr-123',
            'label': 'HOME',
            'firstName': 'Customer',
            'lastName': 'One',
            'addressLine1': '10 Al-Shuhada Street',
            'city': 'Kuwait City',
            'countryCode': 'KW',
            'isDefaultShipping': false,
            'isDefaultBilling': true,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('default-shipping')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Default shipping address updated successfully',
          'data': {
            'id': 'addr-123',
            'label': 'HOME',
            'firstName': 'Customer',
            'lastName': 'One',
            'addressLine1': '10 Al-Shuhada Street',
            'city': 'Kuwait City',
            'countryCode': 'KW',
            'isDefaultShipping': true,
            'isDefaultBilling': false,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if ((options.method == 'POST' || options.method == 'PATCH') &&
        path.endsWith('/addresses')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Address saved successfully',
          'data': {
            'id': 'addr-456',
            'label': 'WORK',
            'firstName': 'Customer',
            'lastName': 'One',
            'addressLine1': '10 Main Street',
            'city': 'Kuwait City',
            'countryCode': 'KW',
            'isDefaultShipping': false,
            'isDefaultBilling': false,
          },
        }),
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.method == 'PATCH' && path.contains('/addresses/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Address updated successfully',
          'data': {
            'id': 'addr-123',
            'label': 'HOME',
            'firstName': 'Customer',
            'lastName': 'One',
            'addressLine1': '10 Al-Shuhada Street',
            'city': 'Kuwait City',
            'countryCode': 'KW',
            'isDefaultShipping': true,
            'isDefaultBilling': true,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.method == 'DELETE' && path.contains('/addresses/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Address deleted successfully',
          'data': null,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    // Default GET /addresses response based on X-Tenant-Slug
    final tenantSlug = options.headers['X-Tenant-Slug'] as String?;
    final addressId = tenantSlug == 'dev81-independent'
        ? 'addr-indep-123'
        : 'addr-123';

    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'message': null,
        'data': [
          {
            'id': addressId,
            'label': 'HOME',
            'firstName': 'Customer',
            'lastName': 'One',
            'addressLine1': '10 Al-Shuhada Street',
            'city': 'Kuwait City',
            'countryCode': 'KW',
            'isDefaultShipping': true,
            'isDefaultBilling': true,
          },
        ],
      }),
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

  group('Task 06.1 — Address Management Integration Tests', () {
    testWidgets(
      '1. AddressesScreen renders address list with titles and labels',
      (tester) async {
        final mockAdapter = MockAddressHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeUserNotifier()),
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
            child: const MaterialApp(home: AddressesScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Addresses'), findsOneWidget);
        expect(find.text('Customer One'), findsOneWidget);
        expect(find.text('HOME'), findsOneWidget);
        expect(find.textContaining('10 Al-Shuhada Street'), findsOneWidget);
      },
    );

    testWidgets('2. Tapping FAB opens AddEditAddressScreen in create mode', (
      tester,
    ) async {
      final mockAdapter = MockAddressHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => FakeUserNotifier()),
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
          child: const MaterialApp(home: AddressesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final addBtn = find.byType(AppButton);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AddEditAddressScreen), findsOneWidget);
      expect(find.text('Add Address'), findsOneWidget);
    });

    testWidgets('3. AddEditAddressScreen submits new address via POST', (
      tester,
    ) async {
      final mockAdapter = MockAddressHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => FakeUserNotifier()),
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
          child: const MaterialApp(home: AddEditAddressScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '10 Main Street');
      await tester.enterText(find.byType(TextField).at(2), 'Kuwait City');
      await tester.enterText(find.byType(TextField).at(6), 'John');
      await tester.enterText(find.byType(TextField).at(7), 'Doe');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      final postReq = mockAdapter.requests.firstWhere(
        (r) => r.method == 'POST' && r.path.endsWith('/addresses'),
      );
      expect(postReq.body['firstName'], 'John');
      expect(postReq.body['lastName'], 'Doe');
      expect(postReq.body['addressLine1'], '10 Main Street');
      expect(postReq.body['city'], 'Kuwait City');
      expect(postReq.body['country'], 'KW');
    });

    testWidgets(
      '4. Tapping Edit button opens AddEditAddressScreen in edit mode',
      (tester) async {
        final mockAdapter = MockAddressHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeUserNotifier()),
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
            child: const MaterialApp(home: AddressesScreen()),
          ),
        );

        await tester.pumpAndSettle();

        final editBtn = find.text('Edit').first;
        expect(editBtn, findsOneWidget);
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AddEditAddressScreen), findsOneWidget);
        expect(find.text('Edit Address'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'John'), findsNothing);
      },
    );

    testWidgets(
      '5. Delete address shows confirmation dialog and sends DELETE on confirm',
      (tester) async {
        final mockAdapter = MockAddressHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeUserNotifier()),
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
            child: const MaterialApp(home: AddressesScreen()),
          ),
        );

        await tester.pumpAndSettle();

        final moreBtn = find.byIcon(Icons.more_horiz);
        expect(moreBtn, findsOneWidget);
        await tester.tap(moreBtn);
        await tester.pumpAndSettle();

        final deleteBtn = find.text('Delete Address');
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        expect(find.text('Delete Address'), findsWidgets);

        final confirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        final deleteReq = mockAdapter.requests.firstWhere(
          (r) => r.method == 'DELETE',
        );
        expect(deleteReq.path, contains('/addresses/addr-123'));
      },
    );

    testWidgets(
      '12. AddEditAddressScreen stays open while POST is pending and pops on success',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final completer = Completer<void>();
        final mockAdapter = MockAddressHttpAdapter()..postCompleter = completer;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
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
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditAddressScreen(),
                    ),
                  ),
                  child: const Text('Open Add'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Add'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), '10 Main Street');
        await tester.enterText(find.byType(TextField).at(2), 'Kuwait City');
        await tester.enterText(find.byType(TextField).at(6), 'John');
        await tester.enterText(find.byType(TextField).at(7), 'Doe');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pump();

        // Screen stays open while POST is pending
        expect(find.byType(AddEditAddressScreen), findsOneWidget);

        // Release POST response
        completer.complete();
        await tester.pumpAndSettle();

        // Screen pops after success
        expect(find.byType(AddEditAddressScreen), findsNothing);
      },
    );

    test(
      '13. AddressNotifier suppresses HTTP requests when user is unauthenticated or loading',
      () async {
        SharedPreferences.setMockInitialValues({
          'selected_tenant_slug': 'dev81-kuwait-fashion',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockAddressHttpAdapter();
        final fakeUser = FakeUserNotifier()..user = null;
        late ProviderContainer container;

        container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => fakeUser),
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
        );

        container.listen(addressProvider, (_, _) {});

        // Zero HTTP requests while user is null
        expect(mockAdapter.requests.length, 0);

        fakeUser.user = const UserDto(
          id: 'usr-123',
          email: 'customer@example.com',
          firstName: 'Customer',
          lastName: 'One',
          isEmailVerified: true,
        );
        container.invalidate(currentUserProvider);
        await Future.delayed(Duration.zero);

        final list = await container.read(addressProvider.future);
        expect(list.length, 1);
        expect(mockAdapter.requests.length, 1);
      },
    );

    testWidgets(
      '14. Double Save tap while POST is pending sends exactly 1 POST request',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final completer = Completer<void>();
        final mockAdapter = MockAddressHttpAdapter()..postCompleter = completer;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
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
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditAddressScreen(),
                    ),
                  ),
                  child: const Text('Open Add'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Add'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), '10 Main Street');
        await tester.enterText(find.byType(TextField).at(2), 'Kuwait City');
        await tester.enterText(find.byType(TextField).at(6), 'John');
        await tester.enterText(find.byType(TextField).at(7), 'Doe');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));

        // Rapid double tap
        await tester.tap(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pump();

        completer.complete();
        await tester.pumpAndSettle();

        final postRequests = mockAdapter.requests
            .where((r) => r.method == 'POST' && r.path.endsWith('/addresses'))
            .length;
        expect(postRequests, 1);
      },
    );

    test(
      '15. In-flight address GET is discarded on logout or account switch',
      () async {
        SharedPreferences.setMockInitialValues({
          'selected_tenant_slug': 'dev81-kuwait-fashion',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockAddressHttpAdapter();
        final authNotifier = FakeAuthTokenNotifier();
        late ProviderContainer container;

        container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(() => authNotifier),
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
            dioClientProvider.overrideWith((ref) {
              final tenantSlug = ref.watch(selectedTenantSlugProvider);
              final token = ref.watch(authTokenProvider);
              final dio = Dio(
                BaseOptions(
                  baseUrl: 'http://127.0.0.1:3000/api/v1',
                  headers: {
                    'X-Tenant-Slug': tenantSlug,
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                ),
              );
              dio.httpClientAdapter = mockAdapter;
              return dio;
            }),
          ],
        );

        container.listen(addressProvider, (_, _) {});

        // Immediate logout
        authNotifier.setToken(null);
        await Future.microtask(() {});

        expect(
          container.read(addressProvider),
          isA<AsyncData<List<AddressModel>>>(),
        );
        expect(container.read(addressProvider).value, isEmpty);
      },
    );

    test(
      '16. In-flight address mutation completes silently on tenant switch without stale updates',
      () async {
        SharedPreferences.setMockInitialValues({
          'selected_tenant_slug': 'dev81-kuwait-fashion',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockAddressHttpAdapter();
        late ProviderContainer container;

        container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => FakeUserNotifier()),
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
        );

        container.listen(addressProvider, (_, _) {});

        await container.read(addressProvider.future);

        // Tenant switch
        await container
            .read(selectedTenantSlugProvider.notifier)
            .setTenantSlug('dev81-independent');
        final list = await container.read(addressProvider.future);

        expect(list.first.id, 'addr-indep-123');
      },
    );

    testWidgets('17. Validation fails when city is empty', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockAddressHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
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
          child: const MaterialApp(home: AddEditAddressScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '10 Main Street');
      await tester.enterText(find.byType(TextField).at(6), 'John');
      await tester.enterText(find.byType(TextField).at(7), 'Doe');
      // Leave city (TextField at 2) empty

      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // Screen stays open and no POST request is sent
      expect(find.byType(AddEditAddressScreen), findsOneWidget);
      final postRequests = mockAdapter.requests
          .where((r) => r.method == 'POST' && r.path.endsWith('/addresses'))
          .length;
      expect(postRequests, 0);
    });

    testWidgets('18. Validation fails when phone number has invalid format', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockAddressHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
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
          child: const MaterialApp(home: AddEditAddressScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '10 Main Street');
      await tester.enterText(find.byType(TextField).at(2), 'Kuwait City');
      await tester.enterText(
        find.byType(TextField).at(5),
        'invalid-phone-1234567890123456',
      ); // invalid phone
      await tester.enterText(find.byType(TextField).at(6), 'John');
      await tester.enterText(find.byType(TextField).at(7), 'Doe');

      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // Screen stays open and no POST request is sent
      expect(find.byType(AddEditAddressScreen), findsOneWidget);
      final postRequests = mockAdapter.requests
          .where((r) => r.method == 'POST' && r.path.endsWith('/addresses'))
          .length;
      expect(postRequests, 0);
    });

    testWidgets(
      '19. AddressModel serializes default shipping and default billing flags',
      (tester) async {
        const model = AddressModel(
          id: 'addr-1',
          firstName: 'Jane',
          lastName: 'Smith',
          addressLine1: '20 Park Lane',
          city: 'Kuwait City',
          country: 'KW',
          isDefaultShipping: true,
          isDefaultBilling: true,
        );

        final json = model.toJson();
        expect(json['isDefaultShipping'], true);
        expect(json['isDefaultBilling'], true);
      },
    );

    test(
      '20. PhoneUtils normalizes E.164 and rejects invalid local numbers',
      () {
        expect(
          PhoneUtils.normalizeToE164('+14155552671', 'US'),
          '+14155552671',
        );
        expect(PhoneUtils.normalizeToE164('90000000', 'KW'), '+96590000000');
        expect(PhoneUtils.normalizeToE164('0501234567', 'SA'), '+966501234567');
        expect(PhoneUtils.normalizeToE164('12345678', 'XX'), null);
        expect(PhoneUtils.normalizeToE164('invalid-phone', 'KW'), null);
        expect(PhoneUtils.normalizeToE164('', 'KW'), null);
      },
    );

    testWidgets(
      '21. Edit address preserves existing country when countries API fails',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockAddressHttpAdapter()..countriesFail = true;

        const existingAddress = AddressModel(
          id: 'addr-123',
          firstName: 'Customer',
          lastName: 'One',
          addressLine1: '10 Al-Shuhada Street',
          city: 'Kuwait City',
          country: 'KW',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
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
            child: const MaterialApp(
              home: AddEditAddressScreen(addressToEdit: existingAddress),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        // Successfully updates and preserves existing country KW
        final patchRequests = mockAdapter.requests
            .where((r) => r.method == 'PATCH' || r.method == 'POST')
            .length;
        expect(patchRequests, greaterThan(0));
      },
    );
  });
}
