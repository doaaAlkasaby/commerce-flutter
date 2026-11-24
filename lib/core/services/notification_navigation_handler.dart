import 'package:flutter/material.dart';
import 'package:ecommerce/features/orders/presentation/screens/order_details_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class NotificationNavigationHandler {
  static String? pendingOrderId;
  static final Set<String> _processedKeys = {};

  static void resetForTesting() {
    pendingOrderId = null;
    _processedKeys.clear();
  }

  static String? extractOrderId(Map<String, dynamic> data) {
    final rawId = data['orderId'] ?? data['order_id'] ?? data['order'];
    if (rawId != null && rawId.toString().trim().isNotEmpty) {
      return rawId.toString().trim();
    }
    return null;
  }

  static bool processNotificationTap(
    Map<String, dynamic> data, {
    required String? authToken,
    BuildContext? context,
  }) {
    final orderId = extractOrderId(data);
    final notificationId =
        data['notificationId']?.toString() ?? data['id']?.toString() ?? orderId;

    if (notificationId != null) {
      final eventType = data['eventType']?.toString() ?? 'ORDER_PLACED';
      final dedupeKey = '${eventType}_$notificationId';
      if (_processedKeys.contains(dedupeKey)) {
        return false;
      }
      _processedKeys.add(dedupeKey);
    }

    if (orderId == null) return false;

    if (authToken == null || authToken.isEmpty) {
      pendingOrderId = orderId;
      return false;
    }

    return navigateToOrderDetails(orderId, context: context);
  }

  static bool checkAndNavigatePending({
    required String? authToken,
    BuildContext? context,
  }) {
    if (authToken != null && authToken.isNotEmpty && pendingOrderId != null) {
      final orderId = pendingOrderId!;
      pendingOrderId = null;
      return navigateToOrderDetails(orderId, context: context);
    }
    return false;
  }

  static bool navigateToOrderDetails(String orderId, {BuildContext? context}) {
    final navContext = context ?? rootNavigatorKey.currentContext;
    if (navContext != null) {
      Navigator.of(navContext).push(
        MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId)),
      );
      return true;
    }
    return false;
  }
}
