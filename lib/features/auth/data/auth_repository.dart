import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/core/network/api_response.dart';
import '../models/auth_response_models.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<ApiResponse<AuthDataDto>> login(String email, String password) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AuthDataDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AuthDataDto>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AuthDataDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _dio.post(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
  }

  Future<ApiResponse<void>> verifyEmail(String token) async {
    final response = await _dio.get(
      ApiEndpoints.verifyEmail,
      queryParameters: {'token': token},
    );
    return ApiResponse.fromJson(response.data, (_) {});
  }

  Future<ApiResponse<void>> resendVerification(String email) async {
    final response = await _dio.post(
      ApiEndpoints.resendVerification,
      data: {'email': email},
    );
    return ApiResponse.fromJson(response.data, (_) {});
  }

  Future<ApiResponse<void>> logoutAll() async {
    final response = await _dio.post(ApiEndpoints.logoutAll);
    return ApiResponse.fromJson(response.data, (_) {});
  }
}
