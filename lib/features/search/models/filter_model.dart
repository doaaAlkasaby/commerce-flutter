class FilterModel {
  final double minPrice;
  final double maxPrice;
  final List<String> selectedCategories;
  final List<String> selectedBrands;
  final double minRating;

  const FilterModel({
    this.minPrice = 0.0,
    this.maxPrice = 100.0,
    this.selectedCategories = const [],
    this.selectedBrands = const [],
    this.minRating = 0.0,
  });

  FilterModel copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? selectedCategories,
    List<String>? selectedBrands,
    double? minRating,
  }) {
    return FilterModel(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      minRating: minRating ?? this.minRating,
    );
  }
}
