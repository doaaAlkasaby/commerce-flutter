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
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('products')) {
      productsCallCount++;
      if (options.headers['Authorization'] != 'Bearer new_access_token_123') {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
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
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real Dio Interceptor & Session Security Gate Tests', () {
    test('Two concurrent 401 responses coalesce into exactly ONE /auth/refresh call', () async {
      SharedPreferences.setMockInitialValues({'refresh_token': 'valid_refresh_token_123'});
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = InterceptorTestAdapter();
      final container = ProviderContainer();

      container.read(authTokenProvider.notifier).setToken('initial_token');

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      final req1 = dio.get('/products');
      final req2 = dio.get('/products');

      await Future.wait([req1, req2]);

      expect(mockAdapter.refreshCallCount, 1);

      container.dispose();
    });

    test('User A refresh fails while User A is active: coordinator AND authProvider BOTH become unauthenticated', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'user_a_token',
        'refresh_token': 'user_a_refresh_token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = SignalRefreshAdapter();
      final container = ProviderContainer();

      container.read(authTokenProvider.notifier).setToken('user_a_token');

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
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        ),
      );

      try {
        await userARequestFuture;
      } catch (_) {}

      // Verify BOTH coordinator and authTokenProvider state became null
      expect(container.read(authTokenProvider), isNull);
      expect(container.read(sessionCoordinatorProvider).currentSession, isNull);
      expect(sharedPreferences.getString('access_token'), isNull);

      container.dispose();
    });

    test('User A refresh fails AFTER User B logs in: User B active session, authProvider, and credentials remain unchanged', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'user_a_token',
        'refresh_token': 'user_a_refresh_token',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter = SignalRefreshAdapter();
      final container = ProviderContainer();

      // 1. User A starts authenticated session
      container.read(authTokenProvider.notifier).setToken('user_a_token');
      final userASessionId = container.read(sessionCoordinatorProvider).currentSessionId;

      final dio = container.read(dioClientProvider);
      dio.httpClientAdapter = mockAdapter;

      // 2. User A sends request returning 401
      final userARequestFuture = dio.get('/products');

      // Await signal that refresh HTTP call has actually started
      await mockAdapter.refreshStartedCompleter.future;

      // 3. User B replaces User A before refresh completes
      await sharedPreferences.setString('access_token', 'user_b_token');
      await sharedPreferences.setString('refresh_token', 'user_b_refresh_token');
      container.read(authTokenProvider.notifier).setToken('user_b_token');
      final userBSessionId = container.read(sessionCoordinatorProvider).currentSessionId;
      expect(userBSessionId, isNot(userASessionId));

      // 4. Complete User A's pending refresh with HTTP 401 failure
      mockAdapter.refreshCompleter.complete(
        ResponseBody.fromString(
          jsonEncode({'message': 'Invalid refresh token'}),
          401,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        ),
      );

      try {
        await userARequestFuture;
      } catch (_) {}

      // 5. Assert User B remains authenticated in authTokenProvider
      expect(container.read(authTokenProvider), 'user_b_token');

      // 6. Assert User B remains active in SessionCoordinator
      expect(container.read(sessionCoordinatorProvider).currentSessionId, userBSessionId);
      expect(container.read(sessionCoordinatorProvider).activeAccessToken, 'user_b_token');

      // 7. Assert User B's persisted credentials in SharedPreferences remain unchanged
      expect(sharedPreferences.getString('access_token'), 'user_b_token');
      expect(sharedPreferences.getString('refresh_token'), 'user_b_refresh_token');

      // 8. Assert User A's request was NOT retried with User B's token
      final productRequests = mockAdapter.requestsReceived.where((r) => r.path.contains('products')).toList();
      for (final req in productRequests) {
        expect(req.headers['Authorization'], isNot('Bearer user_b_token'));
      }

      container.dispose();
    });

    test('Overlapping refreshes across two independent ProviderContainers remain isolated', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'token_init',
        'refresh_token': 'refresh_init',
      });
      sharedPreferences = await SharedPreferences.getInstance();

      final mockAdapter1 = InterceptorTestAdapter();
      final mockAdapter2 = InterceptorTestAdapter();

      final container1 = ProviderContainer();
      final container2 = ProviderContainer();

      container1.read(authTokenProvider.notifier).setToken('token_c1');
      container2.read(authTokenProvider.notifier).setToken('token_c2');

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
    });

    test('SessionCoordinator rejects stale token commit on session replacement', () async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();

      final coordinator = SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
      coordinator.startSession(accessToken: 'user_a_token');

      final userASessionId = coordinator.currentSessionId!;

      // User B logs in during User A's in-flight refresh
      coordinator.startSession(accessToken: 'user_b_token');

      // Attempt to commit User A's refreshed token
      final result = await coordinator.commitRefreshedTokens(
        owningSessionId: userASessionId,
        newAccessToken: 'stale_user_a_refreshed_token',
      );

      // Verify User A's token refresh was discarded and User B's session was preserved
      expect(result, isNull);
      expect(coordinator.activeAccessToken, 'user_b_token');
    });

    test('SessionCoordinator handles refresh failure without clearing newer session', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'user_b_token'});
      sharedPreferences = await SharedPreferences.getInstance();

      final coordinator = SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));

      // User A session started
      coordinator.startSession(accessToken: 'user_a_token');
      final userASessionId = coordinator.currentSessionId!;

      // User B logs in
      coordinator.startSession(accessToken: 'user_b_token');

      // Failed refresh for User A occurs
      await coordinator.handleRefreshFailure(userASessionId);

      // Verify User B's active session is NOT cleared
      expect(coordinator.activeAccessToken, 'user_b_token');
    });

    test('Logout while refresh is pending clears session and discards refreshed token', () async {
      SharedPreferences.setMockInitialValues({'refresh_token': 'valid_refresh_token_123'});
      sharedPreferences = await SharedPreferences.getInstance();

      final coordinator = SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
      coordinator.startSession(accessToken: 'user_a_token');
      final userASessionId = coordinator.currentSessionId!;

      // Logout called
      coordinator.clearSession();

      // Refreshed token arrives for old session
      final result = await coordinator.commitRefreshedTokens(
        owningSessionId: userASessionId,
        newAccessToken: 'user_a_refreshed_token',
      );

      expect(result, isNull);
      expect(coordinator.currentSession, isNull);
    });
  });
}
