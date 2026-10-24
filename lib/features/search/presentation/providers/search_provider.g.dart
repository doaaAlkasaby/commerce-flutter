// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchQueryNotifier)
final searchQueryProvider = SearchQueryNotifierProvider._();

final class SearchQueryNotifierProvider
    extends $NotifierProvider<SearchQueryNotifier, String> {
  SearchQueryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryNotifierHash();

  @$internal
  @override
  SearchQueryNotifier create() => SearchQueryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryNotifierHash() =>
    r'f1ae2703068ae43b2d4e4e79da07716d4f1297b8';

abstract class _$SearchQueryNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FilterNotifier)
final filterProvider = FilterNotifierProvider._();

final class FilterNotifierProvider
    extends $NotifierProvider<FilterNotifier, FilterModel> {
  FilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterNotifierHash();

  @$internal
  @override
  FilterNotifier create() => FilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilterModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilterModel>(value),
    );
  }
}

String _$filterNotifierHash() => r'2cd3b342831c06bbb2b98ee625737db387ef61ee';

abstract class _$FilterNotifier extends $Notifier<FilterModel> {
  FilterModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FilterModel, FilterModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FilterModel, FilterModel>,
              FilterModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredProducts)
final filteredProductsProvider = FilteredProductsProvider._();

final class FilteredProductsProvider
    extends
        $FunctionalProvider<
          List<ProductModel>,
          List<ProductModel>,
          List<ProductModel>
        >
    with $Provider<List<ProductModel>> {
  FilteredProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredProductsHash();

  @$internal
  @override
  $ProviderElement<List<ProductModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ProductModel> create(Ref ref) {
    return filteredProducts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ProductModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ProductModel>>(value),
    );
  }
}

String _$filteredProductsHash() => r'213beea2d508659a248aefce2ac83e52af3a8ed8';
