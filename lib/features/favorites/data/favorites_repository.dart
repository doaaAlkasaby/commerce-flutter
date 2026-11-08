import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class FavoritesRepository {
  final Dio _dio;

  FavoritesRepository(this._dio);

  Future<List<ProductModel>> getWishlist() async {
    try {
      final response = await _dio.get(ApiEndpoints.wishlist);
      final rawData = response.data['data'];
      final List list = rawData is List
          ? rawData
          : (rawData['items'] ?? rawData['products'] ?? []);
      return list.map((item) {
        final prodMap = item['product'] ?? item;
        return ProductModel.fromJson(
          prodMap is Map<String, dynamic> ? prodMap : item,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    await _dio.delete(ApiEndpoints.wishlistByProduct(productId));
  }
}
