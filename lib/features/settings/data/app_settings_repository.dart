import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/core/network/api_response.dart';
import '../models/app_settings_model.dart';

class AppSettingsRepository {
  final Dio _dio;

  AppSettingsRepository(this._dio);

  Future<ApiResponse<AppSettingsModel>> getAppSettings() async {
    final response = await _dio.get(ApiEndpoints.appSettings);
    return ApiResponse.fromJson(
      response.data,
      (json) => AppSettingsModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
