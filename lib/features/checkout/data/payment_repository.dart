import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/payment_models.dart';

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  Future<PaymentModel> getPayment(String paymentId) async {
    final response = await _dio.get(ApiEndpoints.paymentById(paymentId));
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data);
  }

  Future<List<PaymentModel>> getOrderPayments(String orderId) async {
    final response = await _dio.get(ApiEndpoints.paymentByOrderId(orderId));
    final rawData = response.data['data'];
    final List list = rawData is List
        ? rawData
        : (rawData is Map ? (rawData['payments'] as List? ?? []) : []);
    return list
        .map((item) => PaymentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentModel> verifyPayment(String paymentId) async {
    final response = await _dio.post(
      ApiEndpoints.paymentVerify(paymentId),
      data: {},
    );
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data);
  }

  Future<PaymentModel> initiatePayment(String paymentId) async {
    final response = await _dio.post(
      '${ApiEndpoints.payments}/$paymentId/initiate',
      data: {},
    );
    final data =
        response.data['data'] as Map<String, dynamic>? ??
        response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data);
  }
}
