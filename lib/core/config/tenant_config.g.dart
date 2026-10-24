// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TenantNotifier)
final tenantProvider = TenantNotifierProvider._();

final class TenantNotifierProvider
    extends $NotifierProvider<TenantNotifier, TenantConfig> {
  TenantNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantNotifierHash();

  @$internal
  @override
  TenantNotifier create() => TenantNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TenantConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TenantConfig>(value),
    );
  }
}

String _$tenantNotifierHash() => r'1e8fd8418c39dc3c41ce1e2209dde1a1614a8858';

abstract class _$TenantNotifier extends $Notifier<TenantConfig> {
  TenantConfig build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TenantConfig, TenantConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TenantConfig, TenantConfig>,
              TenantConfig,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
