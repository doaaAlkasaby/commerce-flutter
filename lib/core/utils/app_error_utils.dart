import 'package:dio/dio.dart';

class AppErrorUtils {
  static String extractErrorMessage(
    Object error, {
    String fallback = 'An unexpected error occurred',
  }) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response?.data;
        if (data is Map &&
            data['message'] != null &&
            data['message'].toString().isNotEmpty) {
          return data['message'].toString();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Network connection error. Please check your internet connection.';
      }
    }
    final errStr = error.toString();
    if (errStr.startsWith('Exception: ')) {
      return errStr.substring(11);
    }
    return fallback;
  }
}
