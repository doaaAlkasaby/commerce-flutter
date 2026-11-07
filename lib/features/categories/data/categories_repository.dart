import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/category_detail_model.dart';

class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository(this._dio);

  Future<List<MainCategoryModel>> getMainCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categoriesActive);
      final success = response.data['success'] ?? false;
      if (success) {
        final list = response.data['data'] as List? ?? [];
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return MainCategoryModel(
            id: map['id']?.toString() ?? '',
            name: map['name']?.toString() ?? '',
            iconName: 'toys',
            imageUrl: map['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?q=80&w=600&auto=format&fit=crop',
            hasChildren: map['hasChildren'] ?? false,
            subCategories: [],
            directProducts: [],
          );
        }).toList();
      }
    } catch (_) {}

    return const [];
  }

  Future<List<MainCategoryModel>> getCategoryChildren(String categoryId) async {
    try {
      final response = await _dio.get(ApiEndpoints.categoryChildren(categoryId));
      final success = response.data['success'] ?? false;
      if (success) {
        final list = response.data['data'] as List? ?? [];
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return MainCategoryModel(
            id: map['id']?.toString() ?? '',
            name: map['name']?.toString() ?? '',
            iconName: 'toys',
            imageUrl: map['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?q=80&w=600&auto=format&fit=crop',
            hasChildren: map['hasChildren'] ?? false,
            subCategories: [],
            directProducts: [],
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
