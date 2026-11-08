import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/storefront_model.dart';

class StorefrontRepository {
  final Dio _dio;

  StorefrontRepository(this._dio);

  Future<StorefrontModel> getStorefront() async {
    final response = await _dio.get(ApiEndpoints.storefront);
    final data = response.data['data'] ?? response.data;
    return StorefrontModel.fromJson(data as Map<String, dynamic>);
  }
}
