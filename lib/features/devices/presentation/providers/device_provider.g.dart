// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceRepository)
final deviceRepositoryProvider = DeviceRepositoryProvider._();

final class DeviceRepositoryProvider
    extends
        $FunctionalProvider<
          DeviceRepository,
          DeviceRepository,
          DeviceRepository
        >
    with $Provider<DeviceRepository> {
  DeviceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeviceRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceRepository create(Ref ref) {
    return deviceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceRepository>(value),
    );
  }
}

String _$deviceRepositoryHash() => r'ebcb11d8b59d08fef0181c9ca5f8c94a9b2ec048';

@ProviderFor(DeviceRegistrationNotifier)
final deviceRegistrationProvider = DeviceRegistrationNotifierProvider._();

final class DeviceRegistrationNotifierProvider
    extends $NotifierProvider<DeviceRegistrationNotifier, DeviceDto?> {
  DeviceRegistrationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRegistrationNotifierHash();

  @$internal
  @override
  DeviceRegistrationNotifier create() => DeviceRegistrationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceDto? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceDto?>(value),
    );
  }
}

String _$deviceRegistrationNotifierHash() =>
    r'3a0eebc351592bce5ea46a4683058507c8f8b900';

abstract class _$DeviceRegistrationNotifier extends $Notifier<DeviceDto?> {
  DeviceDto? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DeviceDto?, DeviceDto?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeviceDto?, DeviceDto?>,
              DeviceDto?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
