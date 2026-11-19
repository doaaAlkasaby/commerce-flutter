import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/features/tenant_selection/models/public_store_model.dart';
import '../models/storefront_model.dart';

class StorefrontRepository {
  final Dio _dio;

  StorefrontRepository(this._dio);

  Future<StorefrontModel> getStorefront() async {
    final response = await _dio.get(ApiEndpoints.storefront);
    final data = response.data['data'] ?? response.data;
    return StorefrontModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PublicStoreModel>> getPublicStores() async {
    final response = await _dio.get(ApiEndpoints.publicStorefrontTenants);
    final rawList = response.data['data'] as List? ?? [];
    return rawList
        .map((item) => PublicStoreModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
