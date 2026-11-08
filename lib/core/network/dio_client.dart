import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/tenant_config.dart';
import '../constants/api_endpoints.dart';
import '../utils/app_logger.dart';
import '../../main.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
class AuthTokenNotifier extends _$AuthTokenNotifier {
  @override
  String? build() {
    try {
      return sharedPreferences.getString('access_token');
    } catch (_) {
      return null;
    }
  }

  void setToken(String? token) {
    state = token;
  }
}

bool _isGlobalAuthRoute(String path) {
  final p = path.toLowerCase();
  return p.contains('/auth/login') ||
      p.contains('/auth/register') ||
      p.contains('/auth/refresh');
}

Future<String?>? _inFlightRefreshFuture;

Future<String?> _performTokenRefresh(Ref ref) async {
  try {
    String? refreshToken;
    try {
      refreshToken = sharedPreferences.getString('refresh_token');
    } catch (_) {}

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Missing refresh token');
    }

    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    final refreshResponse = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
      final data = refreshResponse.data['data'] ?? refreshResponse.data;
      final newAccessToken = data['accessToken']?.toString() ?? data['access_token']?.toString();
      final newRefreshToken = data['refreshToken']?.toString() ?? data['refresh_token']?.toString();

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        try {
          await sharedPreferences.setString('access_token', newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await sharedPreferences.setString('refresh_token', newRefreshToken);
          }
        } catch (_) {}

        ref.read(authTokenProvider.notifier).setToken(newAccessToken);
        return newAccessToken;
      }
    }
  } catch (_) {
    try {
      await sharedPreferences.remove('access_token');
      await sharedPreferences.remove('refresh_token');
    } catch (_) {}
    ref.read(authTokenProvider.notifier).setToken(null);
  }
  return null;
}

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final tenantSlug = ref.watch(selectedTenantSlugProvider);
  final token = ref.watch(authTokenProvider);

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

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
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
          url: '${response.requestOptions.baseUrl}${response.requestOptions.path}',
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
        final isAuthRoute = error.requestOptions.path.contains('auth/login') ||
            error.requestOptions.path.contains('auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (is401 && !isAuthRoute && !alreadyRetried) {
          error.requestOptions.extra['retried'] = true;

          _inFlightRefreshFuture ??= _performTokenRefresh(ref);
          final newAccessToken = await _inFlightRefreshFuture;
          _inFlightRefreshFuture = null;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            final currentTenantSlug = ref.read(selectedTenantSlugProvider);
            if (currentTenantSlug != tenantSlug) {
              return handler.next(error);
            }

            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            opts.headers['X-Tenant-Slug'] = currentTenantSlug;

            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}
