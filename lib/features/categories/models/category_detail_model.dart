import '../../../core/config/app_environment.dart';
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

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawImg = json['imageUrl']?.toString();
    return SubCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: rawImg != null ? AppEnvironment.resolveImageUrl(rawImg) : '',
      products: (json['products'] as List? ?? [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  SubCategoryModel copyWith({List<ProductModel>? products}) {
    return SubCategoryModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      products: products ?? this.products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
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

  factory MainCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawImg = json['imageUrl']?.toString();
    return MainCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconName: json['iconName']?.toString() ?? '',
      imageUrl: rawImg != null ? AppEnvironment.resolveImageUrl(rawImg) : '',
      hasChildren: json['hasChildren'] ?? false,
      subCategories: (json['subCategories'] as List? ?? [])
          .map((c) => MainCategoryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  MainCategoryModel copyWith({List<ProductModel>? directProducts}) {
    return MainCategoryModel(
      id: id,
      name: name,
      iconName: iconName,
      imageUrl: imageUrl,
      hasChildren: hasChildren,
      subCategories: subCategories,
      directProducts: directProducts ?? this.directProducts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'imageUrl': imageUrl,
      'hasChildren': hasChildren,
      'subCategories': subCategories.map((c) => c.toJson()).toList(),
      'directProducts': directProducts.map((p) => p.toJson()).toList(),
    };
  }
}
