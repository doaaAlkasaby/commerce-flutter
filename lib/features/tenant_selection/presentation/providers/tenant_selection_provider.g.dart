// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(discoveryStorefrontRepository)
final discoveryStorefrontRepositoryProvider =
    DiscoveryStorefrontRepositoryProvider._();

final class DiscoveryStorefrontRepositoryProvider
    extends
        $FunctionalProvider<
          StorefrontRepository,
          StorefrontRepository,
          StorefrontRepository
        >
    with $Provider<StorefrontRepository> {
  DiscoveryStorefrontRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryStorefrontRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryStorefrontRepositoryHash();

  @$internal
  @override
  $ProviderElement<StorefrontRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StorefrontRepository create(Ref ref) {
    return discoveryStorefrontRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorefrontRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorefrontRepository>(value),
    );
  }
}

String _$discoveryStorefrontRepositoryHash() =>
    r'61b323d457fb0a0429f5773ac1255384c7a9538b';

@ProviderFor(PublicStoresNotifier)
final publicStoresProvider = PublicStoresNotifierProvider._();

final class PublicStoresNotifierProvider
    extends
        $AsyncNotifierProvider<PublicStoresNotifier, List<PublicStoreModel>> {
  PublicStoresNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicStoresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicStoresNotifierHash();

  @$internal
  @override
  PublicStoresNotifier create() => PublicStoresNotifier();
}

String _$publicStoresNotifierHash() =>
    r'2c99aa447d24a4b9cfffe2ceae10c0e15588aa6a';

abstract class _$PublicStoresNotifier
    extends $AsyncNotifier<List<PublicStoreModel>> {
  FutureOr<List<PublicStoreModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PublicStoreModel>>, List<PublicStoreModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PublicStoreModel>>,
                List<PublicStoreModel>
              >,
              AsyncValue<List<PublicStoreModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
