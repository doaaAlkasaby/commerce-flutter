import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/core/network/api_response.dart';
import '../models/auth_response_models.dart';

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<ApiResponse<UserDto>> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.usersMe);
    return ApiResponse.fromJson(
      response.data,
      (json) => UserDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
