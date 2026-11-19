import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/notification_model.dart';

class PaginatedNotificationsResultModel {
  final List<NotificationModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final int unreadCount;

  const PaginatedNotificationsResultModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.unreadCount,
  });
}

class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository(this._dio);

  Future<PaginatedNotificationsResultModel> getPaginatedNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );

    final rawData = response.data['data'];
    final List list = rawData is List
        ? rawData
        : (rawData is Map
              ? (rawData['items'] ?? rawData['notifications'] ?? [])
              : []);

    final items = list
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    int respPage = page;
    int respLimit = limit;
    int total = items.length;
    int totalPages = 1;
    int unreadCount = 0;

    if (rawData is Map) {
      if (rawData['pagination'] is Map) {
        final pMap = rawData['pagination'] as Map<String, dynamic>;
        respPage = pMap['page'] is int ? pMap['page'] as int : page;
        respLimit = pMap['limit'] is int ? pMap['limit'] as int : limit;
        total = pMap['total'] is int ? pMap['total'] as int : items.length;
        totalPages = pMap['totalPages'] is int ? pMap['totalPages'] as int : 1;
      }
      if (rawData['unreadCount'] is int) {
        unreadCount = rawData['unreadCount'] as int;
      }
    }

    return PaginatedNotificationsResultModel(
      items: items,
      page: respPage,
      limit: respLimit,
      total: total,
      totalPages: totalPages,
      unreadCount: unreadCount,
    );
  }

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await getPaginatedNotifications(page: page, limit: limit);
    return result.items;
  }

  Future<void> markAllAsRead() async {
    await _dio.patch(ApiEndpoints.notificationsReadAll);
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch(ApiEndpoints.notificationRead(id));
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete(ApiEndpoints.notificationById(id));
  }
}
