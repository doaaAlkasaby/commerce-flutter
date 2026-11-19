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

class PaymentModel {
  final String id;
  final String orderId;
  final String provider;
  final String method;
  final String status;
  final String initiationState;
  final String amount;
  final String currency;
  final String? providerPaymentId;
  final String? providerTransactionId;
  final String? failureCode;
  final String? failureMessage;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final String? updatedAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.method,
    required this.status,
    required this.initiationState,
    required this.amount,
    required this.currency,
    this.providerPaymentId,
    this.providerTransactionId,
    this.failureCode,
    this.failureMessage,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  String? get checkoutUrl {
    if (metadata != null && metadata!['checkoutUrl'] != null) {
      return metadata!['checkoutUrl']?.toString();
    }
    return null;
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Malformed payment payload: missing id');
    }

    final statusStr = json['status']?.toString();
    if (statusStr == null || statusStr.isEmpty) {
      throw const FormatException('Malformed payment payload: missing status');
    }

    final amountRaw = json['amount'];
    if (amountRaw == null) {
      throw const FormatException('Malformed payment payload: missing amount');
    }
    final amountStr = _validateDecimalString(amountRaw, 'amount');

    return PaymentModel(
      id: id,
      orderId: json['orderId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'NONE',
      method: json['method']?.toString() ?? 'CASH_ON_DELIVERY',
      status: statusStr,
      initiationState: json['initiationState']?.toString() ?? 'NOT_STARTED',
      amount: amountStr,
      currency: json['currency']?.toString() ?? '',
      providerPaymentId: json['providerPaymentId']?.toString(),
      providerTransactionId: json['providerTransactionId']?.toString(),
      failureCode: json['failureCode']?.toString(),
      failureMessage: json['failureMessage']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      createdAt: json['createdAt']?.toString() ?? 'Recent',
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
