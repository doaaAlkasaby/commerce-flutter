import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/providers/home_provider.dart';
import 'package:ecommerce/features/search/models/filter_model.dart';

part 'search_provider.g.dart';

@Riverpod(keepAlive: true)
class SearchQueryNotifier extends _$SearchQueryNotifier {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@Riverpod(keepAlive: true)
class FilterNotifier extends _$FilterNotifier {
  @override
  FilterModel build() => const FilterModel(minPrice: 0, maxPrice: 100);

  void updateFilter(FilterModel filter) {
    state = filter;
  }

  void resetFilter() {
    state = const FilterModel(minPrice: 0, maxPrice: 100);
  }
}

@riverpod
List<ProductModel> filteredProducts(Ref ref) {
  final homeDataAsync = ref.watch(homeDataProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filter = ref.watch(filterProvider);

  return homeDataAsync.maybeWhen(
    data: (homeResponse) {
      final sectionsList = homeResponse.data.sections;
      List<ProductModel> productsList = [];
      for (final section in sectionsList) {
        if (section.products.isNotEmpty) {
          productsList.addAll(section.products);
        }
      }

      return productsList.where((p) {
        final matchesQuery = p.name.toLowerCase().contains(query);
        final matchesPrice = (p.priceInfo.finalPrice) >= filter.minPrice &&
            (p.priceInfo.finalPrice) <= filter.maxPrice;
        final matchesRating = p.rating >= filter.minRating;

        return matchesQuery && matchesPrice && matchesRating;
      }).toList();
    },
    orElse: () => [],
  );
}
