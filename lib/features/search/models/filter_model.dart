class FilterModel {
  final double minPrice;
  final double maxPrice;
  final String? categoryId;
  final String? brandId;
  final String sortBy;
  final String sortOrder;

  const FilterModel({
    this.minPrice = 0.0,
    this.maxPrice = 200.0,
    this.categoryId,
    this.brandId,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  FilterModel copyWith({
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? brandId,
    String? sortBy,
    String? sortOrder,
  }) {
    return FilterModel(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
