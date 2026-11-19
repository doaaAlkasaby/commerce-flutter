import 'package:ecommerce/core/config/app_environment.dart';

class CartProductModel {
  final String id;
  final String name;
  final String slug;
  final String basePrice;
  final String? imageUrl;

  const CartProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.basePrice,
    this.imageUrl,
  });

  factory CartProductModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['imageUrl']?.toString();
    return CartProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      basePrice: json['basePrice']?.toString() ?? '0.00',
      imageUrl: rawUrl != null && rawUrl.trim().isNotEmpty
          ? AppEnvironment.resolveImageUrl(rawUrl.trim())
          : null,
    );
  }
}

class CartImageModel {
  final String url;
  final int sortOrder;
  final bool isPrimary;

  const CartImageModel({
    required this.url,
    this.sortOrder = 0,
    this.isPrimary = false,
  });

  factory CartImageModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url']?.toString() ?? '';
    return CartImageModel(
      url: rawUrl.trim().isNotEmpty
          ? AppEnvironment.resolveImageUrl(rawUrl.trim())
          : '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class CartVariantModel {
  final String id;
  final String sku;
  final String price;
  final CartProductModel product;
  final List<CartImageModel> images;

  const CartVariantModel({
    required this.id,
    required this.sku,
    required this.price,
    required this.product,
    required this.images,
  });

  String? get resolvedImageUrl {
    final validImages = images
        .where((img) => img.url.trim().isNotEmpty)
        .toList();

    if (validImages.isNotEmpty) {
      final primaryList = validImages.where((img) => img.isPrimary).toList();
      if (primaryList.isNotEmpty) {
        return primaryList.first.url;
      }

      final sortedImages = List<CartImageModel>.from(validImages)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return sortedImages.first.url;
    }

    if (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty) {
      return product.imageUrl!.trim();
    }

    return null;
  }

  factory CartVariantModel.fromJson(Map<String, dynamic> json) {
    return CartVariantModel(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      product: CartProductModel.fromJson(json['product'] ?? {}),
      images: (json['images'] as List? ?? [])
          .map((img) => CartImageModel.fromJson(img as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CartItemModel {
  final String id;
  final String variantId;
  final int quantity;
  final String unitPrice;
  final String finalUnitPrice;
  final String totalPrice;
  final CartVariantModel variant;

  const CartItemModel({
    required this.id,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.finalUnitPrice,
    required this.totalPrice,
    required this.variant,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: json['unitPrice']?.toString() ?? '0.00',
      finalUnitPrice: json['finalUnitPrice']?.toString() ?? '0.00',
      totalPrice: json['totalPrice']?.toString() ?? '0.00',
      variant: CartVariantModel.fromJson(json['variant'] ?? {}),
    );
  }
}

class CartModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final int itemCount;
  final String subtotal;

  const CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.itemCount,
    required this.subtotal,
  });

  const CartModel.empty()
    : id = '',
      userId = '',
      items = const [],
      itemCount = 0,
      subtotal = '0.00';

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: json['subtotal']?.toString() ?? '0.00',
    );
  }
}
