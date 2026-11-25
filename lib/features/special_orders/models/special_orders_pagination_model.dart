class SpecialOrdersPaginationModel {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const SpecialOrdersPaginationModel({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory SpecialOrdersPaginationModel.fromJson(Map<String, dynamic> json) {
    return SpecialOrdersPaginationModel(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class PaginatedSpecialOrdersModel<T> {
  final List<T> items;
  final SpecialOrdersPaginationModel pagination;

  const PaginatedSpecialOrdersModel({
    required this.items,
    required this.pagination,
  });
}
