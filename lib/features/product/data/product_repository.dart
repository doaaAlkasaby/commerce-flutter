import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class ProductRepository {
  final Dio _dio;

  ProductRepository(this._dio);

  Future<ProductModel> getProductDetails(String id) async {
    final response = await _dio.get(ApiEndpoints.productById(id));
    final data = response.data['data'] ?? response.data;
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProductModel>> searchProducts({
    String search = '',
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? brandId,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'page': page,
        'limit': limit,
      };
      if (search.isNotEmpty) queryParams['search'] = search;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['categoryId'] = categoryId;
      if (brandId != null && brandId.isNotEmpty) queryParams['brandId'] = brandId;

      final response = await _dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );
      final rawData = response.data['data'];
      final List list = rawData is List ? rawData : (rawData['products'] ?? rawData['items'] ?? []);
      return list.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ProductModel>> getProductsByEndpoint(String endpoint, {int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: {'page': page, 'limit': limit},
      );
      final rawData = response.data['data'];
      final List list = rawData is List ? rawData : (rawData['products'] ?? rawData['items'] ?? []);
      return list.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback seed products for offline/testing
      return [
        ProductModel(
          id: 'p1',
          name: 'Classic T-Shirt',
          slug: 'classic-t-shirt',
          priceInfo: const ProductPriceModel(originalPrice: 29.99, finalPrice: 23.99, discountPercentage: 20.01),
          image: 'https://placehold.co/800x800?text=Classic%20T-Shirt',
          isFavorite: false,
          rating: 4.8,
          reviewCount: 120,
          hasVariants: false,
        ),
        ProductModel(
          id: 'p2',
          name: 'Premium Hoodie',
          slug: 'premium-hoodie',
          priceInfo: const ProductPriceModel(originalPrice: 59.99, finalPrice: 50.99, discountPercentage: 15),
          image: 'https://placehold.co/800x800?text=Premium%20Hoodie',
          isFavorite: true,
          rating: 4.9,
          reviewCount: 86,
          hasVariants: true,
        ),
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getProductReviews(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.productReviews(id));
      final list = response.data['data'] as List? ?? response.data as List? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addReview(String id, double rating, String comment) async {
    await _dio.post(ApiEndpoints.productReviews(id), data: {
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> toggleFavorite(String productId, bool isFavorite) async {
    if (isFavorite) {
      await _dio.post(ApiEndpoints.wishlistItems, data: {'productId': productId});
    } else {
      await _dio.delete(ApiEndpoints.wishlistByProduct(productId));
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    await _dio.post(ApiEndpoints.cartItems, data: {
      'variantId': productId,
      'quantity': quantity,
    });
  }
}
