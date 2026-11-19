const _sentinel = Object();

class FilterModel {
  final double minPrice;
  final double? maxPrice;
  final String? categoryId;
  final String? brandId;
  final String sortBy;
  final String sortOrder;

  const FilterModel({
    this.minPrice = 0.0,
    this.maxPrice,
    this.categoryId,
    this.brandId,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  FilterModel copyWith({
    double? minPrice,
    Object? maxPrice = _sentinel,
    Object? categoryId = _sentinel,
    Object? brandId = _sentinel,
    String? sortBy,
    String? sortOrder,
  }) {
    return FilterModel(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
      categoryId: categoryId == _sentinel
          ? this.categoryId
          : categoryId as String?,
      brandId: brandId == _sentinel ? this.brandId : brandId as String?,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
