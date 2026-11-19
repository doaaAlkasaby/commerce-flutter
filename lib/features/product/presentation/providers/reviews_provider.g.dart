// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviews_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProductReviewsController)
final productReviewsControllerProvider = ProductReviewsControllerFamily._();

final class ProductReviewsControllerProvider
    extends
        $AsyncNotifierProvider<
          ProductReviewsController,
          PaginatedReviewsStateData
        > {
  ProductReviewsControllerProvider._({
    required ProductReviewsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productReviewsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productReviewsControllerHash();

  @override
  String toString() {
    return r'productReviewsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProductReviewsController create() => ProductReviewsController();

  @override
  bool operator ==(Object other) {
    return other is ProductReviewsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productReviewsControllerHash() =>
    r'a583dc34405af52b0694e3dcc93efa138c9e1913';

final class ProductReviewsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductReviewsController,
          AsyncValue<PaginatedReviewsStateData>,
          PaginatedReviewsStateData,
          FutureOr<PaginatedReviewsStateData>,
          String
        > {
  ProductReviewsControllerFamily._()
    : super(
        retry: null,
        name: r'productReviewsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductReviewsControllerProvider call(String productId) =>
      ProductReviewsControllerProvider._(argument: productId, from: this);

  @override
  String toString() => r'productReviewsControllerProvider';
}

abstract class _$ProductReviewsController
    extends $AsyncNotifier<PaginatedReviewsStateData> {
  late final _$args = ref.$arg as String;
  String get productId => _$args;

  FutureOr<PaginatedReviewsStateData> build(String productId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PaginatedReviewsStateData>,
              PaginatedReviewsStateData
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PaginatedReviewsStateData>,
                PaginatedReviewsStateData
              >,
              AsyncValue<PaginatedReviewsStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
