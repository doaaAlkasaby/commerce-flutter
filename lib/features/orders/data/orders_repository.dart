import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/order_model.dart';

class OrdersRepository {
  final Dio _dio;

  OrdersRepository(this._dio);

  Future<PaginatedOrdersModel> getMyOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? paymentStatus,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null &&
        status.isNotEmpty &&
        status != 'All' &&
        status != 'ALL') {
      queryParams['status'] = status.toUpperCase();
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParams['paymentStatus'] = paymentStatus.toUpperCase();
    }

    final response = await _dio.get(
      ApiEndpoints.ordersMy,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return PaginatedOrdersModel.fromJson(data);
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final response = await _dio.get(ApiEndpoints.orderMyById(orderId));
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    if (data.isEmpty || data['id'] == null) {
      return null;
    }
    return OrderModel.fromJson(data);
  }
}
