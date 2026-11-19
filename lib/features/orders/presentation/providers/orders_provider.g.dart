// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ordersRepository)
final ordersRepositoryProvider = OrdersRepositoryProvider._();

final class OrdersRepositoryProvider
    extends
        $FunctionalProvider<
          OrdersRepository,
          OrdersRepository,
          OrdersRepository
        >
    with $Provider<OrdersRepository> {
  OrdersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrdersRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrdersRepository create(Ref ref) {
    return ordersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrdersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrdersRepository>(value),
    );
  }
}

String _$ordersRepositoryHash() => r'336c5b7e73d3e99b07a78dd11ed4100534b053d9';

@ProviderFor(MyOrdersController)
final myOrdersControllerProvider = MyOrdersControllerProvider._();

final class MyOrdersControllerProvider
    extends $AsyncNotifierProvider<MyOrdersController, PaginatedOrdersState> {
  MyOrdersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myOrdersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myOrdersControllerHash();

  @$internal
  @override
  MyOrdersController create() => MyOrdersController();
}

String _$myOrdersControllerHash() =>
    r'8867fcd7d8832e8f15dd74da52576c51a10d75f8';

abstract class _$MyOrdersController
    extends $AsyncNotifier<PaginatedOrdersState> {
  FutureOr<PaginatedOrdersState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PaginatedOrdersState>, PaginatedOrdersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PaginatedOrdersState>,
                PaginatedOrdersState
              >,
              AsyncValue<PaginatedOrdersState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(orderDetails)
final orderDetailsProvider = OrderDetailsFamily._();

final class OrderDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderModel?>,
          OrderModel?,
          FutureOr<OrderModel?>
        >
    with $FutureModifier<OrderModel?>, $FutureProvider<OrderModel?> {
  OrderDetailsProvider._({
    required OrderDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDetailsHash();

  @override
  String toString() {
    return r'orderDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrderModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrderModel?> create(Ref ref) {
    final argument = this.argument as String;
    return orderDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDetailsHash() => r'9df6a4b327627e668c39e700d2525d769e6c73f0';

final class OrderDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OrderModel?>, String> {
  OrderDetailsFamily._()
    : super(
        retry: null,
        name: r'orderDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderDetailsProvider call(String orderId) =>
      OrderDetailsProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderDetailsProvider';
}

@ProviderFor(OrderFilterNotifier)
final orderFilterProvider = OrderFilterNotifierProvider._();

final class OrderFilterNotifierProvider
    extends $NotifierProvider<OrderFilterNotifier, String> {
  OrderFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderFilterNotifierHash();

  @$internal
  @override
  OrderFilterNotifier create() => OrderFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$orderFilterNotifierHash() =>
    r'1a66c79977fa57bfaf444142df6eea638c8ec085';

abstract class _$OrderFilterNotifier extends $Notifier<String> {
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
