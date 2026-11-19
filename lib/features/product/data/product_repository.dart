import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/models/review_models.dart';

class PaginatedProductsResultModel {
  final List<ProductModel> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const PaginatedProductsResultModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });
}

class ProductRepository {
  final Dio _dio;

  ProductRepository(this._dio);

  Future<ProductModel> getProductDetails(String id) async {
    final response = await _dio.get(ApiEndpoints.productById(id));
    final data = response.data['data'] ?? response.data;
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PaginatedProductsResultModel> getPaginatedProducts({
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
    final queryParams = <String, dynamic>{
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      'page': page,
      'limit': limit,
    };
    if (search.isNotEmpty) queryParams['search'] = search;
    if (minPrice != null) queryParams['minPrice'] = minPrice;
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['categoryId'] = categoryId;
    }
    if (brandId != null && brandId.isNotEmpty) {
      queryParams['brandId'] = brandId;
    }

    final response = await _dio.get(
      ApiEndpoints.products,
      queryParameters: queryParams,
    );
    final rawData = response.data['data'];
    final List list = rawData is List
        ? rawData
        : (rawData is Map
              ? (rawData['products'] ?? rawData['items'] ?? [])
              : []);
    final items = list
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();

    int totalPages = 1;
    int totalItems = items.length;
    int respPage = page;
    int respLimit = limit;

    if (rawData is Map && rawData['pagination'] is Map) {
      final pMap = rawData['pagination'] as Map<String, dynamic>;
      respPage = pMap['page'] is int ? pMap['page'] as int : page;
      respLimit = pMap['limit'] is int ? pMap['limit'] as int : limit;
      totalItems = pMap['totalItems'] is int
          ? pMap['totalItems'] as int
          : items.length;
      totalPages = pMap['totalPages'] is int ? pMap['totalPages'] as int : 1;
    }

    return PaginatedProductsResultModel(
      items: items,
      page: respPage,
      limit: respLimit,
      totalItems: totalItems,
      totalPages: totalPages,
    );
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
    final result = await getPaginatedProducts(
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      categoryId: categoryId,
      brandId: brandId,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      limit: limit,
    );
    return result.items;
  }

  Future<List<ProductModel>> getProductsByEndpoint(
    String endpoint, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: {'page': page, 'limit': limit},
    );
    final rawData = response.data['data'];
    final List list = rawData is List
        ? rawData
        : (rawData is Map
              ? (rawData['products'] ?? rawData['items'] ?? [])
              : []);
    return list
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedReviewsResultModel> getPaginatedProductReviews(
    String productId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.productReviews(productId),
      queryParameters: {'page': page, 'limit': limit},
    );
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return PaginatedReviewsResultModel.fromJson(data);
  }

  Future<ProductRatingSummaryModel> getProductRatingSummary(
    String productId,
  ) async {
    final response = await _dio.get(
      ApiEndpoints.productReviewsSummary(productId),
    );
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return ProductRatingSummaryModel.fromJson(data);
  }

  Future<ProductReviewModel> createProductReview(
    String productId, {
    required int rating,
    String? title,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'rating': rating,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    };
    final response = await _dio.post(
      ApiEndpoints.productReviews(productId),
      data: body,
    );
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return ProductReviewModel.fromJson(data);
  }

  Future<ProductReviewModel> updateProductReview(
    String productId,
    String reviewId, {
    int? rating,
    String? title,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'rating': ?rating,
      'title': ?title?.trim(),
      'comment': ?comment?.trim(),
    };
    final response = await _dio.patch(
      ApiEndpoints.productReviewById(productId, reviewId),
      data: body,
    );
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return ProductReviewModel.fromJson(data);
  }

  Future<void> deleteProductReview(String productId, String reviewId) async {
    await _dio.delete(ApiEndpoints.productReviewById(productId, reviewId));
  }

  Future<List<Map<String, dynamic>>> getProductReviews(String id) async {
    try {
      final result = await getPaginatedProductReviews(id);
      return result.items
          .map(
            (r) => {
              'id': r.id,
              'userName': r.user.name,
              'rating': r.rating,
              'comment': r.comment ?? r.title ?? '',
              'createdAt': r.createdAt,
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addReview(String id, double rating, String comment) async {
    await createProductReview(id, rating: rating.toInt(), comment: comment);
  }

  Future<void> toggleFavorite(String productId, bool isFavorite) async {
    if (isFavorite) {
      await _dio.post(
        ApiEndpoints.wishlistItems,
        data: {'productId': productId},
      );
    } else {
      await _dio.delete(ApiEndpoints.wishlistByProduct(productId));
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    await _dio.post(
      ApiEndpoints.cartItems,
      data: {'variantId': productId, 'quantity': quantity},
    );
  }
}
