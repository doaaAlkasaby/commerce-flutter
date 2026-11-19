import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/devices/presentation/providers/device_provider.dart';
import '../config/tenant_config.dart';
import '../constants/api_endpoints.dart';
import '../utils/app_logger.dart';
import 'api_logging_interceptor.dart';
import 'session_coordinator.dart';
import '../../main.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
SessionCoordinator sessionCoordinator(Ref ref) {
  return SessionCoordinator(SecureCredentialStorage(), sharedPreferences);
}

@Riverpod(keepAlive: true)
class AuthTokenNotifier extends _$AuthTokenNotifier {
  @override
  String? build() {
    final coordinator = ref.watch(sessionCoordinatorProvider);
    final activeToken = coordinator.activeAccessToken;

    if (activeToken == null) {
      Future.microtask(() async {
        final session = await coordinator.restoreSession();
        if (session != null && state == null) {
          state = session.accessToken;
        }
      });
    }

    return activeToken;
  }

  Future<void> setToken(String? token, {String? refreshToken}) async {
    final coordinator = ref.read(sessionCoordinatorProvider);
    if (token != null && token.isNotEmpty) {
      final effectiveRefresh =
          refreshToken ?? await coordinator.storage.readRefreshToken();
      await coordinator.startSession(
        accessToken: token,
        refreshToken: effectiveRefresh,
      );
    } else {
      try {
        await ref
            .read(deviceRegistrationProvider.notifier)
            .deactivateCurrentDeviceBeforeLogout();
      } catch (_) {}
      await coordinator.clearSession();
    }
    state = token;
  }

  void updateRefreshedToken(String token) {
    state = token;
  }
}

class StorageReadException implements Exception {
  final String message;
  const StorageReadException(this.message);

  @override
  String toString() => 'StorageReadException: $message';
}

bool _isGlobalAuthRoute(String path) {
  final p = path.toLowerCase();
  return p.contains('/auth/login') ||
      p.contains('/auth/register') ||
      p.contains('/auth/refresh');
}

bool _isPermanentRefreshFailure(Object error) {
  if (error is StorageReadException) {
    return false;
  }
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      if (statusCode == 401 || statusCode == 403) {
        return true;
      }
      if (statusCode == 400) {
        final responseData = error.response?.data;
        if (responseData is Map) {
          final code = responseData['code']?.toString();
          if (code == 'INVALID_REFRESH_TOKEN' ||
              code == 'REFRESH_TOKEN_EXPIRED' ||
              code == 'REFRESH_TOKEN_REUSED') {
            return true;
          }
        }
        return false;
      }
      return false;
    }
    return false;
  }
  if (error is FormatException) {
    if (error.message.contains('Missing refresh token')) {
      return true;
    }
  }
  return false;
}

Future<String?> _performTokenRefresh(
  Ref ref, [
  HttpClientAdapter? adapter,
]) async {
  final coordinator = ref.read(sessionCoordinatorProvider);
  final owningSessionId = coordinator.currentSessionId;
  if (owningSessionId == null) {
    return null;
  }

  try {
    String? refreshToken;
    try {
      refreshToken = await coordinator.storage.readRefreshToken();
    } catch (_) {
      throw const StorageReadException(
        'Failed to read refresh token from storage',
      );
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const FormatException('Missing refresh token');
    }

    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    refreshDio.interceptors.add(ApiLoggingInterceptor());
    if (adapter != null) {
      refreshDio.httpClientAdapter = adapter;
    }
    final refreshResponse = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
      final data = refreshResponse.data['data'] ?? refreshResponse.data;
      final newAccessToken =
          data['accessToken']?.toString() ?? data['access_token']?.toString();
      final newRefreshToken =
          data['refreshToken']?.toString() ?? data['refresh_token']?.toString();

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        final updatedSession = await coordinator.commitRefreshedTokens(
          owningSessionId: owningSessionId,
          newAccessToken: newAccessToken,
          newRefreshToken: newRefreshToken,
        );

        if (updatedSession != null) {
          ref
              .read(authTokenProvider.notifier)
              .updateRefreshedToken(newAccessToken);
          return newAccessToken;
        } else {
          throw const FormatException(
            'Failed to persist refreshed credentials or session changed',
          );
        }
      }
    }
    throw const FormatException('Invalid refresh response payload');
  } catch (e) {
    if (_isPermanentRefreshFailure(e)) {
      final clearedActiveSession = await coordinator.handleRefreshFailure(
        owningSessionId,
      );
      if (clearedActiveSession && coordinator.currentSessionId == null) {
        await ref.read(authTokenProvider.notifier).setToken(null);
      }
    }
    rethrow;
  } finally {
    if (coordinator.currentSessionId == owningSessionId) {
      coordinator.inFlightRefreshFuture = null;
    }
  }
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
        if (!_isGlobalAuthRoute(ApiEndpoints.baseUrl))
          'X-Tenant-Slug': tenantSlug,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ),
  );

  dio.interceptors.add(ApiLoggingInterceptor());

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
        options.extra.putIfAbsent(
          'owningSessionId',
          () => coordinator.currentSessionId,
        );
        options.extra.putIfAbsent('owningTenantSlug', () => tenantSlug);

        final currentToken = ref.read(authTokenProvider);
        if (currentToken != null && currentToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $currentToken';
        }
        AppLogger.apiLog(
          method: options.method,
          url: '${options.baseUrl}${options.path}',
          queryParameters: options.queryParameters,
          data: options.data,
        );
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.apiLog(
          method: response.requestOptions.method,
          url:
              '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          statusCode: response.statusCode,
          responseData: response.data,
        );
        return handler.next(response);
      },
      onError: (error, handler) async {
        AppLogger.apiLog(
          method: error.requestOptions.method,
          url: '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          statusCode: error.response?.statusCode,
          responseData: error.response?.data,
          error: error.message,
        );

        final is401 = error.response?.statusCode == 401;
        final isAuthRoute =
            error.requestOptions.path.contains('auth/login') ||
            error.requestOptions.path.contains('auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        final requestSessionId = error.requestOptions.extra['owningSessionId']
            ?.toString();
        final requestTenantSlug = error.requestOptions.extra['owningTenantSlug']
            ?.toString();
        final activeSessionId = coordinator.currentSessionId;
        final currentTenantSlug = ref.read(selectedTenantSlugProvider);

        // Session & tenant retry guard: never retry if session or tenant changed!
        if (requestSessionId != activeSessionId ||
            requestTenantSlug != currentTenantSlug) {
          return handler.next(error);
        }

        if (is401 && !isAuthRoute && !alreadyRetried) {
          error.requestOptions.extra['retried'] = true;

          final currentToken = ref.read(authTokenProvider);
          final requestToken = error.requestOptions.headers['Authorization']
              ?.toString()
              .replaceAll('Bearer ', '');

          // If token was already refreshed by a concurrent request while queued, retry directly!
          if (currentToken != null &&
              currentToken.isNotEmpty &&
              currentToken != requestToken) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $currentToken';
            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }

          try {
            if (activeSessionId != null) {
              coordinator.inFlightRefreshFuture ??= _performTokenRefresh(
                ref,
                dio.httpClientAdapter,
              );
              final newAccessToken = await coordinator.inFlightRefreshFuture;

              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                if (ref.read(selectedTenantSlugProvider) != currentTenantSlug ||
                    coordinator.currentSessionId != activeSessionId) {
                  return handler.next(error);
                }

                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                opts.headers['X-Tenant-Slug'] = currentTenantSlug;

                final cloneReq = await dio.fetch(opts);
                return handler.resolve(cloneReq);
              }
            }
          } catch (refreshError) {
            if (!_isPermanentRefreshFailure(refreshError)) {
              final transientError = DioException(
                requestOptions: error.requestOptions,
                response: refreshError is DioException
                    ? refreshError.response
                    : null,
                type: refreshError is DioException
                    ? refreshError.type
                    : DioExceptionType.unknown,
                error: refreshError is DioException
                    ? refreshError.error
                    : refreshError,
                message: refreshError is DioException
                    ? refreshError.message
                    : refreshError.toString(),
              );
              return handler.next(transientError);
            }
            return handler.next(error);
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}
