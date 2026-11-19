import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/providers/home_provider.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/search/models/filter_model.dart';

part 'search_provider.g.dart';

class PaginatedProductsState {
  final List<ProductModel> items;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String? loadMoreError;

  const PaginatedProductsState({
    required this.items,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => page < totalPages;

  PaginatedProductsState copyWith({
    List<ProductModel>? items,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return PaginatedProductsState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

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
  FilterModel build() => const FilterModel();

  void updateFilter(FilterModel filter) {
    state = filter;
  }

  void resetFilter() {
    state = const FilterModel();
  }
}

@riverpod
class SearchController extends _$SearchController {
  int _requestRevision = 0;

  @override
  Future<PaginatedProductsState> build() async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final query = ref.watch(searchQueryProvider);
    final filter = ref.watch(filterProvider);
    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final requestToken = ref.watch(authTokenProvider);

    final repository = ProductRepository(ref.watch(dioClientProvider));

    final result = await repository.getPaginatedProducts(
      search: query,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      categoryId: filter.categoryId,
      brandId: filter.brandId,
      sortBy: filter.sortBy,
      sortOrder: filter.sortOrder,
      page: 1,
      limit: 20,
    );

    if (!ref.mounted) {
      return const PaginatedProductsState(items: [], page: 1, totalPages: 1);
    }

    if (_requestRevision != currentRev ||
        ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        ref.read(authTokenProvider) != requestToken) {
      return const PaginatedProductsState(items: [], page: 1, totalPages: 1);
    }

    return PaginatedProductsState(
      items: result.items,
      page: result.page,
      totalPages: result.totalPages,
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    final currentRev = _requestRevision;
    final requestTenantSlug = ref.read(selectedTenantSlugProvider);
    final requestToken = ref.read(authTokenProvider);

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final query = ref.read(searchQueryProvider);
      final filter = ref.read(filterProvider);
      final nextPage = currentState.page + 1;

      final repository = ProductRepository(ref.read(dioClientProvider));

      final result = await repository.getPaginatedProducts(
        search: query,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        categoryId: filter.categoryId,
        brandId: filter.brandId,
        sortBy: filter.sortBy,
        sortOrder: filter.sortOrder,
        page: nextPage,
        limit: 20,
      );

      if (!ref.mounted) return;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != requestToken) {
        return;
      }

      final existingIds = currentState.items.map((i) => i.id).toSet();
      final uniqueNewItems = result.items
          .where((i) => !existingIds.contains(i.id))
          .toList();

      state = AsyncValue.data(
        currentState.copyWith(
          items: [...currentState.items, ...uniqueNewItems],
          page: result.page,
          totalPages: result.totalPages,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != requestToken) {
        return;
      }

      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    _requestRevision++;
    ref.invalidateSelf();
    await future;
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
        final matchesMinPrice = (p.priceInfo.finalPrice) >= filter.minPrice;
        final matchesMaxPrice =
            filter.maxPrice == null ||
            (p.priceInfo.finalPrice) <= filter.maxPrice!;

        return matchesQuery && matchesMinPrice && matchesMaxPrice;
      }).toList();
    },
    orElse: () => [],
  );
}
