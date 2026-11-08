import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CredentialStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<bool> writeCredentials(String accessToken, String? refreshToken);
  Future<bool> clearCredentials();
}

class SharedPreferencesCredentialStorage implements CredentialStorage {
  final SharedPreferences _prefs;

  SharedPreferencesCredentialStorage(this._prefs);

  @override
  Future<String?> readAccessToken() async => _prefs.getString('access_token');

  @override
  Future<String?> readRefreshToken() async => _prefs.getString('refresh_token');

  @override
  Future<bool> writeCredentials(String accessToken, String? refreshToken) async {
    final accessOk = await _prefs.setString('access_token', accessToken);
    if (!accessOk) return false;

    if (refreshToken != null && refreshToken.isNotEmpty) {
      final refreshOk = await _prefs.setString('refresh_token', refreshToken);
      if (!refreshOk) {
        // Atomic Rollback: remove access_token on partial write failure
        await _prefs.remove('access_token');
        return false;
      }
    }
    return true;
  }

  @override
  Future<bool> clearCredentials() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');

    final accessExists = _prefs.containsKey('access_token');
    final refreshExists = _prefs.containsKey('refresh_token');

    return !accessExists && !refreshExists;
  }
}

class UserSession {
  final String sessionId;
  final String accessToken;
  final String? refreshToken;

  const UserSession({
    required this.sessionId,
    required this.accessToken,
    this.refreshToken,
  });
}

class SessionCoordinator {
  static int _globalCounter = 0;
  final CredentialStorage _storage;
  UserSession? _currentSession;
  Future<void> _lock = Future.value();
  Future<String?>? inFlightRefreshFuture;

  SessionCoordinator(this._storage) {
    restoreSession();
  }

  static String _generateSessionId() {
    _globalCounter++;
    return 'session_$_globalCounter';
  }

  CredentialStorage get storage => _storage;
  UserSession? get currentSession => _currentSession;
  String? get activeAccessToken => _currentSession?.accessToken;
  String? get currentSessionId => _currentSession?.sessionId;

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _lock = _lock.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }).catchError((_) {});
    return completer.future;
  }

  Future<UserSession?> restoreSession() async {
    return _enqueue(() async {
      if (_currentSession != null) {
        return _currentSession;
      }

      final token = await _storage.readAccessToken();
      if (_currentSession != null) {
        return _currentSession;
      }

      if (token != null && token.isNotEmpty) {
        final refreshToken = await _storage.readRefreshToken();
        if (_currentSession != null) {
          return _currentSession;
        }

        _currentSession = UserSession(
          sessionId: _generateSessionId(),
          accessToken: token,
          refreshToken: refreshToken,
        );
      }
      return _currentSession;
    });
  }

  Future<UserSession> startSession({required String accessToken, String? refreshToken}) async {
    _currentSession = UserSession(
      sessionId: _generateSessionId(),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    final activeSession = _currentSession!;

    await _enqueue(() async {
      final ok = await _storage.writeCredentials(accessToken, refreshToken);
      if (!ok) {
        throw const FormatException('Failed to persist login credentials to local storage');
      }
    });

    return activeSession;
  }

  Future<UserSession?> updateToken(String newAccessToken) async {
    if (_currentSession != null) {
      final activeSessionId = _currentSession!.sessionId;
      return commitRefreshedTokens(
        owningSessionId: activeSessionId,
        newAccessToken: newAccessToken,
      );
    } else {
      return startSession(accessToken: newAccessToken);
    }
  }

  Future<void> clearSession() async {
    _currentSession = null;

    await _enqueue(() async {
      final ok = await _storage.clearCredentials();
      if (!ok) {
        throw const FormatException('Failed to clear credentials from local storage');
      }
    });
  }

  Future<UserSession?> commitRefreshedTokens({
    required String owningSessionId,
    required String newAccessToken,
    String? newRefreshToken,
  }) async {
    return _enqueue(() async {
      if (_currentSession == null || _currentSession!.sessionId != owningSessionId) {
        return null;
      }

      final effectiveRefreshToken = newRefreshToken ?? _currentSession!.refreshToken;
      final ok = await _storage.writeCredentials(newAccessToken, effectiveRefreshToken);
      if (!ok) {
        throw const FormatException('Failed to persist refreshed credentials');
      }

      if (_currentSession == null || _currentSession!.sessionId != owningSessionId) {
        return null;
      }

      _currentSession = UserSession(
        sessionId: owningSessionId,
        accessToken: newAccessToken,
        refreshToken: effectiveRefreshToken,
      );

      return _currentSession;
    });
  }

  Future<bool> handleRefreshFailure(String failedSessionId) async {
    return _enqueue(() async {
      if (_currentSession == null || _currentSession!.sessionId != failedSessionId) {
        return false;
      }

      await _storage.clearCredentials();

      if (_currentSession != null && _currentSession!.sessionId != failedSessionId) {
        return false;
      }

      _currentSession = null;
      return true;
    });
  }
}
