import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../../data/categories_repository.dart';
import '../../models/category_detail_model.dart';

part 'categories_provider.g.dart';

@Riverpod(keepAlive: true)
CategoriesRepository categoriesRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return CategoriesRepository(dio);
}

@riverpod
Future<List<MainCategoryModel>> mainCategories(Ref ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  return repository.getMainCategories();
}

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> activeCategoriesList(Ref ref) async {
  try {
    final dio = ref.watch(dioClientProvider);
    final response = await dio.get(ApiEndpoints.categoriesActive);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  } catch (_) {
    return [];
  }
}

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> activeBrandsList(Ref ref) async {
  try {
    final dio = ref.watch(dioClientProvider);
    final response = await dio.get(ApiEndpoints.brandsActive);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  } catch (_) {
    return [];
  }
}
