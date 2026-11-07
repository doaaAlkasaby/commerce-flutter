class CartProductModel {
  final String id;
  final String name;
  final String slug;
  final String basePrice;

  const CartProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.basePrice,
  });

  factory CartProductModel.fromJson(Map<String, dynamic> json) {
    return CartProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      basePrice: json['basePrice']?.toString() ?? '0.00',
    );
  }
}

class CartImageModel {
  final String url;
  const CartImageModel({required this.url});

  factory CartImageModel.fromJson(Map<String, dynamic> json) {
    return CartImageModel(url: json['url']?.toString() ?? '');
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
