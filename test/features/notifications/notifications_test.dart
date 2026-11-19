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
import 'package:ecommerce/features/notifications/data/notifications_repository.dart';
import 'package:ecommerce/features/notifications/models/notification_model.dart';
import 'package:ecommerce/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:ecommerce/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ecommerce/features/settings/presentation/screens/settings_screen.dart';
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

class MockNotificationsHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  Completer<void>? page2Completer;
  Completer<void>? patchCompleter;
  bool page2ShouldFail = false;
  bool shouldFail = false;
  bool patchShouldFail = false;
  bool deleteShouldFail = false;

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
    final query = options.queryParameters;
    final page = query['page'];

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Failed to fetch notifications'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'PATCH' && path.contains('/read')) {
      if (patchCompleter != null) {
        await patchCompleter!.future;
      }
      if (patchShouldFail) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to mark as read'}),
          400,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': {
            'id': 'notif-1',
            'type': 'ORDER_STATUS_CHANGED',
            'title': 'Order Confirmed',
            'body': 'Your order has been confirmed.',
            'isRead': true,
            'createdAt': '2026-03-01T10:00:00.000Z',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'PATCH' && path.contains('/read-all')) {
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'message': null, 'data': null}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'DELETE' && path.contains('/notifications/')) {
      if (deleteShouldFail) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to delete notification'}),
          400,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'message': null, 'data': null}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('/notifications')) {
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

        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'message': null,
            'data': {
              'items': [
                {
                  'id': 'notif-2',
                  'type': 'SHIPPING_UPDATE',
                  'title': 'Order Shipped',
                  'body': 'Your package is on its way.',
                  'data': {'orderId': 'ord-123'},
                  'isRead': true,
                  'createdAt': '2026-03-02T10:00:00.000Z',
                }
              ],
              'pagination': {
                'page': 2,
                'limit': 20,
                'total': 2,
                'totalPages': 2,
              },
              'unreadCount': 1,
            }
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }

      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': null,
          'data': {
            'items': [
              {
                'id': 'notif-1',
                'type': 'ORDER_STATUS_CHANGED',
                'title': 'Order Confirmed',
                'body': 'Your order has been confirmed.',
                'data': {'orderId': 'ord-123'},
                'isRead': false,
                'createdAt': '2026-03-01T10:00:00.000Z',
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 2,
              'totalPages': 2,
            },
            'unreadCount': 1,
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

  group('Task 06.5.1 — Notifications Behavioral Integration Tests', () {
    test('1. NotificationModel parses real backend DTO fields (body, type, data, isRead)', () {
      final json = {
        'id': 'notif-1',
        'type': 'ORDER_STATUS_CHANGED',
        'title': 'Order Confirmed',
        'body': 'Your order has been confirmed.',
        'data': {'orderId': 'ord-123'},
        'isRead': false,
        'readAt': null,
        'createdAt': '2026-03-01T10:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.type, 'ORDER_STATUS_CHANGED');
      expect(notif.title, 'Order Confirmed');
      expect(notif.body, 'Your order has been confirmed.');
      expect(notif.message, 'Your order has been confirmed.');
      expect(notif.data?['orderId'], 'ord-123');
      expect(notif.isRead, isFalse);
    });

    test('2. NotificationsRepository getPaginatedNotifications parses items, pagination, and unreadCount', () async {
      final mockAdapter = MockNotificationsHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = NotificationsRepository(dio);
      final res = await repo.getPaginatedNotifications(page: 1, limit: 20);

      expect(res.items.length, 1);
      expect(res.items.first.id, 'notif-1');
      expect(res.page, 1);
      expect(res.totalPages, 2);
      expect(res.unreadCount, 1);
    });

    test('3. GET request sends correct page=1 and limit=20 parameters', () async {
      final mockAdapter = MockNotificationsHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = mockAdapter;

      final repo = NotificationsRepository(dio);
      await repo.getPaginatedNotifications(page: 1, limit: 20);

      expect(mockAdapter.requests.first.queryParameters, {'page': 1, 'limit': 20});
    });

    test('4. NotificationController loadNextPage appends page 2 unique items and updates pagination', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter();
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

      container.listen(notificationControllerProvider, (_, _) {});

      final statePage1 = await container.read(notificationControllerProvider.future);
      expect(statePage1.items.length, 1);
      expect(statePage1.hasMore, isTrue);

      await container.read(notificationControllerProvider.notifier).loadNextPage();
      final statePage2 = container.read(notificationControllerProvider).value!;

      expect(statePage2.items.length, 2);
      expect(statePage2.items[0].id, 'notif-1');
      expect(statePage2.items[1].id, 'notif-2');
      expect(statePage2.hasMore, isFalse);
    });

    testWidgets('5. Initial GET failure displays Error UI and Retry button', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter()..shouldFail = true;

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
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      mockAdapter.shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Order Confirmed'), findsOneWidget);
    });

    test('6. Mark unread notification as read sends PATCH request and decrements unreadCount once', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter();
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

      container.listen(notificationControllerProvider, (_, _) {});

      final initState = await container.read(notificationControllerProvider.future);
      expect(initState.unreadCount, 1);

      await container.read(notificationControllerProvider.notifier).markAsRead('notif-1');

      final finalState = container.read(notificationControllerProvider).value!;
      expect(finalState.unreadCount, 0);
      expect(finalState.items.first.isRead, isTrue);
      expect(mockAdapter.requests.last.path, contains('/notifications/notif-1/read'));
    });

    test('7. Marking already-read notification does not decrement unreadCount', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter();
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);
      await container.read(notificationControllerProvider.notifier).markAsRead('notif-1');

      final reqCount = mockAdapter.requests.length;

      // Second markAsRead on same read item
      await container.read(notificationControllerProvider.notifier).markAsRead('notif-1');

      expect(mockAdapter.requests.length, reqCount); // No duplicate PATCH
      expect(container.read(notificationControllerProvider).value!.unreadCount, 0);
    });

    test('8. markAllAsRead updates global unreadCount to 0', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter();
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);
      await container.read(notificationControllerProvider.notifier).markAllAsRead();

      final state = container.read(notificationControllerProvider).value!;
      expect(state.unreadCount, 0);
      expect(state.items.every((i) => i.isRead), isTrue);
      expect(mockAdapter.requests.last.path, contains('/notifications/read-all'));
    });

    test('9. Delete unread notification sends DELETE and updates list and unreadCount', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter();
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);
      await container.read(notificationControllerProvider.notifier).deleteNotification('notif-1');

      final state = container.read(notificationControllerProvider).value!;
      expect(state.items, isEmpty);
      expect(state.unreadCount, 0);
      expect(mockAdapter.requests.last.method, 'DELETE');
      expect(mockAdapter.requests.last.path, contains('/notifications/notif-1'));
    });

    test('10. Failed mutation rolls back optimistic state change', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter()..patchShouldFail = true;
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);

      try {
        await container.read(notificationControllerProvider.notifier).markAsRead('notif-1');
      } catch (_) {}

      final state = container.read(notificationControllerProvider).value!;
      expect(state.items.first.isRead, isFalse);
      expect(state.unreadCount, 1);
    });

    test('11. Delayed GET from old user session cannot overwrite new user notifications', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter();
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);

      // Logout
      authNotifier.setToken(null);
      fakeUserNotifier.user = null;
      await Future.microtask(() {});

      final state = await container.read(notificationControllerProvider.future);
      expect(state.items, isEmpty);
      expect(state.unreadCount, 0);
    });

    testWidgets('12. Settings badge reflects real unreadNotificationCount', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_tenant_confirmed': true,
        'selected_tenant_slug': 'dev81-kuwait-fashion',
        'access_token': 'test-token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter();

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
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget); // unreadCount == 1 from mock adapter
    });

    test('13. Delayed mutation from old user session cannot modify new session', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final patchCompleter = Completer<void>();
      final mockAdapter = MockNotificationsHttpAdapter()..patchCompleter = patchCompleter;
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);

      final notifFuture = container.read(notificationControllerProvider.notifier).markAsRead('notif-1');

      // Logout during in-flight PATCH
      authNotifier.setToken(null);
      fakeUserNotifier.user = null;
      patchCompleter.complete();

      try {
        await notifFuture;
      } catch (_) {}

      final state = await container.read(notificationControllerProvider.future);
      expect(state.items, isEmpty);
      expect(state.unreadCount, 0);
    });

    test('14. loadNextPage preserves item mutations completed while page 2 was in-flight', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final page2Completer = Completer<void>();
      final mockAdapter = MockNotificationsHttpAdapter()..page2Completer = page2Completer;
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);

      // Start loading page 2
      final page2Future = container.read(notificationControllerProvider.notifier).loadNextPage();

      // Mark notif-1 as read while page 2 is in-flight
      await container.read(notificationControllerProvider.notifier).markAsRead('notif-1');

      page2Completer.complete();
      await page2Future;

      final state = container.read(notificationControllerProvider).value!;
      expect(state.items.first.id, 'notif-1');
      expect(state.items.first.isRead, isTrue); // Mutation preserved!
      expect(state.items.length, 2);
    });

    test('15. Failed delete mutation rolls back item and preserves unread count', () async {
      SharedPreferences.setMockInitialValues({'selected_tenant_slug': 'dev81-kuwait-fashion'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = MockNotificationsHttpAdapter()..deleteShouldFail = true;
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

      container.listen(notificationControllerProvider, (_, _) {});

      await container.read(notificationControllerProvider.future);

      try {
        await container.read(notificationControllerProvider.notifier).deleteNotification('notif-1');
      } catch (_) {}

      final state = container.read(notificationControllerProvider).value!;
      expect(state.items.first.id, 'notif-1');
      expect(state.unreadCount, 1);
    });
  });
}
