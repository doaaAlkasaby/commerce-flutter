import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/confirmed_special_order_model.dart';
import '../models/special_order_request_model.dart';
import '../models/special_orders_pagination_model.dart';

class SpecialOrdersRepository {
  final Dio _dio;

  SpecialOrdersRepository(this._dio);

  /// Fetch paginated customer special order requests
  Future<PaginatedSpecialOrdersModel<SpecialOrderRequestModel>> getMyRequests({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
      queryParams['status'] = status.toUpperCase();
    }

    final response = await _dio.get(
      ApiEndpoints.specialOrdersMy,
      queryParameters: queryParams,
    );

    final rawData = response.data['data'] as Map<String, dynamic>? ?? {};
    final rawList = rawData['items'] as List? ?? (response.data['data'] as List? ?? []);
    final items = rawList
        .map((e) => SpecialOrderRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final paginationMap = rawData['pagination'] as Map<String, dynamic>? ??
        <String, dynamic>{
          'page': page,
          'limit': limit,
          'totalItems': items.length,
          'totalPages': 1,
        };

    return PaginatedSpecialOrdersModel<SpecialOrderRequestModel>(
      items: items,
      pagination: SpecialOrdersPaginationModel.fromJson(paginationMap),
    );
  }

  /// Fetch request details by ID
  Future<SpecialOrderRequestModel?> getRequestById(String id) async {
    final response = await _dio.get(ApiEndpoints.specialOrderMyById(id));
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    if (data.isEmpty || data['id'] == null) {
      return null;
    }
    return SpecialOrderRequestModel.fromJson(data);
  }

  /// Fetch paginated confirmed customer special orders
  Future<PaginatedSpecialOrdersModel<ConfirmedSpecialOrderModel>> getMyConfirmedOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
      queryParams['status'] = status.toUpperCase();
    }

    final response = await _dio.get(
      ApiEndpoints.specialOrdersMyOrders,
      queryParameters: queryParams,
    );

    final rawData = response.data['data'] as Map<String, dynamic>? ?? {};
    final rawList = rawData['items'] as List? ?? (response.data['data'] as List? ?? []);
    final items = rawList
        .map((e) => ConfirmedSpecialOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final paginationMap = rawData['pagination'] as Map<String, dynamic>? ??
        <String, dynamic>{
          'page': page,
          'limit': limit,
          'totalItems': items.length,
          'totalPages': 1,
        };

    return PaginatedSpecialOrdersModel<ConfirmedSpecialOrderModel>(
      items: items,
      pagination: SpecialOrdersPaginationModel.fromJson(paginationMap),
    );
  }

  /// Fetch confirmed special order details by ID
  Future<ConfirmedSpecialOrderModel?> getConfirmedOrderById(String id) async {
    final response = await _dio.get(ApiEndpoints.specialOrderMyOrderById(id));
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    if (data.isEmpty || data['id'] == null) {
      return null;
    }
    return ConfirmedSpecialOrderModel.fromJson(data);
  }

  /// Fetch confirmed order associated with a request ID
  Future<ConfirmedSpecialOrderModel?> getConfirmedOrderForRequest(String requestId) async {
    final response = await _dio.get(ApiEndpoints.specialOrderMyOrderForRequest(requestId));
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    if (data.isEmpty || data['id'] == null) {
      return null;
    }
    return ConfirmedSpecialOrderModel.fromJson(data);
  }
}
