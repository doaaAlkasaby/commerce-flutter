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
    r'94c419cea5a5ad40bb7c3678aaf1cde8ec998ffc';

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

String _$authTokenNotifierHash() => r'5c36665d6ce814812045bf52eb3e3ee1569013f8';

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

String _$dioClientHash() => r'd0b34788778f9d31730e552ae13ca515fe7cf0b3';
