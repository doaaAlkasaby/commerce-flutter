import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CredentialStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<bool> writeCredentials(String accessToken, String? refreshToken);
  Future<bool> clearCredentials();
  Future<void> migrateLegacyCredentials(SharedPreferences prefs);
}

class SecureCredentialStorage implements CredentialStorage {
  final FlutterSecureStorage _secureStorage;

  SecureCredentialStorage([FlutterSecureStorage? secureStorage])
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  @override
  Future<String?> readAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  @override
  Future<String?> readRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  @override
  Future<bool> writeCredentials(
    String accessToken,
    String? refreshToken,
  ) async {
    try {
      await _secureStorage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      } else {
        await _secureStorage.delete(key: 'refresh_token');
      }
      return true;
    } catch (_) {
      try {
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');
      } catch (_) {}
      return false;
    }
  }

  @override
  Future<bool> clearCredentials() async {
    try {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      return true;
    } catch (_) {
      return false;
    }
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

class SharedPreferencesCredentialStorage implements CredentialStorage {
  final SharedPreferences _prefs;

  SharedPreferencesCredentialStorage(this._prefs);

  @override
  Future<String?> readAccessToken() async => _prefs.getString('access_token');

  @override
  Future<String?> readRefreshToken() async => _prefs.getString('refresh_token');

  @override
  Future<bool> writeCredentials(
    String accessToken,
    String? refreshToken,
  ) async {
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

  @override
  Future<void> migrateLegacyCredentials(SharedPreferences prefs) async {}
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
  final SharedPreferences? _legacyPrefs;
  UserSession? _currentSession;
  int _operationRevision = 0;
  Future<void> _lock = Future.value();
  Future<String?>? inFlightRefreshFuture;

  SessionCoordinator(this._storage, [this._legacyPrefs]) {
    restoreSession().catchError((_) => null);
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
    _lock = _lock
        .then((_) async {
          try {
            final result = await action();
            completer.complete(result);
          } catch (e, st) {
            completer.completeError(e, st);
          }
        })
        .catchError((_) {});
    return completer.future;
  }

  Future<UserSession?> restoreSession() async {
    final currentRev = _operationRevision;
    return _enqueue(() async {
      if (_operationRevision != currentRev || _currentSession != null) {
        return _currentSession;
      }

      if (_legacyPrefs != null) {
        await _storage.migrateLegacyCredentials(_legacyPrefs);
      }

      final token = await _storage.readAccessToken();
      if (_operationRevision != currentRev || _currentSession != null) {
        return _currentSession;
      }

      if (token != null && token.isNotEmpty) {
        final refreshToken = await _storage.readRefreshToken();
        if (_operationRevision != currentRev || _currentSession != null) {
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

  Future<UserSession> startSession({
    required String accessToken,
    String? refreshToken,
  }) async {
    _operationRevision++;
    final currentRev = _operationRevision;
    final pendingSessionId = _generateSessionId();
    inFlightRefreshFuture = null;

    // 1. Invalidate previous session immediately in memory
    _currentSession = null;

    // 2. Persist credentials in queue and publish only if operation is still current
    return _enqueue(() async {
      final ok = await _storage.writeCredentials(accessToken, refreshToken);
      if (!ok) {
        throw const FormatException(
          'Failed to persist login credentials to storage',
        );
      }

      if (_operationRevision != currentRev) {
        throw StateError(
          'Login operation was superseded by a newer session operation',
        );
      }

      final newSession = UserSession(
        sessionId: pendingSessionId,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      _currentSession = newSession;
      return newSession;
    });
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
    _operationRevision++;
    _currentSession = null;
    inFlightRefreshFuture = null;

    await _enqueue(() async {
      final ok = await _storage.clearCredentials();
      if (!ok) {
        throw const FormatException('Failed to clear credentials from storage');
      }
    });
  }

  Future<UserSession?> commitRefreshedTokens({
    required String owningSessionId,
    required String newAccessToken,
    String? newRefreshToken,
  }) async {
    return _enqueue(() async {
      if (_currentSession == null ||
          _currentSession!.sessionId != owningSessionId) {
        return null;
      }

      final effectiveRefreshToken =
          newRefreshToken ?? _currentSession!.refreshToken;
      final ok = await _storage.writeCredentials(
        newAccessToken,
        effectiveRefreshToken,
      );
      if (!ok) {
        throw const FormatException('Failed to persist refreshed credentials');
      }

      if (_currentSession == null ||
          _currentSession!.sessionId != owningSessionId) {
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
      if (_currentSession == null ||
          _currentSession!.sessionId != failedSessionId) {
        return false;
      }

      final startRev = _operationRevision;
      await _storage.clearCredentials();

      if (_operationRevision != startRev ||
          _currentSession == null ||
          _currentSession!.sessionId != failedSessionId) {
        return false;
      }

      _operationRevision++;
      _currentSession = null;
      return true;
    });
  }
}
