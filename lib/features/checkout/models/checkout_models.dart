import 'payment_models.dart';

String _validateDecimalString(dynamic raw, String fieldName) {
  if (raw == null) {
    throw FormatException(
      'Missing required monetary decimal field: $fieldName',
    );
  }
  final str = raw.toString().trim();
  if (str.isEmpty || !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(str)) {
    throw FormatException(
      'Invalid monetary decimal value for $fieldName: "$raw"',
    );
  }
  return str;
}

class FulfillmentModel {
  final String warehouseId;
  final String warehouseCode;

  const FulfillmentModel({
    required this.warehouseId,
    required this.warehouseCode,
  });

  factory FulfillmentModel.fromJson(Map<String, dynamic> json) {
    return FulfillmentModel(
      warehouseId: json['warehouseId']?.toString() ?? '',
      warehouseCode: json['warehouseCode']?.toString() ?? '',
    );
  }
}

class ShippingOptionModel {
  final String methodCode;
  final String methodName;
  final String currency;
  final String amount;
  final double? distanceKm;
  final FulfillmentModel fulfillment;
  final String totalAmount;

  const ShippingOptionModel({
    required this.methodCode,
    required this.methodName,
    required this.currency,
    required this.amount,
    this.distanceKm,
    required this.fulfillment,
    required this.totalAmount,
  });

  factory ShippingOptionModel.fromJson(Map<String, dynamic> json) {
    final methodCode =
        json['methodCode']?.toString() ?? json['code']?.toString();
    final methodName =
        json['methodName']?.toString() ?? json['name']?.toString();
    if (methodCode == null || methodCode.isEmpty) {
      throw const FormatException('Shipping option is missing methodCode');
    }

    return ShippingOptionModel(
      methodCode: methodCode,
      methodName: methodName ?? methodCode,
      currency: json['currency']?.toString() ?? '',
      amount: _validateDecimalString(json['amount'] ?? '0.00', 'amount'),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      fulfillment: FulfillmentModel.fromJson(
        (json['fulfillment'] as Map<String, dynamic>?) ?? {},
      ),
      totalAmount: _validateDecimalString(
        json['totalAmount'] ?? json['amount'] ?? '0.00',
        'totalAmount',
      ),
    );
  }
}

class CheckoutPreviewItemModel {
  final String productId;
  final String variantId;
  final String productName;
  final String sku;
  final int quantity;
  final String currency;
  final String unitPrice;
  final String itemDiscountAmount;
  final String finalUnitPrice;
  final String totalPrice;
  final String couponDiscount;

  const CheckoutPreviewItemModel({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.currency,
    required this.unitPrice,
    required this.itemDiscountAmount,
    required this.finalUnitPrice,
    required this.totalPrice,
    required this.couponDiscount,
  });

  factory CheckoutPreviewItemModel.fromJson(Map<String, dynamic> json) {
    return CheckoutPreviewItemModel(
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      currency: json['currency']?.toString() ?? '',
      unitPrice: _validateDecimalString(
        json['unitPrice'] ?? '0.00',
        'unitPrice',
      ),
      itemDiscountAmount: _validateDecimalString(
        json['itemDiscountAmount'] ?? '0.00',
        'itemDiscountAmount',
      ),
      finalUnitPrice: _validateDecimalString(
        json['finalUnitPrice'] ?? '0.00',
        'finalUnitPrice',
      ),
      totalPrice: _validateDecimalString(
        json['totalPrice'] ?? '0.00',
        'totalPrice',
      ),
      couponDiscount: _validateDecimalString(
        json['couponDiscount'] ?? '0.00',
        'couponDiscount',
      ),
    );
  }
}

class CheckoutCouponModel {
  final String code;
  final String discountType;
  final String discountValue;
  final String currency;
  final String discountAmount;

  const CheckoutCouponModel({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.currency,
    required this.discountAmount,
  });

  factory CheckoutCouponModel.fromJson(Map<String, dynamic> json) {
    return CheckoutCouponModel(
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? '',
      discountValue: _validateDecimalString(
        json['discountValue'] ?? '0.00',
        'discountValue',
      ),
      currency: json['currency']?.toString() ?? '',
      discountAmount: _validateDecimalString(
        json['discountAmount'] ?? '0.00',
        'discountAmount',
      ),
    );
  }
}

class CheckoutPreviewModel {
  final FulfillmentModel fulfillment;
  final bool estimated;
  final String currency;
  final List<CheckoutPreviewItemModel> items;
  final String subtotal;
  final String productDiscount;
  final String couponDiscount;
  final String shippingAmount;
  final String taxAmount;
  final String totalAmount;
  final bool pricesIncludeTax;
  final ShippingOptionModel? shipping;
  final CheckoutCouponModel? coupon;
  final List<String> warnings;

  const CheckoutPreviewModel({
    required this.fulfillment,
    required this.estimated,
    required this.currency,
    required this.items,
    required this.subtotal,
    required this.productDiscount,
    required this.couponDiscount,
    required this.shippingAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.pricesIncludeTax,
    this.shipping,
    this.coupon,
    this.warnings = const [],
  });

  factory CheckoutPreviewModel.fromJson(Map<String, dynamic> json) {
    final subtotal = _validateDecimalString(json['subtotal'], 'subtotal');
    final totalAmount = _validateDecimalString(
      json['totalAmount'],
      'totalAmount',
    );
    final shippingAmount = _validateDecimalString(
      json['shippingAmount'] ?? '0.00',
      'shippingAmount',
    );
    final taxAmount = _validateDecimalString(
      json['taxAmount'] ?? '0.00',
      'taxAmount',
    );
    final couponDiscount = _validateDecimalString(
      json['couponDiscount'] ?? '0.00',
      'couponDiscount',
    );

    return CheckoutPreviewModel(
      fulfillment: FulfillmentModel.fromJson(
        (json['fulfillment'] as Map<String, dynamic>?) ?? {},
      ),
      estimated: json['estimated'] ?? true,
      currency: json['currency']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .map(
            (item) =>
                CheckoutPreviewItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      subtotal: subtotal,
      productDiscount: _validateDecimalString(
        json['productDiscount'] ?? '0.00',
        'productDiscount',
      ),
      couponDiscount: couponDiscount,
      shippingAmount: shippingAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      pricesIncludeTax: json['pricesIncludeTax'] ?? false,
      shipping: json['shipping'] != null
          ? ShippingOptionModel.fromJson(
              json['shipping'] as Map<String, dynamic>,
            )
          : null,
      coupon: json['coupon'] != null
          ? CheckoutCouponModel.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
      warnings: (json['warnings'] as List? ?? [])
          .map((w) => w.toString())
          .toList(),
    );
  }
}

class CheckoutOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String currency;
  final String subtotal;
  final String discountAmount;
  final String shippingAmount;
  final String taxAmount;
  final String totalAmount;

  const CheckoutOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.currency,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingAmount,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory CheckoutOrderModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException(
        'Malformed checkout order payload: missing id',
      );
    }

    return CheckoutOrderModel(
      id: id,
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      subtotal: _validateDecimalString(json['subtotal'] ?? '0.00', 'subtotal'),
      discountAmount: _validateDecimalString(
        json['discountAmount'] ?? '0.00',
        'discountAmount',
      ),
      shippingAmount: _validateDecimalString(
        json['shippingAmount'] ?? '0.00',
        'shippingAmount',
      ),
      taxAmount: _validateDecimalString(
        json['taxAmount'] ?? '0.00',
        'taxAmount',
      ),
      totalAmount: _validateDecimalString(
        json['totalAmount'] ?? '0.00',
        'totalAmount',
      ),
    );
  }
}

class CheckoutResultModel {
  final CheckoutOrderModel order;
  final PaymentModel? payment;
  final bool idempotent;

  const CheckoutResultModel({
    required this.order,
    this.payment,
    required this.idempotent,
  });

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) {
    PaymentModel? p;
    if (json['payment'] is Map<String, dynamic>) {
      p = PaymentModel.fromJson(json['payment'] as Map<String, dynamic>);
    }
    return CheckoutResultModel(
      order: CheckoutOrderModel.fromJson(
        (json['order'] as Map<String, dynamic>?) ?? {},
      ),
      payment: p,
      idempotent: json['idempotent'] ?? false,
    );
  }
}
