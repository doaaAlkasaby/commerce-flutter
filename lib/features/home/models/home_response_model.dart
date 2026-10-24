class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? targetType;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.targetType,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      targetType: json['targetType']?.toString(),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String iconName;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.iconName = 'toys',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class ProductPriceModel {
  final double originalPrice;
  final double finalPrice;
  final num? discountPercentage;

  const ProductPriceModel({
    required this.originalPrice,
    required this.finalPrice,
    this.discountPercentage,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    return ProductPriceModel(
      originalPrice: double.parse(json['original']?.toString() ?? '0.0'),
      finalPrice: double.parse(json['finalPrice']?.toString() ?? '0.0'),
      discountPercentage: json['discountPercentage'] as num?,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String slug;
  final ProductPriceModel priceInfo;
  final String image;
final bool isFavorite;
final num rating;
final int reviewCount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.priceInfo,
    required this.image,
    required this.isFavorite,
    required this.rating,
    required this.reviewCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      priceInfo: ProductPriceModel.fromJson(json['price'] ?? {}),
      image: json['image']?.toString() ?? '',
      isFavorite: json['isFavorite'] ?? false,
        rating: json['rating']??0,
        reviewCount: json['reviewCount']??0,
    );
  }
}

class HomeSectionModel {
  final String type;
  final String title;
  final String displayType;
  final List<ProductModel> products;

  const HomeSectionModel({
    required this.type,
    required this.title,
    required this.displayType,
    required this.products,
  });

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    return HomeSectionModel(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      displayType: json['displayType']?.toString() ?? '',
      products: (json['products'] as List? ?? [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BrandModel {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;

  const BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class HomeDataModel {
  final String platform;
  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<HomeSectionModel> sections;
  final List<BrandModel> brands;

  const HomeDataModel({
    required this.platform,
    required this.banners,
    required this.categories,
    required this.sections,
    required this.brands,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      platform: json['platform']?.toString() ?? 'mobile',
      banners: (json['banners'] as List? ?? [])
          .map((b) => BannerModel.fromJson(b as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List? ?? [])
          .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List? ?? [])
          .map((s) => HomeSectionModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      brands: (json['brands'] as List? ?? [])
          .map((br) => BrandModel.fromJson(br as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HomeResponseModel {
  final bool success;
  final String? message;
  final HomeDataModel data;

  const HomeResponseModel({
    required this.success,
    this.message,
    required this.data,
  });

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) {
    return HomeResponseModel(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: HomeDataModel.fromJson(json['data'] ?? {}),
    );
  }
}
