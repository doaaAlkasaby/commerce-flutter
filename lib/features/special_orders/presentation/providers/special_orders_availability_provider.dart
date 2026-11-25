import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/features/storefront/presentation/providers/storefront_provider.dart';

part 'special_orders_availability_provider.g.dart';

/// Centralized provider for Special Orders feature submission availability.
///
/// Behavior:
/// - Authoritative Storefront Availability: Derived from `storefrontProvider` settings.
///   Returns `storefront.specialOrders.enabled`.
/// - Fallback / Errors: If storefront is loading or fails, defaults to `false`.
@Riverpod(keepAlive: true)
class SpecialOrdersAvailability extends _$SpecialOrdersAvailability {
  @override
  bool build() {
    final storefrontAsync = ref.watch(storefrontProvider);
    return storefrontAsync.value?.specialOrders.enabled ?? false;
  }

  void setEnabled(bool value) {
    state = value;
  }
}
