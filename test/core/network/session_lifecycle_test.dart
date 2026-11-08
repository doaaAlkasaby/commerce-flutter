import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';

class GatedMockStorage implements CredentialStorage {
  String? accessToken;
  String? refreshToken;

  Completer<void>? writeStartedCompleter;
  Completer<void>? releaseWriteCompleter;

  Completer<void>? clearStartedCompleter;
  Completer<void>? releaseClearCompleter;

  Completer<void>? readStartedCompleter;
  Completer<void>? releaseReadCompleter;

  bool shouldFailRefreshToken = false;
  bool shouldFailClear = false;

  @override
  Future<String?> readAccessToken() async {
    if (readStartedCompleter != null && !readStartedCompleter!.isCompleted) {
      readStartedCompleter!.complete();
    }
    if (releaseReadCompleter != null) {
      await releaseReadCompleter!.future;
    }
    return accessToken;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<bool> writeCredentials(String newAccess, String? newRefresh) async {
    if (writeStartedCompleter != null && !writeStartedCompleter!.isCompleted) {
      writeStartedCompleter!.complete();
    }
    if (releaseWriteCompleter != null) {
      await releaseWriteCompleter!.future;
    }

    accessToken = newAccess;
    if (shouldFailRefreshToken) {
      // Partial write failure: refresh token write fails -> rollback access token
      accessToken = null;
      return false;
    }
    refreshToken = newRefresh;
    return true;
  }

  @override
  Future<bool> clearCredentials() async {
    if (clearStartedCompleter != null && !clearStartedCompleter!.isCompleted) {
      clearStartedCompleter!.complete();
    }
    if (releaseClearCompleter != null) {
      await releaseClearCompleter!.future;
    }
    if (shouldFailClear) {
      return false;
    }
    accessToken = null;
    refreshToken = null;
    return true;
  }
}

void main() {
  group('Session Lifecycle & Gated Completer Integration Tests', () {
    test('1. Account replacement during active credential write discards stale User A write', () async {
      final storage = GatedMockStorage();
      storage.accessToken = 'user_a_token';
      storage.refreshToken = 'user_a_refresh_token';
      storage.writeStartedCompleter = Completer<void>();
      storage.releaseWriteCompleter = Completer<void>();

      final coordinator = SessionCoordinator(storage);
      await coordinator.restoreSession();

      final userASessionId = coordinator.currentSessionId!;

      // User A triggers token refresh commit (pauses inside writeCredentials)
      final commitFuture = coordinator.commitRefreshedTokens(
        owningSessionId: userASessionId,
        newAccessToken: 'user_a_refreshed_token',
      );

      // Await signal that storage write operation started
      await storage.writeStartedCompleter!.future;

      // User B logs in while User A write is paused in storage
      final startFuture = coordinator.startSession(accessToken: 'user_b_token', refreshToken: 'user_b_refresh_token');
      final userBSessionId = coordinator.currentSessionId!;

      // Release User A's paused storage write
      storage.releaseWriteCompleter!.complete();

      final result = await commitFuture;
      await startFuture;

      // Assert User A's commit was discarded and User B remains active in memory and storage
      expect(result, isNull);
      expect(coordinator.currentSessionId, userBSessionId);
      expect(coordinator.activeAccessToken, 'user_b_token');
      expect(storage.accessToken, 'user_b_token');
      expect(storage.refreshToken, 'user_b_refresh_token');
    });

    test('2. Account replacement during refresh-failure cleanup preserves User B session', () async {
      final storage = GatedMockStorage();
      storage.accessToken = 'user_a_token';
      storage.refreshToken = 'user_a_refresh_token';
      storage.clearStartedCompleter = Completer<void>();
      storage.releaseClearCompleter = Completer<void>();

      final coordinator = SessionCoordinator(storage);
      await coordinator.restoreSession();

      final userASessionId = coordinator.currentSessionId!;

      // User A refresh failure triggers cleanup (pauses inside clearCredentials)
      final failureFuture = coordinator.handleRefreshFailure(userASessionId);

      // Await signal that storage clear operation started
      await storage.clearStartedCompleter!.future;

      // User B logs in while User A cleanup is paused
      final startFuture = coordinator.startSession(accessToken: 'user_b_token', refreshToken: 'user_b_refresh_token');
      final userBSessionId = coordinator.currentSessionId!;

      // Release User A's paused storage cleanup
      storage.releaseClearCompleter!.complete();

      final cleared = await failureFuture;
      await startFuture;

      // Assert User A cleanup returned false and User B remains active in memory and storage
      expect(cleared, isFalse);
      expect(coordinator.currentSessionId, userBSessionId);
      expect(coordinator.activeAccessToken, 'user_b_token');
      expect(storage.accessToken, 'user_b_token');
      expect(storage.refreshToken, 'user_b_refresh_token');
    });

    test('3. Logout during refresh persistence discards refreshed credentials', () async {
      final storage = GatedMockStorage();
      storage.accessToken = 'user_a_token';
      storage.writeStartedCompleter = Completer<void>();
      storage.releaseWriteCompleter = Completer<void>();

      final coordinator = SessionCoordinator(storage);
      await coordinator.restoreSession();

      final userASessionId = coordinator.currentSessionId!;

      final commitFuture = coordinator.commitRefreshedTokens(
        owningSessionId: userASessionId,
        newAccessToken: 'user_a_refreshed_token',
      );

      await storage.writeStartedCompleter!.future;

      // Logout called while write is paused
      final clearFuture = coordinator.clearSession();

      // Release storage write
      storage.releaseWriteCompleter!.complete();

      final result = await commitFuture;
      await clearFuture;

      expect(result, isNull);
      expect(coordinator.currentSession, isNull);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });

    test('4. Session initialization racing with login preserves login session', () async {
      final storage = GatedMockStorage();
      storage.accessToken = 'old_restored_token';
      storage.readStartedCompleter = Completer<void>();
      storage.releaseReadCompleter = Completer<void>();

      final coordinator = SessionCoordinator(storage);

      // Trigger restore (pauses during readAccessToken)
      final restoreFuture = coordinator.restoreSession();

      await storage.readStartedCompleter!.future;

      // User B logs in before restore completes
      final startFuture = coordinator.startSession(accessToken: 'new_login_token');
      final loginSessionId = coordinator.currentSessionId;

      // Release storage read
      storage.releaseReadCompleter!.complete();

      await restoreFuture;
      await startFuture;

      // Assert login session was preserved in memory and storage
      expect(coordinator.currentSessionId, loginSessionId);
      expect(coordinator.activeAccessToken, 'new_login_token');
      expect(storage.accessToken, 'new_login_token');
    });

    test('5. Failed credential deletion propagates error on clearSession', () async {
      final storage = GatedMockStorage();
      storage.shouldFailClear = true;

      final coordinator = SessionCoordinator(storage);
      await coordinator.startSession(accessToken: 'active_token');

      expect(
        () async => await coordinator.clearSession(),
        throwsA(isA<FormatException>()),
      );
    });

    test('6. Instance-scoped refresh futures do not cross-contaminate independent coordinator instances', () async {
      final storage1 = GatedMockStorage();
      final storage2 = GatedMockStorage();

      final coordinator1 = SessionCoordinator(storage1);
      final coordinator2 = SessionCoordinator(storage2);

      await coordinator1.startSession(accessToken: 'token_1');
      await coordinator2.startSession(accessToken: 'token_2');

      expect(coordinator1.currentSessionId, isNot(coordinator2.currentSessionId));
      expect(coordinator1.inFlightRefreshFuture, isNull);
      expect(coordinator2.inFlightRefreshFuture, isNull);
    });
  });
}
