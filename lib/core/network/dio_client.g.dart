// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionCoordinator)
final sessionCoordinatorProvider = SessionCoordinatorProvider._();

final class SessionCoordinatorProvider
    extends
        $FunctionalProvider<
          SessionCoordinator,
          SessionCoordinator,
          SessionCoordinator
        >
    with $Provider<SessionCoordinator> {
  SessionCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionCoordinatorHash();

  @$internal
  @override
  $ProviderElement<SessionCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionCoordinator create(Ref ref) {
    return sessionCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionCoordinator>(value),
    );
  }
}

String _$sessionCoordinatorHash() =>
    r'137a1853b7856a42664e1eaebec801d8c6138e8e';

@ProviderFor(AuthTokenNotifier)
final authTokenProvider = AuthTokenNotifierProvider._();

final class AuthTokenNotifierProvider
    extends $NotifierProvider<AuthTokenNotifier, String?> {
  AuthTokenNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authTokenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authTokenNotifierHash();

  @$internal
  @override
  AuthTokenNotifier create() => AuthTokenNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$authTokenNotifierHash() => r'cfe37883725446a46b577d13af21a58559139204';

abstract class _$AuthTokenNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(dioClient)
final dioClientProvider = DioClientProvider._();

final class DioClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dioClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioClientHash() => r'3363bf0729e57fc11a1b7e3d57b58cc984767855';
