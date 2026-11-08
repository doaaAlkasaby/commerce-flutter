// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storefront_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storefrontRepository)
final storefrontRepositoryProvider = StorefrontRepositoryProvider._();

final class StorefrontRepositoryProvider
    extends
        $FunctionalProvider<
          StorefrontRepository,
          StorefrontRepository,
          StorefrontRepository
        >
    with $Provider<StorefrontRepository> {
  StorefrontRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storefrontRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storefrontRepositoryHash();

  @$internal
  @override
  $ProviderElement<StorefrontRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StorefrontRepository create(Ref ref) {
    return storefrontRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorefrontRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorefrontRepository>(value),
    );
  }
}

String _$storefrontRepositoryHash() =>
    r'36d397a29dbbb4921344f31f6eac6fb607a44ac5';

@ProviderFor(storefront)
final storefrontProvider = StorefrontProvider._();

final class StorefrontProvider
    extends
        $FunctionalProvider<
          AsyncValue<StorefrontModel>,
          StorefrontModel,
          FutureOr<StorefrontModel>
        >
    with $FutureModifier<StorefrontModel>, $FutureProvider<StorefrontModel> {
  StorefrontProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storefrontProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storefrontHash();

  @$internal
  @override
  $FutureProviderElement<StorefrontModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StorefrontModel> create(Ref ref) {
    return storefront(ref);
  }
}

String _$storefrontHash() => r'0e8e97cf381746eec9eea92b68063b91c6637b95';
