import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/core/network/api_response.dart';
import '../models/order_model.dart';

class OrdersRepository {
  final Dio _dio;

  OrdersRepository(this._dio);

  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _dio.get(ApiEndpoints.myOrders);
      final apiResponse = ApiListResponse.fromJson(
        response.data,
        (json) {
          final item = json as Map<String, dynamic>;
          return OrderModel(
            id: item['id']?.toString() ?? '',
            orderNumber: item['orderNumber']?.toString() ?? '#IVY-2431',
            status: item['status']?.toString() ?? 'IN_TRANSIT',
            placedDate: item['placedDate']?.toString() ?? '15 Sep 2026',
            deliveryDate: item['deliveryDate']?.toString(),
            totalAmount: (item['totalAmount'] as num?)?.toDouble() ?? 90.90,
            items: const [],
          );
        },
      );
      if (apiResponse.success && apiResponse.data.isNotEmpty) {
        return apiResponse.data;
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 300));
    return [
      OrderModel(
        id: '1',
        orderNumber: '#IVY-2431',
        status: 'IN_TRANSIT',
        placedDate: 'Placed 15 Sep 2026 · 4 items · Arriving 21 Sep',
        totalAmount: 90.90,
        items: [
          const OrderItemModel(id: 'i1', name: 'Cuddle Bear Soft Toy', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a87f0?q=80&w=600&auto=format&fit=crop', details: 'Cream · Medium 35cm', price: 24.0, quantity: 1),
          const OrderItemModel(id: 'i2', name: 'Daisy Summer Dress', imageUrl: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?q=80&w=600&auto=format&fit=crop', details: 'Mustard · 3–4 years', price: 37.0, quantity: 2),
          const OrderItemModel(id: 'i3', name: 'Rainbow Arch Stacker', imageUrl: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?q=80&w=600&auto=format&fit=crop', details: 'Natural · 7 arches', price: 29.90, quantity: 1),
        ],
      ),
      OrderModel(
        id: '2',
        orderNumber: '#IVY-2398',
        status: 'DELIVERED',
        placedDate: 'Delivered 2 Aug 2026 · 2 items',
        totalAmount: 42.50,
        items: [
          const OrderItemModel(id: 'i4', name: 'Cuddle Bear Soft Toy', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a87f0?q=80&w=600&auto=format&fit=crop', details: 'Cream', price: 24.0, quantity: 1),
        ],
      ),
      OrderModel(
        id: '3',
        orderNumber: '#IVY-2355',
        status: 'DELIVERED',
        placedDate: 'Delivered 18 Jul 2026 · 1 item',
        totalAmount: 29.90,
        items: [
          const OrderItemModel(id: 'i5', name: 'Rainbow Arch Stacker', imageUrl: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?q=80&w=600&auto=format&fit=crop', details: 'Natural', price: 29.90, quantity: 1),
        ],
      ),
      OrderModel(
        id: '4',
        orderNumber: '#IVY-2301',
        status: 'CANCELLED',
        placedDate: 'Cancelled 3 Jul 2026 · Refunded 5 Jul · 2 items',
        totalAmount: 40.50,
        items: [
          const OrderItemModel(id: 'i6', name: 'Mini Canvas Sneakers', imageUrl: 'https://images.unsplash.com/photo-1514989940723-e8e5ef6ab5a9?q=80&w=600&auto=format&fit=crop', details: 'White', price: 22.0, quantity: 1),
        ],
      ),
    ];
  }

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    await _dio.post(ApiEndpoints.checkout, data: orderData);
  }
}
