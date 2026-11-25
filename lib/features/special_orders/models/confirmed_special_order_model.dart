String _validateDecimal(dynamic raw, String fieldName) {
  if (raw == null) return '0.00';
  final str = raw.toString().trim();
  if (str.isEmpty || !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(str)) {
    return '0.00';
  }
  return str;
}

class ConfirmedSpecialOrderModel {
  final String id;
  final String orderNumber;
  final String requestId;
  final String status;
  final String paymentStatus;
  final String fulfillmentStatus;
  final String currency;
  final String subtotal;
  final String shippingFee;
  final String taxAmount;
  final String totalAmount;
  final String createdAt;
  final String? updatedAt;

  const ConfirmedSpecialOrderModel({
    required this.id,
    required this.orderNumber,
    required this.requestId,
    required this.status,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    required this.currency,
    required this.subtotal,
    required this.shippingFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConfirmedSpecialOrderModel.fromJson(Map<String, dynamic> json) {
    return ConfirmedSpecialOrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber:
          json['orderNumber']?.toString() ??
          json['number']?.toString() ??
          'SO',
      requestId: json['requestId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
      fulfillmentStatus: json['fulfillmentStatus']?.toString() ?? 'NOT_FULFILLED',
      currency: json['currency']?.toString() ?? 'KWD',
      subtotal: _validateDecimal(json['subtotal'] ?? json['subtotalAmount'], 'subtotal'),
      shippingFee: _validateDecimal(json['shippingFee'] ?? json['shippingAmount'], 'shippingFee'),
      taxAmount: _validateDecimal(json['taxAmount'] ?? json['tax'], 'taxAmount'),
      totalAmount: _validateDecimal(json['totalAmount'] ?? json['grandTotal'] ?? json['total'], 'totalAmount'),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
