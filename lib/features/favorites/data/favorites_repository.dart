import 'package:dio/dio.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';

class WishlistProductModel {
  final String id;
  final String name;
  final String slug;
  final String status;
  final String image;
  final List<String> images;

  const WishlistProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.image,
    this.images = const [],
  });

  factory WishlistProductModel.fromJson(Map<String, dynamic> json) {
    List<String> imgUrls = [];
    String primaryUrl = '';
    if (json['images'] is List) {
      for (final img in json['images']) {
        if (img is Map) {
          final rawUrl = img['url']?.toString() ?? '';
          if (rawUrl.isNotEmpty) {
            final resolved = AppEnvironment.resolveImageUrl(rawUrl);
            imgUrls.add(resolved);
            if (primaryUrl.isEmpty || img['isPrimary'] == true) {
              primaryUrl = resolved;
            }
          }
        }
      }
    }
    return WishlistProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      image: primaryUrl.isNotEmpty
          ? primaryUrl
          : (imgUrls.isNotEmpty ? imgUrls.first : ''),
      images: imgUrls,
    );
  }
}

class WishlistItemModel {
  final String id;
  final String addedAt;
  final WishlistProductModel product;

  const WishlistItemModel({
    required this.id,
    required this.addedAt,
    required this.product,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id']?.toString() ?? '',
      addedAt: json['addedAt']?.toString() ?? '',
      product: WishlistProductModel.fromJson(
        json['product'] is Map<String, dynamic>
            ? json['product'] as Map<String, dynamic>
            : json,
      ),
    );
  }
}

class WishlistResponseModel {
  final String id;
  final List<WishlistItemModel> items;
  final int count;

  const WishlistResponseModel({
    required this.id,
    required this.items,
    required this.count,
  });

  factory WishlistResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List? ?? [])
        .map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return WishlistResponseModel(
      id: json['id']?.toString() ?? '',
      items: list,
      count: json['count'] is int ? json['count'] as int : list.length,
    );
  }
}

class FavoritesRepository {
  final Dio _dio;

  FavoritesRepository(this._dio);

  Future<WishlistResponseModel> getWishlist() async {
    final response = await _dio.get(ApiEndpoints.wishlist);
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return WishlistResponseModel.fromJson(data);
  }

  Future<void> addToWishlist(String productId) async {
    await _dio.post(ApiEndpoints.wishlistItems, data: {'productId': productId});
  }

  Future<void> removeFromWishlist(String productId) async {
    await _dio.delete(ApiEndpoints.wishlistByProduct(productId));
  }

  Future<bool> checkWishlist(String productId) async {
    final response = await _dio.get(ApiEndpoints.wishlistCheck(productId));
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return data['isInWishlist'] as bool? ?? false;
  }
}
