// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(addressRepository)
final addressRepositoryProvider = AddressRepositoryProvider._();

final class AddressRepositoryProvider
    extends
        $FunctionalProvider<
          AddressRepository,
          AddressRepository,
          AddressRepository
        >
    with $Provider<AddressRepository> {
  AddressRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressRepositoryHash();

  @$internal
  @override
  $ProviderElement<AddressRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AddressRepository create(Ref ref) {
    return addressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddressRepository>(value),
    );
  }
}

String _$addressRepositoryHash() => r'b969a2cef98aa15dbc2736524717003e56faafbf';

@ProviderFor(supportedCountries)
final supportedCountriesProvider = SupportedCountriesProvider._();

final class SupportedCountriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CountryModel>>,
          List<CountryModel>,
          FutureOr<List<CountryModel>>
        >
    with
        $FutureModifier<List<CountryModel>>,
        $FutureProvider<List<CountryModel>> {
  SupportedCountriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportedCountriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportedCountriesHash();

  @$internal
  @override
  $FutureProviderElement<List<CountryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CountryModel>> create(Ref ref) {
    return supportedCountries(ref);
  }
}

String _$supportedCountriesHash() =>
    r'74319c763048236d1c14b03fda6980c1020a64a6';

@ProviderFor(AddressNotifier)
final addressProvider = AddressNotifierProvider._();

final class AddressNotifierProvider
    extends $AsyncNotifierProvider<AddressNotifier, List<AddressModel>> {
  AddressNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressNotifierHash();

  @$internal
  @override
  AddressNotifier create() => AddressNotifier();
}

String _$addressNotifierHash() => r'55303bf90471001c14cc8c52b7416a2fb9568e7f';

abstract class _$AddressNotifier extends $AsyncNotifier<List<AddressModel>> {
  FutureOr<List<AddressModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<AddressModel>>, List<AddressModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AddressModel>>, List<AddressModel>>,
              AsyncValue<List<AddressModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
