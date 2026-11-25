// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'special_orders_availability_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Centralized provider for Special Orders feature submission availability.
///
/// Behavior:
/// - Authoritative Storefront Availability: Derived from `storefrontProvider` settings.
///   Returns `storefront.specialOrders.enabled`.
/// - Fallback / Errors: If storefront is loading or fails, defaults to `false`.

@ProviderFor(SpecialOrdersAvailability)
final specialOrdersAvailabilityProvider = SpecialOrdersAvailabilityProvider._();

/// Centralized provider for Special Orders feature submission availability.
///
/// Behavior:
/// - Authoritative Storefront Availability: Derived from `storefrontProvider` settings.
///   Returns `storefront.specialOrders.enabled`.
/// - Fallback / Errors: If storefront is loading or fails, defaults to `false`.
final class SpecialOrdersAvailabilityProvider
    extends $NotifierProvider<SpecialOrdersAvailability, bool> {
  /// Centralized provider for Special Orders feature submission availability.
  ///
  /// Behavior:
  /// - Authoritative Storefront Availability: Derived from `storefrontProvider` settings.
  ///   Returns `storefront.specialOrders.enabled`.
  /// - Fallback / Errors: If storefront is loading or fails, defaults to `false`.
  SpecialOrdersAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'specialOrdersAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$specialOrdersAvailabilityHash();

  @$internal
  @override
  SpecialOrdersAvailability create() => SpecialOrdersAvailability();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$specialOrdersAvailabilityHash() =>
    r'f210237b72cb734ed7052d9d6b8463083ce47101';

/// Centralized provider for Special Orders feature submission availability.
///
/// Behavior:
/// - Authoritative Storefront Availability: Derived from `storefrontProvider` settings.
///   Returns `storefront.specialOrders.enabled`.
/// - Fallback / Errors: If storefront is loading or fails, defaults to `false`.

abstract class _$SpecialOrdersAvailability extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
