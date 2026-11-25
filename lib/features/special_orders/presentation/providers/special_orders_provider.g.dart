// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'special_orders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(specialOrdersRepository)
final specialOrdersRepositoryProvider = SpecialOrdersRepositoryProvider._();

final class SpecialOrdersRepositoryProvider
    extends
        $FunctionalProvider<
          SpecialOrdersRepository,
          SpecialOrdersRepository,
          SpecialOrdersRepository
        >
    with $Provider<SpecialOrdersRepository> {
  SpecialOrdersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'specialOrdersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$specialOrdersRepositoryHash();

  @$internal
  @override
  $ProviderElement<SpecialOrdersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SpecialOrdersRepository create(Ref ref) {
    return specialOrdersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpecialOrdersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpecialOrdersRepository>(value),
    );
  }
}

String _$specialOrdersRepositoryHash() =>
    r'66a02fc60caf03aa518a7f61e55a7922bf88a1e0';

@ProviderFor(MySpecialOrdersRequestsController)
final mySpecialOrdersRequestsControllerProvider =
    MySpecialOrdersRequestsControllerProvider._();

final class MySpecialOrdersRequestsControllerProvider
    extends
        $AsyncNotifierProvider<
          MySpecialOrdersRequestsController,
          PaginatedRequestsState
        > {
  MySpecialOrdersRequestsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySpecialOrdersRequestsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$mySpecialOrdersRequestsControllerHash();

  @$internal
  @override
  MySpecialOrdersRequestsController create() =>
      MySpecialOrdersRequestsController();
}

String _$mySpecialOrdersRequestsControllerHash() =>
    r'1e9df6ef74a4fa0f1b12569226ceb6f0d57eb514';

abstract class _$MySpecialOrdersRequestsController
    extends $AsyncNotifier<PaginatedRequestsState> {
  FutureOr<PaginatedRequestsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PaginatedRequestsState>, PaginatedRequestsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PaginatedRequestsState>,
                PaginatedRequestsState
              >,
              AsyncValue<PaginatedRequestsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(MyConfirmedSpecialOrdersController)
final myConfirmedSpecialOrdersControllerProvider =
    MyConfirmedSpecialOrdersControllerProvider._();

final class MyConfirmedSpecialOrdersControllerProvider
    extends
        $AsyncNotifierProvider<
          MyConfirmedSpecialOrdersController,
          PaginatedConfirmedOrdersState
        > {
  MyConfirmedSpecialOrdersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myConfirmedSpecialOrdersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$myConfirmedSpecialOrdersControllerHash();

  @$internal
  @override
  MyConfirmedSpecialOrdersController create() =>
      MyConfirmedSpecialOrdersController();
}

String _$myConfirmedSpecialOrdersControllerHash() =>
    r'58f3195fe7710d4bf28fcd569d06c354ca82b49a';

abstract class _$MyConfirmedSpecialOrdersController
    extends $AsyncNotifier<PaginatedConfirmedOrdersState> {
  FutureOr<PaginatedConfirmedOrdersState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PaginatedConfirmedOrdersState>,
              PaginatedConfirmedOrdersState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PaginatedConfirmedOrdersState>,
                PaginatedConfirmedOrdersState
              >,
              AsyncValue<PaginatedConfirmedOrdersState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(specialOrderRequestDetail)
final specialOrderRequestDetailProvider = SpecialOrderRequestDetailFamily._();

final class SpecialOrderRequestDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SpecialOrderRequestModel?>,
          SpecialOrderRequestModel?,
          FutureOr<SpecialOrderRequestModel?>
        >
    with
        $FutureModifier<SpecialOrderRequestModel?>,
        $FutureProvider<SpecialOrderRequestModel?> {
  SpecialOrderRequestDetailProvider._({
    required SpecialOrderRequestDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'specialOrderRequestDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$specialOrderRequestDetailHash();

  @override
  String toString() {
    return r'specialOrderRequestDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SpecialOrderRequestModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SpecialOrderRequestModel?> create(Ref ref) {
    final argument = this.argument as String;
    return specialOrderRequestDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SpecialOrderRequestDetailProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$specialOrderRequestDetailHash() =>
    r'd1e480be99eac75805c8544d250a0e6ad6d10ea3';

final class SpecialOrderRequestDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<SpecialOrderRequestModel?>, String> {
  SpecialOrderRequestDetailFamily._()
    : super(
        retry: null,
        name: r'specialOrderRequestDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SpecialOrderRequestDetailProvider call(String id) =>
      SpecialOrderRequestDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'specialOrderRequestDetailProvider';
}

@ProviderFor(confirmedSpecialOrderDetail)
final confirmedSpecialOrderDetailProvider =
    ConfirmedSpecialOrderDetailFamily._();

final class ConfirmedSpecialOrderDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConfirmedSpecialOrderModel?>,
          ConfirmedSpecialOrderModel?,
          FutureOr<ConfirmedSpecialOrderModel?>
        >
    with
        $FutureModifier<ConfirmedSpecialOrderModel?>,
        $FutureProvider<ConfirmedSpecialOrderModel?> {
  ConfirmedSpecialOrderDetailProvider._({
    required ConfirmedSpecialOrderDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'confirmedSpecialOrderDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$confirmedSpecialOrderDetailHash();

  @override
  String toString() {
    return r'confirmedSpecialOrderDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ConfirmedSpecialOrderModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConfirmedSpecialOrderModel?> create(Ref ref) {
    final argument = this.argument as String;
    return confirmedSpecialOrderDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConfirmedSpecialOrderDetailProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$confirmedSpecialOrderDetailHash() =>
    r'6674ecb773ef07c5f5196e62781a46eb2fe2e9ad';

final class ConfirmedSpecialOrderDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ConfirmedSpecialOrderModel?>,
          String
        > {
  ConfirmedSpecialOrderDetailFamily._()
    : super(
        retry: null,
        name: r'confirmedSpecialOrderDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConfirmedSpecialOrderDetailProvider call(String id) =>
      ConfirmedSpecialOrderDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'confirmedSpecialOrderDetailProvider';
}
