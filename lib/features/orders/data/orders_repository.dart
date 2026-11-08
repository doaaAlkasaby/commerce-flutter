import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/order_model.dart';

class OrdersRepository {
  final Dio _dio;

  OrdersRepository(this._dio);

  Future<List<OrderModel>> getMyOrders({
    String? status,
    String? paymentStatus,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        queryParams['paymentStatus'] = paymentStatus;
      }

      final response = await _dio.get(
        ApiEndpoints.ordersMy,
        queryParameters: queryParams,
      );
      final rawData = response.data['data'];
      final List list = rawData is List
          ? rawData
          : (rawData['orders'] ?? rawData['items'] ?? []);
      return list.map((item) {
        return OrderModel(
          id: item['id']?.toString() ?? '',
          orderNumber: item['orderNumber']?.toString() ?? '#IVY-2431',
          status: item['status']?.toString() ?? 'IN_TRANSIT',
          placedDate: item['createdAt']?.toString() ?? '15 Sep 2026',
          deliveryDate: item['deliveryDate']?.toString(),
          totalAmount:
              double.tryParse(item['totalAmount']?.toString() ?? '0.0') ?? 0.0,
          items: (item['items'] as List? ?? []).map((i) {
            final prod = i['variant']?['product'] ?? {};
            final img =
                (i['variant']?['images'] as List? ?? []).firstOrNull?['url'] ??
                '';
            return OrderItemModel(
              id: i['id']?.toString() ?? '',
              name: prod['name']?.toString() ?? 'Product',
              imageUrl: img,
              details: '',
              price:
                  double.tryParse(i['finalUnitPrice']?.toString() ?? '0.0') ??
                  0.0,
              quantity: (i['quantity'] as num?)?.toInt() ?? 1,
            );
          }).toList(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    await _dio.post(ApiEndpoints.checkout, data: orderData);
  }
}
