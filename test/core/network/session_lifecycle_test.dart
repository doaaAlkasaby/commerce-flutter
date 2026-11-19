import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';

class CompleterPausableStorage implements CredentialStorage {
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

  @override
  Future<void> migrateLegacyCredentials(SharedPreferences prefs) async {
    final legacyAccess = prefs.getString('access_token');
    final legacyRefresh = prefs.getString('refresh_token');

    if (legacyAccess != null && legacyAccess.isNotEmpty) {
      final currentAccess = await readAccessToken();
      if (currentAccess == null || currentAccess.isEmpty) {
        final ok = await writeCredentials(legacyAccess, legacyRefresh);
        if (!ok) {
          throw const FormatException(
            'Failed to migrate legacy credentials to secure storage',
          );
        }
      }
    }

    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session Lifecycle & Gated Completer Integration Tests', () {
    test(
      '1. Account replacement during active credential write discards stale User A write',
      () async {
        final storage = CompleterPausableStorage();
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
        final startFuture = coordinator.startSession(
          accessToken: 'user_b_token',
          refreshToken: 'user_b_refresh_token',
        );

        // Release User A's paused storage write
        storage.releaseWriteCompleter!.complete();

        final result = await commitFuture;
        final userBSession = await startFuture;

        // Assert User A's commit was discarded and User B remains active in memory and storage
        expect(result, isNull);
        expect(coordinator.currentSessionId, userBSession.sessionId);
        expect(coordinator.activeAccessToken, 'user_b_token');
        expect(storage.accessToken, 'user_b_token');
        expect(storage.refreshToken, 'user_b_refresh_token');
      },
    );

    test(
      '2. Account replacement during refresh-failure cleanup preserves User B session',
      () async {
        final storage = CompleterPausableStorage();
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
        final startFuture = coordinator.startSession(
          accessToken: 'user_b_token',
          refreshToken: 'user_b_refresh_token',
        );

        // Release User A's paused storage cleanup
        storage.releaseClearCompleter!.complete();

        final cleared = await failureFuture;
        final userBSession = await startFuture;

        // Assert User A cleanup returned false and User B remains active in memory and storage
        expect(cleared, isFalse);
        expect(coordinator.currentSessionId, userBSession.sessionId);
        expect(coordinator.activeAccessToken, 'user_b_token');
        expect(storage.accessToken, 'user_b_token');
        expect(storage.refreshToken, 'user_b_refresh_token');
      },
    );

    test(
      '3. Logout during refresh persistence discards refreshed credentials',
      () async {
        final storage = CompleterPausableStorage();
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
      },
    );

    test(
      '4. Session initialization racing with login preserves login session',
      () async {
        final storage = CompleterPausableStorage();
        storage.accessToken = 'old_restored_token';
        storage.readStartedCompleter = Completer<void>();
        storage.releaseReadCompleter = Completer<void>();

        final coordinator = SessionCoordinator(storage);

        // Trigger restore (pauses during readAccessToken)
        final restoreFuture = coordinator.restoreSession();

        await storage.readStartedCompleter!.future;

        // User B logs in before restore completes
        final startFuture = coordinator.startSession(
          accessToken: 'new_login_token',
        );

        // Release storage read
        storage.releaseReadCompleter!.complete();

        await restoreFuture;
        final userBSession = await startFuture;

        // Assert login session was preserved in memory and storage
        expect(coordinator.currentSessionId, userBSession.sessionId);
        expect(coordinator.activeAccessToken, 'new_login_token');
        expect(storage.accessToken, 'new_login_token');
      },
    );

    test(
      '5. Failed credential deletion propagates error on clearSession',
      () async {
        final storage = CompleterPausableStorage();
        storage.shouldFailClear = true;

        final coordinator = SessionCoordinator(storage);
        await coordinator.startSession(accessToken: 'active_token');

        await expectLater(
          coordinator.clearSession(),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      '6. Instance-scoped refresh futures do not cross-contaminate independent coordinator instances',
      () async {
        final storage1 = CompleterPausableStorage();
        final storage2 = CompleterPausableStorage();

        final coordinator1 = SessionCoordinator(storage1);
        final coordinator2 = SessionCoordinator(storage2);

        await coordinator1.startSession(accessToken: 'token_1');
        await coordinator2.startSession(accessToken: 'token_2');

        expect(
          coordinator1.currentSessionId,
          isNot(coordinator2.currentSessionId),
        );
        expect(coordinator1.inFlightRefreshFuture, isNull);
        expect(coordinator2.inFlightRefreshFuture, isNull);
      },
    );

    test(
      '7. Legacy SharedPreferences credentials migrate safely to CredentialStorage and are cleared',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'legacy_access_token',
          'refresh_token': 'legacy_refresh_token',
        });
        final prefs = await SharedPreferences.getInstance();

        final storage = CompleterPausableStorage();

        // Ensure storage is empty before migration
        expect(await storage.readAccessToken(), isNull);

        // Perform migration
        await storage.migrateLegacyCredentials(prefs);

        // Verify credentials migrated to storage
        expect(await storage.readAccessToken(), 'legacy_access_token');
        expect(await storage.readRefreshToken(), 'legacy_refresh_token');

        // Verify old SharedPreferences keys were removed
        expect(prefs.containsKey('access_token'), isFalse);
        expect(prefs.containsKey('refresh_token'), isFalse);
      },
    );

    test(
      '8. Failed migration throws FormatException and preserves legacy SharedPreferences keys',
      () async {
        SharedPreferences.setMockInitialValues({
          'access_token': 'legacy_access_token',
          'refresh_token': 'legacy_refresh_token',
        });
        final prefs = await SharedPreferences.getInstance();

        final storage = CompleterPausableStorage();
        storage.shouldFailRefreshToken = true; // Migration write will fail

        await expectLater(
          storage.migrateLegacyCredentials(prefs),
          throwsA(isA<FormatException>()),
        );

        // Verify legacy keys were NOT deleted on migration failure
        expect(prefs.containsKey('access_token'), isTrue);
        expect(prefs.containsKey('refresh_token'), isTrue);
      },
    );

    test(
      '9. Failed login persistence leaves SessionCoordinator unauthenticated',
      () async {
        final storage = CompleterPausableStorage();
        storage.shouldFailRefreshToken = true;

        final coordinator = SessionCoordinator(storage);

        await expectLater(
          coordinator.startSession(
            accessToken: 'login_access',
            refreshToken: 'login_refresh',
          ),
          throwsA(isA<FormatException>()),
        );

        // Verify coordinator remains unauthenticated on login persistence failure
        expect(coordinator.currentSession, isNull);
        expect(coordinator.activeAccessToken, isNull);
      },
    );

    test(
      '10. Session remains unauthenticated while login persistence is paused in storage',
      () async {
        final storage = CompleterPausableStorage();
        storage.writeStartedCompleter = Completer<void>();
        storage.releaseWriteCompleter = Completer<void>();

        final coordinator = SessionCoordinator(storage);

        // Trigger login start
        final startFuture = coordinator.startSession(
          accessToken: 'login_access',
          refreshToken: 'login_refresh',
        );

        // Wait until writeCredentials starts and pauses inside storage
        await storage.writeStartedCompleter!.future;

        // Assert session remains unauthenticated while persistence is paused
        expect(coordinator.currentSession, isNull);
        expect(coordinator.activeAccessToken, isNull);

        // Unblock storage write
        storage.releaseWriteCompleter!.complete();

        final activeSession = await startFuture;

        // Assert session becomes active only after persistence completes
        expect(coordinator.currentSession, isNotNull);
        expect(coordinator.currentSessionId, activeSession.sessionId);
        expect(coordinator.activeAccessToken, 'login_access');
      },
    );

    test(
      '11. Login A paused while Login B starts throws StateError for A, B owns memory and storage',
      () async {
        final storage = CompleterPausableStorage();
        storage.writeStartedCompleter = Completer<void>();
        storage.releaseWriteCompleter = Completer<void>();

        final coordinator = SessionCoordinator(storage);

        // Login A starts (pauses in storage write)
        final loginAFuture = coordinator.startSession(
          accessToken: 'user_a_token',
          refreshToken: 'user_a_refresh',
        );

        await storage.writeStartedCompleter!.future;

        // Login B starts while Login A is paused
        final loginBFuture = coordinator.startSession(
          accessToken: 'user_b_token',
          refreshToken: 'user_b_refresh',
        );

        // Release storage write
        storage.releaseWriteCompleter!.complete();

        // Login A throws StateError because it was superseded by Login B
        expect(loginAFuture, throwsA(isA<StateError>()));

        final userBSession = await loginBFuture;

        // Assert Login B owns memory and storage
        expect(coordinator.currentSessionId, userBSession.sessionId);
        expect(coordinator.activeAccessToken, 'user_b_token');
        expect(storage.accessToken, 'user_b_token');
        expect(storage.refreshToken, 'user_b_refresh');
      },
    );

    test(
      '12. Logout during pending login throws StateError for pending login and leaves session unauthenticated',
      () async {
        final storage = CompleterPausableStorage();
        storage.writeStartedCompleter = Completer<void>();
        storage.releaseWriteCompleter = Completer<void>();

        final coordinator = SessionCoordinator(storage);

        // Login A starts (pauses in storage write)
        final loginAFuture = coordinator.startSession(
          accessToken: 'user_a_token',
          refreshToken: 'user_a_refresh',
        );

        await storage.writeStartedCompleter!.future;

        // Logout called while Login A is paused
        final clearFuture = coordinator.clearSession();

        // Release storage write
        storage.releaseWriteCompleter!.complete();

        // Login A throws StateError because it was superseded by logout
        expect(loginAFuture, throwsA(isA<StateError>()));

        await clearFuture;

        // Assert session remains unauthenticated in memory and storage
        expect(coordinator.currentSession, isNull);
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
      },
    );
  });
}
