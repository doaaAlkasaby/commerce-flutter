// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentRepository)
final paymentRepositoryProvider = PaymentRepositoryProvider._();

final class PaymentRepositoryProvider
    extends
        $FunctionalProvider<
          PaymentRepository,
          PaymentRepository,
          PaymentRepository
        >
    with $Provider<PaymentRepository> {
  PaymentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaymentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentRepository create(Ref ref) {
    return paymentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentRepository>(value),
    );
  }
}

String _$paymentRepositoryHash() => r'1aa90731abf6077a9739eca4f3f4b2ba2f02cfea';

@ProviderFor(OrderPaymentsController)
final orderPaymentsControllerProvider = OrderPaymentsControllerFamily._();

final class OrderPaymentsControllerProvider
    extends
        $AsyncNotifierProvider<
          OrderPaymentsController,
          OrderPaymentsStateData
        > {
  OrderPaymentsControllerProvider._({
    required OrderPaymentsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderPaymentsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderPaymentsControllerHash();

  @override
  String toString() {
    return r'orderPaymentsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrderPaymentsController create() => OrderPaymentsController();

  @override
  bool operator ==(Object other) {
    return other is OrderPaymentsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderPaymentsControllerHash() =>
    r'10d91076469800d6c64b89ffe76ac66daaefe8b1';

final class OrderPaymentsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderPaymentsController,
          AsyncValue<OrderPaymentsStateData>,
          OrderPaymentsStateData,
          FutureOr<OrderPaymentsStateData>,
          String
        > {
  OrderPaymentsControllerFamily._()
    : super(
        retry: null,
        name: r'orderPaymentsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderPaymentsControllerProvider call(String orderId) =>
      OrderPaymentsControllerProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderPaymentsControllerProvider';
}

abstract class _$OrderPaymentsController
    extends $AsyncNotifier<OrderPaymentsStateData> {
  late final _$args = ref.$arg as String;
  String get orderId => _$args;

  FutureOr<OrderPaymentsStateData> build(String orderId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<OrderPaymentsStateData>, OrderPaymentsStateData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<OrderPaymentsStateData>,
                OrderPaymentsStateData
              >,
              AsyncValue<OrderPaymentsStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
