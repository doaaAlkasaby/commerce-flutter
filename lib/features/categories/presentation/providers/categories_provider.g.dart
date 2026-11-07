// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categoriesRepository)
final categoriesRepositoryProvider = CategoriesRepositoryProvider._();

final class CategoriesRepositoryProvider
    extends
        $FunctionalProvider<
          CategoriesRepository,
          CategoriesRepository,
          CategoriesRepository
        >
    with $Provider<CategoriesRepository> {
  CategoriesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoriesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoriesRepository create(Ref ref) {
    return categoriesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoriesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoriesRepository>(value),
    );
  }
}

String _$categoriesRepositoryHash() =>
    r'e44c1901780aff34c422ff3dbc35b5615c2829d6';

@ProviderFor(mainCategories)
final mainCategoriesProvider = MainCategoriesProvider._();

final class MainCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MainCategoryModel>>,
          List<MainCategoryModel>,
          FutureOr<List<MainCategoryModel>>
        >
    with
        $FutureModifier<List<MainCategoryModel>>,
        $FutureProvider<List<MainCategoryModel>> {
  MainCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mainCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mainCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<MainCategoryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MainCategoryModel>> create(Ref ref) {
    return mainCategories(ref);
  }
}

String _$mainCategoriesHash() => r'0f419e664f1c0951c89b33a6f026d2bab87a9d19';

@ProviderFor(activeCategoriesList)
final activeCategoriesListProvider = ActiveCategoriesListProvider._();

final class ActiveCategoriesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  ActiveCategoriesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCategoriesListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCategoriesListHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return activeCategoriesList(ref);
  }
}

String _$activeCategoriesListHash() =>
    r'248bdf1ac1ca54fb5c11c2dec5378c406d21970e';

@ProviderFor(activeBrandsList)
final activeBrandsListProvider = ActiveBrandsListProvider._();

final class ActiveBrandsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  ActiveBrandsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeBrandsListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeBrandsListHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return activeBrandsList(ref);
  }
}

String _$activeBrandsListHash() => r'6b8d710b380e2bfc116ae731bf51877c13bcad73';
