import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/cart_model.dart';

class CartRepository {
  final Dio _dio;

  CartRepository(this._dio);

  Future<CartModel> getCart() async {
    try {
      final response = await _dio.get(ApiEndpoints.cart);
      final data = response.data['data'] ?? {};
      return CartModel.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return const CartModel(id: '1', userId: '1', items: [], itemCount: 0, subtotal: '0.00');
    }
  }

  Future<CartModel> addToCart(String variantId, int quantity) async {
    try {
      final response = await _dio.post(ApiEndpoints.cartItems, data: {
        'variantId': variantId,
        'quantity': quantity,
      });
      final data = response.data['data'] ?? {};
      return CartModel.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return const CartModel(id: '1', userId: '1', items: [], itemCount: 0, subtotal: '0.00');
    }
  }

  Future<CartModel> updateItemQuantity(String variantId, int quantity) async {
    try {
      final response = await _dio.patch(ApiEndpoints.cartItemById(variantId), data: {
        'quantity': quantity,
      });
      final data = response.data['data'] ?? {};
      return CartModel.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return const CartModel(id: '1', userId: '1', items: [], itemCount: 0, subtotal: '0.00');
    }
  }

  Future<CartModel> removeItem(String variantId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.cartItemById(variantId));
      final data = response.data['data'] ?? {};
      return CartModel.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return const CartModel(id: '1', userId: '1', items: [], itemCount: 0, subtotal: '0.00');
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiEndpoints.cart);
    } catch (_) {}
  }
}
