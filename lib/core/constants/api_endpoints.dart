import 'dart:io';

class ApiEndpoints {
  static String baseUrl = ( Platform.isIOS)? "http://127.0.0.1:3000/api/v1":
  'http://10.0.2.2:3000/api/v1';

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

  // Addresses
  static const String addresses = '/addresses';
  static String addressById(String id) => '/addresses/$id';
  static String addressDefaultShipping(String id) => '/addresses/$id/default-shipping';
  static String addressDefaultBilling(String id) => '/addresses/$id/default-billing';

  // Orders & Checkout
  static const String myOrders = '/my';
  static String myOrderById(String id) => '/my/$id';
  static const String checkout = '/checkout';
  static String paymentByOrderId(String orderId) => '/payments/order/$orderId';
}
