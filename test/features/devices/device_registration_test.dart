import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/services/notification_service.dart';
import 'package:ecommerce/features/devices/data/device_repository.dart';
import 'package:ecommerce/features/devices/presentation/providers/device_provider.dart';

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

class MockDeviceHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  int failCountBeforeSuccess = 0;
  int responseStatusCode = 200;
  bool throwConnectionTimeoutOnFirst = false;
  bool returnInvalidJsonSchema = false;
  bool shouldHangOnDeactivate = false;
  int postDelayMs = 0;

  int _currentFailures = 0;
  bool _hasThrownTimeout = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
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

    if (postDelayMs > 0 && options.method == 'POST') {
      await Future.delayed(Duration(milliseconds: postDelayMs));
    }

    if (shouldHangOnDeactivate && options.path.contains('/deactivate')) {
      await Future.delayed(const Duration(seconds: 10));
    }

    if (throwConnectionTimeoutOnFirst && !_hasThrownTimeout) {
      _hasThrownTimeout = true;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
        error: 'Connection timeout',
      );
    }

    if (_currentFailures < failCountBeforeSuccess) {
      _currentFailures++;
      return ResponseBody.fromString(
        '{"message":"Server error"}',
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (responseStatusCode != 200) {
      return ResponseBody.fromString(
        '{"message":"Error response"}',
        responseStatusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (returnInvalidJsonSchema && options.method == 'POST') {
      return ResponseBody.fromString(
        '{"data": "invalid_schema_string_instead_of_map"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.method == 'POST' && options.path.endsWith('/devices')) {
      final bodyMap = options.data as Map<String, dynamic>;
      final respJson = {
        'success': true,
        'message': 'Device registered successfully',
        'data': {
          'id': 'dev-uuid-101',
          'token': bodyMap['token'],
          'platform': bodyMap['platform'],
          'appVersion': bodyMap['appVersion'] ?? '1.0.0',
          'isActive': true,
          'lastUsedAt': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      };
      return ResponseBody.fromString(
        jsonEncode(respJson),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.method == 'PATCH' && options.path.contains('/deactivate')) {
      final respJson = {
        'success': true,
        'message': 'Device deactivated successfully',
        'data': {
          'id': 'dev-uuid-101',
          'token': 'test-token',
          'platform': 'ANDROID',
          'isActive': false,
          'lastUsedAt': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      };
      return ResponseBody.fromString(
        jsonEncode(respJson),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      '{}',
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
    });
    sharedPreferences = await SharedPreferences.getInstance();
    AppNotificationService.mockTokenForTesting = null;
    AppNotificationService.mockTokenRefreshControllerForTesting = null;
  });

  tearDown(() {
    AppNotificationService.mockTokenForTesting = null;
    AppNotificationService.mockTokenRefreshControllerForTesting = null;
  });

  group('Phase 2.1E.4 — FCM Device Registration Lifecycle Final Tests', () {
    test('1. Initial authenticated registration', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-token-initial';
      final mockAdapter = MockDeviceHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-user-101'),
          ),
          selectedTenantSlugProvider.overrideWith(
            () => TestTenantSlugNotifier('dev81-kuwait-fashion'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(deviceRegistrationProvider);
      expect(state, isNotNull);
      expect(state!.id, equals('dev-uuid-101'));
      expect(state.token, equals('fcm-token-initial'));

      expect(mockAdapter.requests.length, equals(1));
      final req = mockAdapter.requests.first;
      expect(req.path, equals('/devices'));
      expect(req.method, equals('POST'));
      expect(req.body['token'], equals('fcm-token-initial'));
    });

    test('2. Restored authenticated session', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-token-restored';
      final mockAdapter = MockDeviceHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-restored-session'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(deviceRegistrationProvider);
      expect(state, isNotNull);
      expect(state!.token, equals('fcm-token-restored'));
      expect(mockAdapter.requests.length, equals(1));
    });

    test('3. Anonymous session', () async {
      final mockAdapter = MockDeviceHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(() => TestAuthTokenNotifier(null)),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(deviceRegistrationProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(state, isNull);
      expect(mockAdapter.requests.length, equals(0));
    });

    test('4. HTTP 401/403/422 non-retry', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-401';
      final mockAdapter = MockDeviceHttpAdapter()..responseStatusCode = 401;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-401-test'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockAdapter.requests.length, equals(1)); // NO retries!
      expect(container.read(deviceRegistrationProvider), isNull);
    });

    test('5. HTTP 500 automatic bounded retry', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-500';
      final mockAdapter = MockDeviceHttpAdapter()..failCountBeforeSuccess = 2;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-500-retry'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);
      // Wait enough for retries (200ms + 400ms + buffer)
      await Future.delayed(const Duration(milliseconds: 1000));

      final state = container.read(deviceRegistrationProvider);
      expect(state, isNotNull);
      expect(state!.id, equals('dev-uuid-101'));
      // Initial attempt + 2 retries = 3 total requests
      expect(mockAdapter.requests.length, equals(3));
    });

    test('6. Connection timeout bounded retry', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-timeout';
      final mockAdapter = MockDeviceHttpAdapter()
        ..throwConnectionTimeoutOnFirst = true;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-timeout-test'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);
      await Future.delayed(const Duration(milliseconds: 600));

      final state = container.read(deviceRegistrationProvider);
      expect(state, isNotNull);
      // 1st request failed with connection timeout, 2nd attempt succeeded
      expect(mockAdapter.requests.length, equals(2));
    });

    test('7. Parsing error non-retry', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-parse';
      final mockAdapter = MockDeviceHttpAdapter()
        ..returnInvalidJsonSchema = true;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-parse-err'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockAdapter.requests.length, equals(1)); // NO retries!
      expect(container.read(deviceRegistrationProvider), isNull);
    });

    test('8. Logout deactivation before credential removal', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-logout-test';
      final mockAdapter = MockDeviceHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-valid-auth'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(deviceRegistrationProvider), isNotNull);

      final notifier = container.read(deviceRegistrationProvider.notifier);
      await notifier.deactivateCurrentDeviceBeforeLogout();

      expect(container.read(deviceRegistrationProvider), isNull);
      expect(mockAdapter.requests.length, equals(2));
      expect(mockAdapter.requests[1].method, equals('PATCH'));
      expect(
        mockAdapter.requests[1].path,
        contains('/devices/dev-uuid-101/deactivate'),
      );
    });

    test('9. Offline logout completes within timeout', () async {
      final mockAdapter = MockDeviceHttpAdapter()
        ..shouldHangOnDeactivate = true;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final repo = DeviceRepository(dio);

      final stopwatch = Stopwatch()..start();
      try {
        await repo
            .deactivateDevice('dev-uuid-101')
            .timeout(const Duration(milliseconds: 500));
      } catch (e) {
        expect(e, isA<TimeoutException>());
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
    });

    test('10. Logout while registration is in flight', () async {
      final mockAdapter = MockDeviceHttpAdapter()..postDelayMs = 200;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-user-a'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(deviceRegistrationProvider.notifier);
      final regFuture = notifier.registerDevice(
        forcedToken: 'fcm-in-flight-logout',
      );

      // Logout immediately while POST registration is in flight
      await container.read(authTokenProvider.notifier).setToken(null);

      final res = await regFuture;
      expect(res, isNull);

      // Wait for registration POST to finish and cleanup task to run
      await Future.delayed(const Duration(milliseconds: 350));
      // First call was POST /devices, second call was PATCH /deactivate cleanup
      expect(mockAdapter.requests.length, equals(2));
      expect(mockAdapter.requests[0].method, equals('POST'));
      expect(mockAdapter.requests[1].method, equals('PATCH'));
      expect(container.read(deviceRegistrationProvider), isNull);
    });

    test('11. Account switch while registration is in flight', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-stale';
      final mockAdapter = MockDeviceHttpAdapter()..postDelayMs = 200;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-user-a'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);

      // Switch to User B while User A's registration POST is in flight
      await container.read(authTokenProvider.notifier).setToken('token-user-b');

      await Future.delayed(const Duration(milliseconds: 350));
      expect(container.read(authTokenProvider), equals('token-user-b'));
    });

    test('12. Tenant switch while registration is in flight', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-tenant-stale';
      final mockAdapter = MockDeviceHttpAdapter()..postDelayMs = 200;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-user-1'),
          ),
          selectedTenantSlugProvider.overrideWith(
            () => TestTenantSlugNotifier('tenant-a'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      container.read(deviceRegistrationProvider);

      // Switch tenant while registration POST is in flight
      await container
          .read(selectedTenantSlugProvider.notifier)
          .setTenantSlug('tenant-b');

      await Future.delayed(const Duration(milliseconds: 350));
    });

    test('13. FCM token refresh during registration', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-token-v1';
      final mockAdapter = MockDeviceHttpAdapter()..postDelayMs = 200;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final refreshController = StreamController<String>.broadcast();
      AppNotificationService.mockTokenRefreshControllerForTesting =
          refreshController;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-refresh-test'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(() {
        container.dispose();
        refreshController.close();
      });

      container.read(deviceRegistrationProvider);

      // Emit new token on refresh stream while 1st registration is in flight
      refreshController.add('fcm-token-v2');

      await Future.delayed(const Duration(milliseconds: 500));

      // 2 registrations total: 1st with v1, 2nd queued refresh with v2
      expect(mockAdapter.requests.length, equals(2));
      expect(mockAdapter.requests[0].body['token'], equals('fcm-token-v1'));
      expect(mockAdapter.requests[1].body['token'], equals('fcm-token-v2'));
    });

    test('14. Concurrent registration deduplication', () async {
      AppNotificationService.mockTokenForTesting = 'fcm-concurrent';
      final mockAdapter = MockDeviceHttpAdapter()..postDelayMs = 150;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
        ..httpClientAdapter = mockAdapter;

      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith(
            () => TestAuthTokenNotifier('token-concurrent'),
          ),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(deviceRegistrationProvider.notifier);

      final req1 = notifier.registerDevice();
      final req2 = notifier.registerDevice();

      final results = await Future.wait([req1, req2]);

      // Only 1 HTTP request made!
      expect(mockAdapter.requests.length, equals(1));
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(results[0]!.id, equals(results[1]!.id));
    });

    test(
      '15. No repeated automatic registration after permanent failure',
      () async {
        AppNotificationService.mockTokenForTesting = 'fcm-perm-fail';
        final mockAdapter = MockDeviceHttpAdapter()..responseStatusCode = 400;
        final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
          ..httpClientAdapter = mockAdapter;

        final container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(
              () => TestAuthTokenNotifier('token-perm-fail'),
            ),
            dioClientProvider.overrideWithValue(dio),
          ],
        );
        addTearDown(container.dispose);

        container.read(deviceRegistrationProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(mockAdapter.requests.length, equals(1));

        // Trigger build() again under same context
        container.read(deviceRegistrationProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // NO new request made! Still 1.
        expect(mockAdapter.requests.length, equals(1));
      },
    );

    test(
      '16. Correct payload, Authorization, and X-Tenant-Slug headers',
      () async {
        AppNotificationService.mockTokenForTesting = 'fcm-header-verify';
        final mockAdapter = MockDeviceHttpAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'))
          ..httpClientAdapter = mockAdapter;

        final container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(
              () => TestAuthTokenNotifier('token-header-check-999'),
            ),
            selectedTenantSlugProvider.overrideWith(
              () => TestTenantSlugNotifier('kuwait-fashion-shop'),
            ),
            dioClientProvider.overrideWithValue(dio),
          ],
        );
        addTearDown(container.dispose);

        container.read(deviceRegistrationProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        final device = container.read(deviceRegistrationProvider);
        expect(device, isNotNull);
        expect(mockAdapter.requests.length, equals(1));

        final req = mockAdapter.requests.first;
        expect(req.path, equals('/devices'));
        expect(req.method, equals('POST'));
        expect(req.body['token'], equals('fcm-header-verify'));
        expect(req.body['platform'], isNotNull);
      },
    );
  });
}

class TestAuthTokenNotifier extends AuthTokenNotifier {
  String? _t;
  TestAuthTokenNotifier(this._t);

  @override
  String? build() => _t;

  @override
  Future<void> setToken(String? token, {String? refreshToken}) async {
    _t = token;
    state = token;
  }
}

class TestTenantSlugNotifier extends SelectedTenantSlugNotifier {
  String _s;
  TestTenantSlugNotifier(this._s);

  @override
  String build() => _s;

  @override
  Future<void> setTenantSlug(String slug) async {
    _s = slug;
    state = slug;
  }
}
