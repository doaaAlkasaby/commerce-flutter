import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/tenant_config.dart';
import '../constants/api_endpoints.dart';
import '../utils/app_logger.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
class AuthTokenNotifier extends _$AuthTokenNotifier {
  @override
  String? build() => null;

  void setToken(String? token) {
    state = token;
  }
}

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final tenant = ref.watch(tenantProvider);
  final token = ref.watch(authTokenProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Tenant-Id': tenant.tenantId,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Tenant-Id'] = tenant.tenantId;
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

        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('auth/login') &&
            !error.requestOptions.path.contains('auth/refresh')) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');

            if (refreshToken != null && refreshToken.isNotEmpty) {
              final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
              final refreshResponse = await refreshDio.post(
                ApiEndpoints.refreshToken,
                data: {'refreshToken': refreshToken},
                options: Options(headers: {'X-Tenant-Id': tenant.tenantId}),
              );

              if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
                final data = refreshResponse.data['data'] ?? refreshResponse.data;
                final newAccessToken = data['accessToken']?.toString();

                if (newAccessToken != null && newAccessToken.isNotEmpty) {
                  await prefs.setString('access_token', newAccessToken);
                  ref.read(authTokenProvider.notifier).setToken(newAccessToken);

                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final cloneReq = await Dio().fetch(opts);
                  return handler.resolve(cloneReq);
                }
              }
            }
          } catch (_) {}
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}
