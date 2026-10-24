class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}

class ApiListResponse<T> {
  final bool success;
  final String? message;
  final List<T> data;

  const ApiListResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawData = json['data'];
    List<T> list = [];
    if (rawData is List) {
      list = rawData.map((item) => fromJsonT(item)).toList();
    } else if (rawData is Map<String, dynamic> && rawData['items'] is List) {
      list = (rawData['items'] as List).map((item) => fromJsonT(item)).toList();
    }
    return ApiListResponse<T>(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: list,
    );
  }
}
