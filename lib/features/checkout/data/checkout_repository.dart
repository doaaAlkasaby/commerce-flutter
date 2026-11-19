import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/checkout_models.dart';

class CheckoutRepository {
  final Dio _dio;

  CheckoutRepository(this._dio);

  Future<List<ShippingOptionModel>> getShippingOptions({
    required String shippingAddressId,
    String? billingAddressId,
    bool billingSameAsShipping = true,
    String? couponCode,
  }) async {
    final body = <String, dynamic>{
      'shippingAddressId': shippingAddressId,
      'billingSameAsShipping': billingSameAsShipping,
      if (!billingSameAsShipping && billingAddressId != null)
        'billingAddressId': billingAddressId,
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'couponCode': couponCode.trim(),
    };

    final response = await _dio.post(
      '${ApiEndpoints.checkout}/shipping-options',
      data: body,
    );

    final rawData = response.data['data'];
    final optionsList = (rawData is Map)
        ? (rawData['options'] as List? ?? [])
        : [];

    return optionsList
        .map((opt) => ShippingOptionModel.fromJson(opt as Map<String, dynamic>))
        .toList();
  }

  Future<CheckoutPreviewModel> getPreview({
    required String shippingAddressId,
    String? billingAddressId,
    bool billingSameAsShipping = true,
    String? shippingMethodCode,
    String? couponCode,
  }) async {
    final body = <String, dynamic>{
      'shippingAddressId': shippingAddressId,
      'billingSameAsShipping': billingSameAsShipping,
      if (!billingSameAsShipping && billingAddressId != null)
        'billingAddressId': billingAddressId,
      if (shippingMethodCode != null && shippingMethodCode.trim().isNotEmpty)
        'shippingMethodCode': shippingMethodCode.trim(),
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'couponCode': couponCode.trim(),
    };

    final response = await _dio.post(
      '${ApiEndpoints.checkout}/preview',
      data: body,
    );

    final data = response.data['data'] ?? {};
    return CheckoutPreviewModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckoutResultModel> placeOrder({
    required String shippingAddressId,
    String? billingAddressId,
    bool billingSameAsShipping = true,
    required String shippingMethodCode,
    required String paymentMethod,
    String? paymentProvider,
    String? couponCode,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'shippingAddressId': shippingAddressId,
      'billingSameAsShipping': billingSameAsShipping,
      if (!billingSameAsShipping && billingAddressId != null)
        'billingAddressId': billingAddressId,
      'shippingMethodCode': shippingMethodCode,
      'paymentMethod': paymentMethod,
      if (paymentProvider != null && paymentProvider.isNotEmpty)
        'paymentProvider': paymentProvider,
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'couponCode': couponCode.trim(),
    };

    final options = Options(
      headers: {
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'Idempotency-Key': idempotencyKey,
      },
    );

    final response = await _dio.post(
      ApiEndpoints.checkout,
      data: body,
      options: options,
    );

    final data = response.data['data'] ?? {};
    return CheckoutResultModel.fromJson(data as Map<String, dynamic>);
  }
}
