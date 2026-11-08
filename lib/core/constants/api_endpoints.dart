import 'package:ecommerce/core/config/app_environment.dart';

class ApiEndpoints {
  static String get baseUrl => AppEnvironment.baseUrl;

  // Storefront Bootstrap
  static const String storefront = '/storefront';

  // App settings
  static const String appSettings = '/app-settings';

  // Home
  static const String home = '/home';

  // Health & Ready
  static const String health = '/health';
  static const String ready = '/ready';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String logoutAll = '/auth/logout-all';

  // Users
  static const String usersMe = '/users/me';
  static String userStatus(String id) => '/users/$id/status';
  static const String adminTest = '/users/admin-test';
  static const String verifiedTest = '/users/verified-test';

  // Categories
  static const String categories = '/categories';
  static const String categoriesActive = '/categories/active';
  static String categoryById(String id) => '/categories/$id';
  static String categoryChildren(String id) => '/categories/$id/children';
  static String categoryStatus(String id) => '/categories/$id/status';
  static String categoryImage(String id) => '/categories/$id/image';

  // Brands
  static const String brands = '/brands';
  static const String brandsActive = '/brands/active';
  static String brandById(String id) => '/brands/$id';
  static String brandStatus(String id) => '/brands/$id/status';
  static String brandImage(String id) => '/brands/$id/image';

  // Products
  static const String products = '/products';
  static const String productsOffers = '/products/offers';
  static const String productsBestSellers = '/products/best-sellers';
  static const String productsNewArrivals = '/products/new-arrivals';
  static String productById(String id) => '/products/$id';
  static String productReviews(String id) => '/products/$id/reviews';

  // Wishlist
  static const String wishlist = '/wishlist';
  static const String wishlistItems = '/wishlist/items';
  static String wishlistByProduct(String productId) =>
      '/wishlist/items/$productId';
  static String wishlistCheck(String productId) => '/wishlist/check/$productId';

  // Addresses
  static const String addresses = '/addresses';
  static String addressById(String id) => '/addresses/$id';
  static String addressDefaultShipping(String id) =>
      '/addresses/$id/default-shipping';
  static String addressDefaultBilling(String id) =>
      '/addresses/$id/default-billing';

  // Orders & Checkout
  static const String ordersMy = '/orders/my';
  static String orderMyById(String id) => '/orders/my/$id';
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';
  static const String checkout = '/checkout';
  static String paymentByOrderId(String orderId) => '/payments/order/$orderId';

  // Cart
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItemById(String variantId) => '/cart/items/$variantId';

  // Devices
  static const String devices = '/devices';
  static String deviceDeactivate(String deviceId) =>
      '/devices/$deviceId/deactivate';
  static String deviceById(String deviceId) => '/devices/$deviceId';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationById(String id) => '/notifications/$id';
}
