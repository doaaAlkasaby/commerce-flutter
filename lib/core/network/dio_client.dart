import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/tenant_config.dart';
import '../constants/api_endpoints.dart';
import '../utils/app_logger.dart';
import 'session_coordinator.dart';
import '../../main.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
SessionCoordinator sessionCoordinator(Ref ref) {
  return SessionCoordinator(SharedPreferencesCredentialStorage(sharedPreferences));
}

@Riverpod(keepAlive: true)
class AuthTokenNotifier extends _$AuthTokenNotifier {
  @override
  String? build() {
    final coordinator = ref.watch(sessionCoordinatorProvider);
    return coordinator.activeAccessToken;
  }

  Future<void> setToken(String? token) async {
    final coordinator = ref.read(sessionCoordinatorProvider);
    if (token != null && token.isNotEmpty) {
      await coordinator.startSession(accessToken: token);
    } else {
      await coordinator.clearSession();
    }
    state = token;
  }

  void updateRefreshedToken(String token) {
    state = token;
  }
}

bool _isGlobalAuthRoute(String path) {
  final p = path.toLowerCase();
  return p.contains('/auth/login') ||
      p.contains('/auth/register') ||
      p.contains('/auth/refresh');
}

Future<String?> _performTokenRefresh(Ref ref, [HttpClientAdapter? adapter]) async {
  final coordinator = ref.read(sessionCoordinatorProvider);
  final owningSessionId = coordinator.currentSessionId;
  if (owningSessionId == null) {
    return null;
  }

  try {
    String? refreshToken;
    try {
      refreshToken = await coordinator.storage.readRefreshToken();
    } catch (_) {}

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Missing refresh token');
    }

    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    if (adapter != null) {
      refreshDio.httpClientAdapter = adapter;
    }
    final refreshResponse = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
      final data = refreshResponse.data['data'] ?? refreshResponse.data;
      final newAccessToken = data['accessToken']?.toString() ?? data['access_token']?.toString();
      final newRefreshToken = data['refreshToken']?.toString() ?? data['refresh_token']?.toString();

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        final updatedSession = await coordinator.commitRefreshedTokens(
          owningSessionId: owningSessionId,
          newAccessToken: newAccessToken,
          newRefreshToken: newRefreshToken,
        );

        if (updatedSession != null) {
          ref.read(authTokenProvider.notifier).updateRefreshedToken(newAccessToken);
          return newAccessToken;
        }
      }
    }
  } catch (_) {
    final clearedActiveSession = await coordinator.handleRefreshFailure(owningSessionId);
    if (clearedActiveSession && coordinator.currentSessionId == null) {
      await ref.read(authTokenProvider.notifier).setToken(null);
    }
    rethrow;
  } finally {
    coordinator.inFlightRefreshFuture = null;
  }
  return null;
}

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final tenantSlug = ref.watch(selectedTenantSlugProvider);
  final token = ref.watch(authTokenProvider);
  final coordinator = ref.watch(sessionCoordinatorProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (!_isGlobalAuthRoute(ApiEndpoints.baseUrl)) 'X-Tenant-Slug': tenantSlug,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        if (!_isGlobalAuthRoute(options.path)) {
          options.headers['X-Tenant-Slug'] = tenantSlug;
        } else {
          options.headers.remove('X-Tenant-Slug');
        }
        options.headers.remove('X-Tenant-Id');

        // Preserve immutable original request ownership metadata
        options.extra.putIfAbsent('owningSessionId', () => coordinator.currentSessionId);
        options.extra.putIfAbsent('owningTenantSlug', () => tenantSlug);

        final currentToken = ref.read(authTokenProvider);
        if (currentToken != null && currentToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $currentToken';
        }
        AppLogger.apiLog(
          method: options.method,
          url: '${options.baseUrl}${options.path}',
        );
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.apiLog(
          method: response.requestOptions.method,
          url: '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          statusCode: response.statusCode,
        );
        return handler.next(response);
      },
      onError: (error, handler) async {
        AppLogger.apiLog(
          method: error.requestOptions.method,
          url: '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          statusCode: error.response?.statusCode,
          error: error.message,
        );

        final is401 = error.response?.statusCode == 401;
        final isAuthRoute = error.requestOptions.path.contains('auth/login') ||
            error.requestOptions.path.contains('auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        final requestSessionId = error.requestOptions.extra['owningSessionId']?.toString();
        final requestTenantSlug = error.requestOptions.extra['owningTenantSlug']?.toString();
        final activeSessionId = coordinator.currentSessionId;
        final currentTenantSlug = ref.read(selectedTenantSlugProvider);

        // Session & tenant retry guard: never retry if session or tenant changed!
        if (requestSessionId != activeSessionId || requestTenantSlug != currentTenantSlug) {
          return handler.next(error);
        }

        if (is401 && !isAuthRoute && !alreadyRetried) {
          error.requestOptions.extra['retried'] = true;

          final currentToken = ref.read(authTokenProvider);
          final requestToken = error.requestOptions.headers['Authorization']?.toString().replaceAll('Bearer ', '');

          // If token was already refreshed by a concurrent request while queued, retry directly!
          if (currentToken != null && currentToken.isNotEmpty && currentToken != requestToken) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $currentToken';
            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }

          try {
            if (activeSessionId != null) {
              coordinator.inFlightRefreshFuture ??= _performTokenRefresh(ref, dio.httpClientAdapter);
              final newAccessToken = await coordinator.inFlightRefreshFuture;

              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                if (ref.read(selectedTenantSlugProvider) != currentTenantSlug || coordinator.currentSessionId != activeSessionId) {
                  return handler.next(error);
                }

                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                opts.headers['X-Tenant-Slug'] = currentTenantSlug;

                final cloneReq = await dio.fetch(opts);
                return handler.resolve(cloneReq);
              }
            }
          } catch (_) {
            return handler.next(error);
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}
