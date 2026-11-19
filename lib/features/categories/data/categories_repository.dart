import 'package:dio/dio.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/category_detail_model.dart';

class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository(this._dio);

  Future<List<MainCategoryModel>> getMainCategories() async {
    final response = await _dio.get(ApiEndpoints.categoriesActive);
    final success = response.data['success'] ?? false;
    if (success) {
      final list = response.data['data'] as List? ?? [];
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final rawImg = map['imageUrl']?.toString() ?? '';
        return MainCategoryModel(
          id: map['id']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          iconName: 'toys',
          imageUrl: AppEnvironment.resolveImageUrl(rawImg),
          hasChildren: map['hasChildren'] ?? false,
          subCategories: [],
          directProducts: [],
        );
      }).toList();
    }
    return const [];
  }

  Future<List<MainCategoryModel>> getCategoryChildren(String categoryId) async {
    final response = await _dio.get(ApiEndpoints.categoryChildren(categoryId));
    final success = response.data['success'] ?? false;
    if (success) {
      final list = response.data['data'] as List? ?? [];
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final rawImg = map['imageUrl']?.toString() ?? '';
        return MainCategoryModel(
          id: map['id']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          iconName: 'toys',
          imageUrl: AppEnvironment.resolveImageUrl(rawImg),
          hasChildren: map['hasChildren'] ?? false,
          subCategories: [],
          directProducts: [],
        );
      }).toList();
    }
    return const [];
  }
}
