import '../../home/models/home_response_model.dart';

class SubCategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<ProductModel> products;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.products,
  });
}

class MainCategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String imageUrl;
  final bool hasChildren;
  final List<MainCategoryModel> subCategories;
  final List<ProductModel> directProducts;

  const MainCategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.imageUrl,
    this.hasChildren = false,
    this.subCategories = const [],
    this.directProducts = const [],
  });
}
