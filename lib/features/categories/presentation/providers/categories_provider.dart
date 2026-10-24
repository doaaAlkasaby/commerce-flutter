import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
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
