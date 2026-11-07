import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository(this._dio);

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(ApiEndpoints.notifications, queryParameters: {'page': page, 'limit': limit});
      final rawData = response.data['data'];
      final List list = rawData is List ? rawData : (rawData['notifications'] ?? rawData['items'] ?? []);
      return list.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
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
