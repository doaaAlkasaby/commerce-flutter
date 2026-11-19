import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/main.dart';

class InterceptorTestAdapter implements HttpClientAdapter {
  int refreshCallCount = 0;
  int productsCallCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('auth/refresh')) {
      refreshCallCount++;
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'accessToken': 'new_access_token_123',
            'refreshToken': 'new_refresh_token_456',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('products')) {
      productsCallCount++;
      if (options.headers['Authorization'] != 'Bearer new_access_token_123') {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class SignalRefreshAdapter implements HttpClientAdapter {
  final Completer<void> refreshStartedCompleter = Completer<void>();
  final Completer<ResponseBody> refreshCompleter = Completer<ResponseBody>();
  int refreshCallCount = 0;
  List<RequestOptions> requestsReceived = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestsReceived.add(options);
    final path = options.path;

    if (path.contains('auth/refresh')) {
      refreshCallCount++;
      if (!refreshStartedCompleter.isCompleted) {
        refreshStartedCompleter.complete();
      }
      return refreshCompleter.future;
    }

    if (path.contains('products')) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('checkout')) {
      if (options.headers['Authorization'] != 'Bearer new_token_777') {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthorized'}),
          401,
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

    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real Dio Interceptor & Session Security Gate Tests', () {
    test(
      'Two concurrent 401 responses coalesce into exactly ONE /auth/refresh call',
      () async {
        SharedPreferences.setMockInitialValues({
          'refresh_token': 'valid_refresh_token_123',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = InterceptorTestAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('initial_token', refreshToken: 'valid_refresh_token_123');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final req1 = dio.get('/products');
        final req2 = dio.get('/products');

        await Future.wait([req1, req2]);

        expect(mockAdapter.refreshCallCount, 1);

        container.dispose();
      },
    );

    test(
      'User A refresh fails while User A is active: coordinator AND authProvider BOTH become unauthenticated',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'user_a_token',
          'refresh_token': 'user_a_refresh_token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = SignalRefreshAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('user_a_token', refreshToken: 'user_a_refresh_token');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        // Trigger 401 request
        final userARequestFuture = dio.get('/products');

        // Await signal that refresh HTTP call has actually started
        await mockAdapter.refreshStartedCompleter.future;

        // Fail refresh with 401
        mockAdapter.refreshCompleter.complete(
          ResponseBody.fromString(
            jsonEncode({'message': 'Invalid refresh token'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        try {
          await userARequestFuture;
        } catch (_) {}

        // Verify BOTH coordinator and authTokenProvider state became null
        expect(container.read(authTokenProvider), isNull);
        expect(
          container.read(sessionCoordinatorProvider).currentSession,
          isNull,
        );

        container.dispose();
      },
    );

    test(
      'User A refresh fails AFTER User B logs in: User B active session, authProvider, and credentials remain unchanged',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'user_a_token',
          'refresh_token': 'user_a_refresh_token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = SignalRefreshAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        // 1. User A starts authenticated session
        await container
            .read(authTokenProvider.notifier)
            .setToken('user_a_token', refreshToken: 'user_a_refresh_token');
        final userASessionId = container
            .read(sessionCoordinatorProvider)
            .currentSessionId;

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        // 2. User A sends request returning 401
        final userARequestFuture = dio.get('/products');

        // Await signal that refresh HTTP call has actually started
        await mockAdapter.refreshStartedCompleter.future;

        // 3. User B replaces User A before refresh completes
        await sharedPreferences.setString('access_token', 'user_b_token');
        await sharedPreferences.setString(
          'refresh_token',
          'user_b_refresh_token',
        );
        await container
            .read(authTokenProvider.notifier)
            .setToken('user_b_token', refreshToken: 'user_b_refresh_token');
        final userBSessionId = container
            .read(sessionCoordinatorProvider)
            .currentSessionId;
        expect(userBSessionId, isNot(userASessionId));

        // 4. Complete User A's pending refresh with HTTP 401 failure
        mockAdapter.refreshCompleter.complete(
          ResponseBody.fromString(
            jsonEncode({'message': 'Invalid refresh token'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        try {
          await userARequestFuture;
        } catch (_) {}

        // 5. Assert User B remains authenticated in authTokenProvider
        expect(container.read(authTokenProvider), 'user_b_token');

        // 6. Assert User B remains active in SessionCoordinator
        expect(
          container.read(sessionCoordinatorProvider).currentSessionId,
          userBSessionId,
        );
        expect(
          container.read(sessionCoordinatorProvider).activeAccessToken,
          'user_b_token',
        );

        // 7. Assert User B's persisted credentials in SharedPreferences remain unchanged
        expect(sharedPreferences.getString('access_token'), 'user_b_token');
        expect(
          sharedPreferences.getString('refresh_token'),
          'user_b_refresh_token',
        );

        // 8. Assert User A's request was NOT retried with User B's token
        final productRequests = mockAdapter.requestsReceived
            .where((r) => r.path.contains('products'))
            .toList();
        for (final req in productRequests) {
          expect(req.headers['Authorization'], isNot('Bearer user_b_token'));
        }

        container.dispose();
      },
    );

    test(
      'Overlapping refreshes across two independent ProviderContainers remain isolated',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'token_init',
          'refresh_token': 'refresh_init',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter1 = InterceptorTestAdapter();
        final mockAdapter2 = InterceptorTestAdapter();

        final container1 = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );
        final container2 = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container1
            .read(authTokenProvider.notifier)
            .setToken('token_c1', refreshToken: 'refresh_c1');
        await container2
            .read(authTokenProvider.notifier)
            .setToken('token_c2', refreshToken: 'refresh_c2');

        final dio1 = container1.read(dioClientProvider);
        dio1.httpClientAdapter = mockAdapter1;

        final dio2 = container2.read(dioClientProvider);
        dio2.httpClientAdapter = mockAdapter2;

        // Trigger 401s on both containers simultaneously
        final req1 = dio1.get('/products');
        final req2 = dio2.get('/products');

        await Future.wait([req1, req2]);

        expect(mockAdapter1.refreshCallCount, 1);
        expect(mockAdapter2.refreshCallCount, 1);

        expect(container1.read(authTokenProvider), 'new_access_token_123');
        expect(container2.read(authTokenProvider), 'new_access_token_123');

        container1.dispose();
        container2.dispose();
      },
    );

    test(
      'SessionCoordinator rejects stale token commit on session replacement',
      () async {
        SharedPreferences.setMockInitialValues({});
        sharedPreferences = await SharedPreferences.getInstance();

        final coordinator = SessionCoordinator(
          SharedPreferencesCredentialStorage(sharedPreferences),
        );
        await coordinator.startSession(accessToken: 'user_a_token');

        final userASessionId = coordinator.currentSessionId!;

        // User B logs in during User A's in-flight refresh
        await coordinator.startSession(accessToken: 'user_b_token');

        // Attempt to commit User A's refreshed token
        final result = await coordinator.commitRefreshedTokens(
          owningSessionId: userASessionId,
          newAccessToken: 'stale_user_a_refreshed_token',
        );

        // Verify User A's token refresh was discarded and User B's session was preserved
        expect(result, isNull);
        expect(coordinator.activeAccessToken, 'user_b_token');
      },
    );

    test(
      'SessionCoordinator handles refresh failure without clearing newer session',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'user_b_token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final coordinator = SessionCoordinator(
          SharedPreferencesCredentialStorage(sharedPreferences),
        );

        // User A session started
        await coordinator.startSession(accessToken: 'user_a_token');
        final userASessionId = coordinator.currentSessionId!;

        // User B logs in
        await coordinator.startSession(accessToken: 'user_b_token');

        // Failed refresh for User A occurs
        await coordinator.handleRefreshFailure(userASessionId);

        // Verify User B's active session is NOT cleared
        expect(coordinator.activeAccessToken, 'user_b_token');
      },
    );

    test(
      'Logout while refresh is pending clears session and discards refreshed token',
      () async {
        SharedPreferences.setMockInitialValues({
          'refresh_token': 'valid_refresh_token_123',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final coordinator = SessionCoordinator(
          SharedPreferencesCredentialStorage(sharedPreferences),
        );
        await coordinator.startSession(accessToken: 'user_a_token');
        final userASessionId = coordinator.currentSessionId!;

        // Logout called
        await coordinator.clearSession();

        // Refreshed token arrives for old session
        final result = await coordinator.commitRefreshedTokens(
          owningSessionId: userASessionId,
          newAccessToken: 'user_a_refreshed_token',
        );

        expect(result, isNull);
        expect(coordinator.currentSession, isNull);
      },
    );
  });

  group('Phase AUTH-2 — Safe Refresh Failure Handling Regression Tests', () {
    test(
      '1. Offline refresh failure preserves session and credentials',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'active_token',
          'refresh_token': 'active_refresh',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = SignalRefreshAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('active_token', refreshToken: 'active_refresh');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final reqFuture = dio.get('/products');
        await mockAdapter.refreshStartedCompleter.future;

        // Fail refresh with offline connection error
        mockAdapter.refreshCompleter.completeError(
          DioException(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            type: DioExceptionType.connectionError,
            error: 'SocketException: Network is unreachable',
          ),
        );

        DioException? caughtError;
        try {
          await reqFuture;
        } on DioException catch (e) {
          caughtError = e;
        }

        // Verify caller receives the TRANSIENT connection error, NOT a misleading 401!
        expect(caughtError, isNotNull);
        expect(caughtError!.type, equals(DioExceptionType.connectionError));

        // Session and tokens MUST remain active!
        expect(container.read(authTokenProvider), equals('active_token'));
        expect(
          container.read(sessionCoordinatorProvider).currentSession,
          isNotNull,
        );
        expect(
          sharedPreferences.getString('access_token'),
          equals('active_token'),
        );

        container.dispose();
      },
    );

    test(
      '2. Connection timeout preserves session and reaches caller correctly',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'active_token',
          'refresh_token': 'active_refresh',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = SignalRefreshAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('active_token', refreshToken: 'active_refresh');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final reqFuture = dio.get('/products');
        await mockAdapter.refreshStartedCompleter.future;

        // Fail refresh with connection timeout
        mockAdapter.refreshCompleter.completeError(
          DioException(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timeout',
          ),
        );

        DioException? caughtError;
        try {
          await reqFuture;
        } on DioException catch (e) {
          caughtError = e;
        }

        // Verify caller receives timeout error
        expect(caughtError, isNotNull);
        expect(caughtError!.type, equals(DioExceptionType.connectionTimeout));

        expect(container.read(authTokenProvider), equals('active_token'));
        expect(
          container.read(sessionCoordinatorProvider).currentSession,
          isNotNull,
        );

        container.dispose();
      },
    );

    test(
      '3. HTTP 500 preserves session and reaches caller correctly',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'active_token',
          'refresh_token': 'active_refresh',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = SignalRefreshAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('active_token', refreshToken: 'active_refresh');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final reqFuture = dio.get('/products');
        await mockAdapter.refreshStartedCompleter.future;

        // Fail refresh with HTTP 500
        mockAdapter.refreshCompleter.complete(
          ResponseBody.fromString(
            jsonEncode({'message': 'Internal Server Error'}),
            500,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        DioException? caughtError;
        try {
          await reqFuture;
        } on DioException catch (e) {
          caughtError = e;
        }

        // Verify caller receives 500 response error
        expect(caughtError, isNotNull);
        expect(caughtError!.response?.statusCode, equals(500));

        expect(container.read(authTokenProvider), equals('active_token'));
        expect(
          container.read(sessionCoordinatorProvider).currentSession,
          isNotNull,
        );

        container.dispose();
      },
    );

    test('4. Storage read exception preserves active session', () async {
      final mockAdapter = SignalRefreshAdapter();
      final exceptionStorage = ThrowingReadStorage();

      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(exceptionStorage);
          }),
        ],
      );

      await container
          .read(sessionCoordinatorProvider)
          .startSession(accessToken: 'token_1', refreshToken: 'refresh_1');
      await container
          .read(authTokenProvider.notifier)
          .setToken('token_1', refreshToken: 'refresh_1');

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      final reqFuture = dio.get('/products');

      try {
        await reqFuture;
      } catch (_) {}

      // Storage read threw exception; session MUST remain active!
      expect(container.read(authTokenProvider), equals('token_1'));
      expect(
        container.read(sessionCoordinatorProvider).currentSession,
        isNotNull,
      );

      container.dispose();
    });

    test('4. Confirmed invalid refresh token clears session', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'active_token',
        'refresh_token': 'active_refresh',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = SignalRefreshAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(
              SharedPreferencesCredentialStorage(sharedPreferences),
            );
          }),
        ],
      );

      await container
          .read(authTokenProvider.notifier)
          .setToken('active_token', refreshToken: 'active_refresh');

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      final reqFuture = dio.get('/products');
      await mockAdapter.refreshStartedCompleter.future;

      // Fail refresh with HTTP 401
      mockAdapter.refreshCompleter.complete(
        ResponseBody.fromString(
          jsonEncode({
            'message': 'Invalid refresh token',
            'code': 'INVALID_REFRESH_TOKEN',
          }),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      try {
        await reqFuture;
      } catch (_) {}

      expect(container.read(authTokenProvider), isNull);
      expect(container.read(sessionCoordinatorProvider).currentSession, isNull);

      container.dispose();
    });

    test('5. Confirmed revoked/reused token clears session', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'active_token',
        'refresh_token': 'active_refresh',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = SignalRefreshAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(
              SharedPreferencesCredentialStorage(sharedPreferences),
            );
          }),
        ],
      );

      await container
          .read(authTokenProvider.notifier)
          .setToken('active_token', refreshToken: 'active_refresh');

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      final reqFuture = dio.get('/products');
      await mockAdapter.refreshStartedCompleter.future;

      // Fail refresh with HTTP 400 REFRESH_TOKEN_REUSED
      mockAdapter.refreshCompleter.complete(
        ResponseBody.fromString(
          jsonEncode({
            'message': 'Refresh token reuse detected',
            'code': 'REFRESH_TOKEN_REUSED',
          }),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      try {
        await reqFuture;
      } catch (_) {}

      expect(container.read(authTokenProvider), isNull);
      expect(container.read(sessionCoordinatorProvider).currentSession, isNull);

      container.dispose();
    });

    test(
      '6. Concurrent 401 requests share a single refresh operation',
      () async {
        SharedPreferences.setMockInitialValues({
          'refresh_token': 'valid_refresh',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = InterceptorTestAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('initial_token', refreshToken: 'valid_refresh');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final req1 = dio.get('/products');
        final req2 = dio.get('/products');
        final req3 = dio.get('/products');

        await Future.wait([req1, req2, req3]);

        expect(mockAdapter.refreshCallCount, equals(1));

        container.dispose();
      },
    );

    test('7. Successful refresh retries with the new access token', () async {
      SharedPreferences.setMockInitialValues({
        'refresh_token': 'valid_refresh',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = InterceptorTestAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(
              SharedPreferencesCredentialStorage(sharedPreferences),
            );
          }),
        ],
      );

      await container
          .read(authTokenProvider.notifier)
          .setToken('old_token', refreshToken: 'valid_refresh');

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      final response = await dio.get('/products');

      expect(response.statusCode, equals(200));
      expect(container.read(authTokenProvider), equals('new_access_token_123'));

      container.dispose();
    });

    test(
      '8. Original Idempotency-Key survives an authenticated retry',
      () async {
        SharedPreferences.setMockInitialValues({
          'refresh_token': 'valid_refresh',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = SignalRefreshAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('old_token', refreshToken: 'valid_refresh');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final reqFuture = dio.post(
          '/checkout',
          options: Options(
            headers: {'Idempotency-Key': 'idemp_unique_key_999'},
          ),
        );

        await mockAdapter.refreshStartedCompleter.future;

        mockAdapter.refreshCompleter.complete(
          ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'new_token_777',
                'refreshToken': 'new_refresh_777',
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        try {
          await reqFuture;
        } catch (_) {}

        final checkoutReqs = mockAdapter.requestsReceived
            .where((r) => r.path.contains('checkout'))
            .toList();
        expect(checkoutReqs.length, equals(2));
        expect(
          checkoutReqs[0].headers['Idempotency-Key'],
          equals('idemp_unique_key_999'),
        );
        expect(
          checkoutReqs[1].headers['Idempotency-Key'],
          equals('idemp_unique_key_999'),
        );
        expect(
          checkoutReqs[1].headers['Authorization'],
          equals('Bearer new_token_777'),
        );

        container.dispose();
      },
    );

    test(
      '9. Account switching during refresh does not clear the new account',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'user_a_token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = SignalRefreshAdapter();
        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
          ],
        );

        await container
            .read(authTokenProvider.notifier)
            .setToken('user_a_token', refreshToken: 'user_a_refresh');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final reqFuture = dio.get('/products');
        await mockAdapter.refreshStartedCompleter.future;

        // Switch to User B while User A refresh is pending
        await container
            .read(authTokenProvider.notifier)
            .setToken('user_b_token', refreshToken: 'user_b_refresh');

        mockAdapter.refreshCompleter.complete(
          ResponseBody.fromString(
            jsonEncode({'message': 'Invalid refresh token'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        try {
          await reqFuture;
        } catch (_) {}

        // User B must remain authenticated!
        expect(container.read(authTokenProvider), equals('user_b_token'));

        container.dispose();
      },
    );

    test('10. Logout during refresh does not restore an old session', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'user_a_token'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = SignalRefreshAdapter();
      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(
              SharedPreferencesCredentialStorage(sharedPreferences),
            );
          }),
        ],
      );

      await container
          .read(authTokenProvider.notifier)
          .setToken('user_a_token', refreshToken: 'user_a_refresh');

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      final reqFuture = dio.get('/products');
      await mockAdapter.refreshStartedCompleter.future;

      // User logs out while refresh is pending
      await container.read(authTokenProvider.notifier).setToken(null);

      // Late refreshed token response arrives
      mockAdapter.refreshCompleter.complete(
        ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'user_a_new_access',
              'refreshToken': 'user_a_new_refresh',
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      try {
        await reqFuture;
      } catch (_) {}

      // Session must remain null (unauthenticated)!
      expect(container.read(authTokenProvider), isNull);
      expect(container.read(sessionCoordinatorProvider).currentSession, isNull);

      container.dispose();
    });

    test(
      '11. Secure-storage write failure is reported without falsely claiming successful refresh',
      () async {
        final mockAdapter = SignalRefreshAdapter();
        final failingStorage = FailingWriteStorage();

        final container = ProviderContainer(
          overrides: [
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(failingStorage);
            }),
          ],
        );

        await container
            .read(sessionCoordinatorProvider)
            .startSession(accessToken: 'token_1', refreshToken: 'refresh_1');
        await container
            .read(authTokenProvider.notifier)
            .setToken('token_1', refreshToken: 'refresh_1');

        final dio = container.read(dioClientProvider);
        dio.httpClientAdapter = mockAdapter;

        final reqFuture = dio.get('/products');
        await mockAdapter.refreshStartedCompleter.future;

        failingStorage.shouldFailWrite = true;

        mockAdapter.refreshCompleter.complete(
          ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'new_token',
                'refreshToken': 'new_refresh',
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        try {
          await reqFuture;
        } catch (_) {}

        // Storage write failed, so authTokenProvider was NOT updated to new_token!
        expect(container.read(authTokenProvider), isNot('new_token'));

        container.dispose();
      },
    );

    test('12. No infinite retry loops', () async {
      SharedPreferences.setMockInitialValues({
        'refresh_token': 'valid_refresh',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
      dio.httpClientAdapter = Always401Adapter();

      final container = ProviderContainer(
        overrides: [
          sessionCoordinatorProvider.overrideWith((ref) {
            return SessionCoordinator(
              SharedPreferencesCredentialStorage(sharedPreferences),
            );
          }),
        ],
      );

      await container
          .read(authTokenProvider.notifier)
          .setToken('initial_token', refreshToken: 'valid_refresh');

      final clientDio = container.read(dioClientProvider);
      clientDio.httpClientAdapter = Always401Adapter();

      try {
        await clientDio.get('/products');
      } catch (_) {}

      final adapter = clientDio.httpClientAdapter as Always401Adapter;
      // Request should hit 401, trigger 1 refresh (which fails with 401), and NOT loop infinitely.
      expect(adapter.requestCount, lessThanOrEqualTo(2));

      container.dispose();
    });
  });
}

class FailingWriteStorage implements CredentialStorage {
  String? _access;
  String? _refresh;
  bool shouldFailWrite = false;

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<bool> writeCredentials(String access, String? refresh) async {
    if (shouldFailWrite) return false;
    _access = access;
    _refresh = refresh;
    return true;
  }

  @override
  Future<bool> clearCredentials() async {
    _access = null;
    _refresh = null;
    return true;
  }

  @override
  Future<void> migrateLegacyCredentials(SharedPreferences prefs) async {}
}

class Always401Adapter implements HttpClientAdapter {
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    if (options.path.contains('auth/refresh')) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Invalid refresh token'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class ThrowingReadStorage implements CredentialStorage {
  String? _access = 'token_1';
  String? _refresh = 'refresh_1';

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async {
    if (_refresh == null) return null;
    throw Exception('KeyStore temporary OS hardware lock');
  }

  @override
  Future<bool> writeCredentials(String access, String? refresh) async {
    _access = access;
    _refresh = refresh;
    return true;
  }

  @override
  Future<bool> clearCredentials() async {
    _access = null;
    _refresh = null;
    return true;
  }

  @override
  Future<void> migrateLegacyCredentials(SharedPreferences prefs) async {}
}
