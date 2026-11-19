import 'package:ecommerce/core/config/app_environment.dart';

String resolveImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.isEmpty) {
    return '';
  }
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  // Resolve relative /uploads URL against origin base URL (e.g. http://127.0.0.1:3000)
  final baseUrl = AppEnvironment.baseUrl; // e.g. http://127.0.0.1:3000/api/v1
  final uri = Uri.parse(baseUrl);
  final origin =
      '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
  return '$origin$cleanPath';
}

String _validateOrderDecimalString(dynamic raw, String fieldName) {
  if (raw == null) {
    throw FormatException('Missing required order decimal field: $fieldName');
  }
  final str = raw.toString().trim();
  if (str.isEmpty || !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(str)) {
    throw FormatException('Invalid order decimal value for $fieldName: "$raw"');
  }
  return str;
}

String formatOrderMoney(
  String rawAmount,
  String currency, [
  bool isArabic = false,
]) {
  final parsed = double.tryParse(rawAmount);
  final upper = currency.toUpperCase();

  String currencyLabel = currency;
  if (isArabic) {
    if (upper == 'KWD') {
      currencyLabel = 'د.ك';
    } else if (upper == 'SAR') {
      currencyLabel = 'ر.س';
    } else if (upper == 'AED') {
      currencyLabel = 'د.إ';
    } else if (upper == 'EGP') {
      currencyLabel = 'ج.م';
    } else if (upper == 'USD') {
      currencyLabel = '\$';
    } else if (upper == 'EUR') {
      currencyLabel = '€';
    } else if (upper == 'QAR') {
      currencyLabel = 'ر.ق';
    } else if (upper == 'BHD') {
      currencyLabel = 'د.ب';
    } else if (upper == 'OMR') {
      currencyLabel = 'ر.ع';
    }
  }

  if (parsed == null) return '$rawAmount $currencyLabel';
  if (upper == 'KWD') {
    return '${parsed.toStringAsFixed(3)} $currencyLabel';
  }
  return '${parsed.toStringAsFixed(2)} $currencyLabel';
}

class OrderAddressModel {
  final String firstName;
  final String lastName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final String countryCode;
  final String? phone;

  const OrderAddressModel({
    required this.firstName,
    required this.lastName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    required this.countryCode,
    this.phone,
  });

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      addressLine1:
          json['addressLine1']?.toString() ??
          json['streetAddress']?.toString() ??
          '',
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
      countryCode:
          json['countryCode']?.toString() ?? json['country']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }
}

class OrderPaymentModel {
  final String id;
  final String provider;
  final String method;
  final String status;
  final String amount;
  final String currency;
  final String createdAt;

  const OrderPaymentModel({
    required this.id,
    required this.provider,
    required this.method,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory OrderPaymentModel.fromJson(Map<String, dynamic> json) {
    return OrderPaymentModel(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: _validateOrderDecimalString(json['amount'] ?? '0.00', 'amount'),
      currency: json['currency']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class OrderItemModel {
  final String id;
  final String productId;
  final String variantId;
  final String productName;
  final String sku;
  final int quantity;
  final String unitPrice;
  final String itemDiscountAmount;
  final String finalUnitPrice;
  final String totalPrice;
  final String imageUrl;
  final List<String> variantAttributes;

  String get name => productName;
  String get price => finalUnitPrice;

  String get variantAttributesSummary {
    if (variantAttributes.isNotEmpty) {
      return variantAttributes.join(' · ');
    }
    return 'One size';
  }

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.itemDiscountAmount,
    required this.finalUnitPrice,
    required this.totalPrice,
    required this.imageUrl,
    this.variantAttributes = const [],
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final variantSnapshot =
        json['variantSnapshot'] as Map<String, dynamic>? ?? {};
    final images = variantSnapshot['images'] as List? ?? [];
    String rawImg = '';
    if (images.isNotEmpty) {
      final primaryImg = images.firstWhere(
        (img) => img['isPrimary'] == true,
        orElse: () => images.first,
      );
      rawImg = primaryImg['url']?.toString() ?? '';
    }

    final valuesList = variantSnapshot['values'] as List? ?? [];
    final attrValues = valuesList
        .map((v) => v['value']?.toString() ?? '')
        .where((val) => val.isNotEmpty)
        .toList();

    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      productName:
          json['productName']?.toString() ??
          json['name']?.toString() ??
          'Product',
      sku: json['sku']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: _validateOrderDecimalString(
        json['unitPrice'] ?? '0.00',
        'unitPrice',
      ),
      itemDiscountAmount: _validateOrderDecimalString(
        json['itemDiscountAmount'] ?? '0.00',
        'itemDiscountAmount',
      ),
      finalUnitPrice: _validateOrderDecimalString(
        json['finalUnitPrice'] ?? '0.00',
        'finalUnitPrice',
      ),
      totalPrice: _validateOrderDecimalString(
        json['totalPrice'] ?? '0.00',
        'totalPrice',
      ),
      imageUrl: resolveImageUrl(rawImg),
      variantAttributes: attrValues,
    );
  }
}

class OrderPaginationModel {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const OrderPaginationModel({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory OrderPaginationModel.fromJson(Map<String, dynamic> json) {
    return OrderPaginationModel(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class OrderModel {
  String get placedDate => createdAt;

  String formatHumanDate(bool isArabic) {
    if (createdAt.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      const monthsEn = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      const monthsAr = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];

      final day = dateTime.day;
      final monthStr = isArabic
          ? monthsAr[dateTime.month - 1]
          : monthsEn[dateTime.month - 1];

      int hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final periodEn = hour >= 12 ? 'PM' : 'AM';
      final periodAr = hour >= 12 ? 'م' : 'ص';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      if (isArabic) {
        return 'تم الطلب $day $monthStr، $hour:$minute $periodAr';
      } else {
        return 'Placed $day $monthStr, $hour:$minute $periodEn';
      }
    } catch (_) {
      return createdAt;
    }
  }

  final String id;
  final String orderNumber;
  final String userId;
  final String status;
  final String paymentStatus;
  final String currency;
  final String subtotal;
  final String discountAmount;
  final String shippingAmount;
  final String taxAmount;
  final String totalAmount;
  final bool pricesIncludeTax;
  final String? shippingMethodCode;
  final String? shippingMethodName;
  final OrderAddressModel? shippingAddress;
  final OrderAddressModel? billingAddress;
  final List<OrderItemModel> items;
  final List<OrderPaymentModel> payments;
  final int itemCount;
  final String createdAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    required this.currency,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.pricesIncludeTax,
    this.shippingMethodCode,
    this.shippingMethodName,
    this.shippingAddress,
    this.billingAddress,
    required this.items,
    required this.payments,
    required this.itemCount,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const FormatException('Malformed order payload: missing id');
    }

    final rawItems = json['items'] as List? ?? [];
    final rawPayments = json['payments'] as List? ?? [];

    return OrderModel(
      id: id,
      orderNumber: json['orderNumber']?.toString() ?? id,
      userId: json['userId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'CONFIRMED',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      currency: json['currency']?.toString() ?? '',
      subtotal: _validateOrderDecimalString(json['subtotal'], 'subtotal'),
      discountAmount: _validateOrderDecimalString(
        json['discountAmount'] ?? '0.00',
        'discountAmount',
      ),
      shippingAmount: _validateOrderDecimalString(
        json['shippingAmount'] ?? '0.00',
        'shippingAmount',
      ),
      taxAmount: _validateOrderDecimalString(
        json['taxAmount'] ?? '0.00',
        'taxAmount',
      ),
      totalAmount: _validateOrderDecimalString(
        json['totalAmount'],
        'totalAmount',
      ),
      pricesIncludeTax: json['pricesIncludeTax'] ?? false,
      shippingMethodCode: json['shippingMethodCode']?.toString(),
      shippingMethodName: json['shippingMethodName']?.toString(),
      shippingAddress:
          json['shippingAddress'] != null &&
              json['shippingAddress'] is Map<String, dynamic>
          ? OrderAddressModel.fromJson(
              json['shippingAddress'] as Map<String, dynamic>,
            )
          : null,
      billingAddress:
          json['billingAddress'] != null &&
              json['billingAddress'] is Map<String, dynamic>
          ? OrderAddressModel.fromJson(
              json['billingAddress'] as Map<String, dynamic>,
            )
          : null,
      items: rawItems
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      payments: rawPayments
          .map((p) => OrderPaymentModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? rawItems.length,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PaginatedOrdersModel {
  final List<OrderModel> items;
  final OrderPaginationModel pagination;

  const PaginatedOrdersModel({required this.items, required this.pagination});

  factory PaginatedOrdersModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final paginationObj = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedOrdersModel(
      items: rawItems
          .map((i) => OrderModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: OrderPaginationModel.fromJson(paginationObj),
    );
  }
}
