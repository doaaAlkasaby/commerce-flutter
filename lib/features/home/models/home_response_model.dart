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

  factory ProductPriceModel.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final original = double.tryParse(json['original']?.toString() ?? json['basePrice']?.toString() ?? '0.0') ?? 0.0;
      final finalP = double.tryParse(json['final']?.toString() ?? json['finalPrice']?.toString() ?? json['basePrice']?.toString() ?? '0.0') ?? original;
      final discount = json['discountPercentage'] ?? num.tryParse(json['discountValue']?.toString() ?? '');
      return ProductPriceModel(
        originalPrice: original,
        finalPrice: finalP,
        discountPercentage: discount,
      );
    } else if (json is num) {
      return ProductPriceModel(originalPrice: json.toDouble(), finalPrice: json.toDouble());
    } else if (json is String) {
      final val = double.tryParse(json) ?? 0.0;
      return ProductPriceModel(originalPrice: val, finalPrice: val);
    }
    return const ProductPriceModel(originalPrice: 0.0, finalPrice: 0.0);
  }
}

class ProductPricingModel {
  final double basePrice;
  final double finalPrice;
  final String? discountType;
  final String? discountValue;

  const ProductPricingModel({
    required this.basePrice,
    required this.finalPrice,
    this.discountType,
    this.discountValue,
  });

  factory ProductPricingModel.fromJson(Map<String, dynamic> json) {
    return ProductPricingModel(
      basePrice: double.tryParse(json['basePrice']?.toString() ?? '0.0') ?? 0.0,
      finalPrice: double.tryParse(json['finalPrice']?.toString() ?? json['final']?.toString() ?? json['basePrice']?.toString() ?? '0.0') ?? 0.0,
      discountType: json['discountType']?.toString(),
      discountValue: json['discountValue']?.toString(),
    );
  }
}

class ProductImageModel {
  final String id;
  final String url;
  final String altText;
  final bool isPrimary;

  const ProductImageModel({
    required this.id,
    required this.url,
    required this.altText,
    required this.isPrimary,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      altText: json['altText']?.toString() ?? '',
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}

class ProductAttributeValueModel {
  final String id;
  final String value;
  final String? imageUrl;

  const ProductAttributeValueModel({
    required this.id,
    required this.value,
    this.imageUrl,
  });

  factory ProductAttributeValueModel.fromJson(Map<String, dynamic> json) {
    return ProductAttributeValueModel(
      id: json['id']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class ProductAttributeModel {
  final String id;
  final String name;
  final List<ProductAttributeValueModel> values;

  const ProductAttributeModel({
    required this.id,
    required this.name,
    required this.values,
  });

  factory ProductAttributeModel.fromJson(Map<String, dynamic> json) {
    return ProductAttributeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      values: (json['values'] as List? ?? [])
          .map((v) => ProductAttributeValueModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VariantAttributeModel {
  final String attributeId;
  final String attributeName;
  final String attributeValueId;
  final String value;

  const VariantAttributeModel({
    required this.attributeId,
    required this.attributeName,
    required this.attributeValueId,
    required this.value,
  });

  factory VariantAttributeModel.fromJson(Map<String, dynamic> json) {
    return VariantAttributeModel(
      attributeId: json['attributeId']?.toString() ?? '',
      attributeName: json['attributeName']?.toString() ?? '',
      attributeValueId: json['attributeValueId']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class ProductVariantModel {
  final String id;
  final String sku;
  final double price;
  final bool isActive;
  final ProductPricingModel pricing;
  final List<ProductImageModel> images;
  final List<VariantAttributeModel> attributes;

  const ProductVariantModel({
    required this.id,
    required this.sku,
    required this.price,
    required this.isActive,
    required this.pricing,
    required this.images,
    required this.attributes,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      isActive: json['isActive'] ?? true,
      pricing: ProductPricingModel.fromJson(json['pricing'] ?? {}),
      images: (json['images'] as List? ?? [])
          .map((img) => ProductImageModel.fromJson(img as Map<String, dynamic>))
          .toList(),
      attributes: (json['attributes'] as List? ?? [])
          .map((attr) => VariantAttributeModel.fromJson(attr as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RatingModel {
  final double average;
  final int count;

  const RatingModel({
    required this.average,
    required this.count,
  });

  factory RatingModel.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return RatingModel(
        average: (json['average'] as num?)?.toDouble() ?? 0.0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
    } else if (json is num) {
      return RatingModel(average: json.toDouble(), count: 0);
    }
    return const RatingModel(average: 0.0, count: 0);
  }
}

class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final ProductPriceModel priceInfo;
  final ProductPricingModel? pricing;
  final String image;
  final List<ProductImageModel> images;
  final List<ProductAttributeModel> attributes;
  final List<ProductVariantModel> variants;
  final bool isFavorite;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? brand;
  final bool hasVariants;
  final String? defaultVariantId;

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    required this.priceInfo,
    this.pricing,
    required this.image,
    this.images = const [],
    this.attributes = const [],
    this.variants = const [],
    required this.isFavorite,
    required this.rating,
    required this.reviewCount,
    this.category,
    this.brand,
    required this.hasVariants,
    this.defaultVariantId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final ratingObj = RatingModel.fromJson(json['rating']);
    final pricingMap = json['pricing'] ?? json['price'] ?? json;
    final priceInfoObj = ProductPriceModel.fromJson(pricingMap);
    final pricingObj = ProductPricingModel.fromJson(pricingMap);

    List<ProductImageModel> imgsList = [];
    if (json['images'] is List) {
      imgsList = (json['images'] as List)
          .map((img) => ProductImageModel.fromJson(img as Map<String, dynamic>))
          .toList();
    }
    if (json['primaryImage'] is Map<String, dynamic>) {
      final pi = json['primaryImage'] as Map<String, dynamic>;
      imgsList.add(ProductImageModel(
        id: pi['id']?.toString() ?? 'primary',
        url: pi['url']?.toString() ?? '',
        altText: pi['altText']?.toString() ?? '',
        isPrimary: true,
      ));
    }

    final primaryImg = imgsList.where((img) => img.isPrimary).firstOrNull?.url ??
        (imgsList.isNotEmpty ? imgsList.first.url : json['image']?.toString() ?? 'https://placehold.co/800x800');

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priceInfo: priceInfoObj,
      pricing: pricingObj,
      image: primaryImg,
      images: imgsList,
      attributes: (json['attributes'] as List? ?? [])
          .map((attr) => ProductAttributeModel.fromJson(attr as Map<String, dynamic>))
          .toList(),
      variants: (json['variants'] as List? ?? [])
          .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      isFavorite: json['isInWishlist'] ?? json['isFavorite'] ?? false,
      rating: ratingObj.average,
      reviewCount: ratingObj.count,
      category: json['category'] as Map<String, dynamic>?,
      brand: json['brand'] as Map<String, dynamic>?,
      hasVariants: json['hasVariants'] ?? false,
      defaultVariantId: json['defaultVariantId']?.toString(),
    );
  }

  ProductModel copyWith({bool? isFavorite}) {
    return ProductModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      priceInfo: priceInfo,
      pricing: pricing,
      image: image,
      images: images,
      attributes: attributes,
      variants: variants,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating,
      reviewCount: reviewCount,
      category: category,
      brand: brand,
      hasVariants: hasVariants,
      defaultVariantId: defaultVariantId,
    );
  }
}

class HomeSectionModel {
  final String type;
  final String title;
  final String displayType;
  final List<ProductModel> products;
  final SeeAllModel? seeAll;

  const HomeSectionModel({
    required this.type,
    required this.title,
    required this.displayType,
    required this.products,
    this.seeAll,
  });

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    return HomeSectionModel(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      displayType: json['displayType']?.toString() ?? '',
      products: (json['products'] as List? ?? [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      seeAll: json['seeAll'] != null ? SeeAllModel.fromJson(json['seeAll'] as Map<String, dynamic>) : null,
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

class SeeAllModel {
  final bool enabled;
  final String? targetType;
  final String? target;

  const SeeAllModel({
    required this.enabled,
    this.targetType,
    this.target,
  });

  factory SeeAllModel.fromJson(Map<String, dynamic> json) {
    return SeeAllModel(
      enabled: json['enabled'] ?? false,
      targetType: json['targetType']?.toString(),
      target: json['target']?.toString(),
    );
  }
}
