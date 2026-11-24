import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/services/notification_service.dart';
import 'package:ecommerce/core/utils/app_logger.dart';
import '../../data/device_repository.dart';
import '../../models/device_model.dart';

part 'device_provider.g.dart';

@Riverpod(keepAlive: true)
DeviceRepository deviceRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return DeviceRepository(dio);
}

@Riverpod(keepAlive: true)
class DeviceRegistrationNotifier extends _$DeviceRegistrationNotifier {
  StreamSubscription<String>? _tokenRefreshSubscription;
  Completer<DeviceDto?>? _inFlightRegistration;
  bool _isRegistering = false;
  bool _hasFailedForCurrentContext = false;
  String? _queuedTokenRefresh;
  DeviceDto? _registeredDevice;

  // Last attempted context
  String? _lastAttemptedSessionId;
  String? _lastAttemptedTenantSlug;

  // Last successfully registered context
  String? _lastRegisteredFcmToken;
  String? _lastRegisteredSessionId;
  String? _lastRegisteredTenantSlug;

  @override
  DeviceDto? build() {
    final authToken = ref.watch(authTokenProvider);
    final tenantSlug = ref.watch(selectedTenantSlugProvider);
    final coordinator = ref.watch(sessionCoordinatorProvider);
    final sessionId = coordinator.currentSessionId ?? authToken;

    if (authToken == null || authToken.isEmpty) {
      if (_lastRegisteredSessionId != null || _lastAttemptedSessionId != null) {
        _clearContext();
        deactivateCurrentDeviceBeforeLogout();
      }
      _registeredDevice = null;
      return null;
    }

    final contextChanged =
        _lastAttemptedSessionId != sessionId ||
        _lastAttemptedTenantSlug != tenantSlug;

    if (contextChanged) {
      _hasFailedForCurrentContext = false;
      _lastAttemptedSessionId = sessionId;
      _lastAttemptedTenantSlug = tenantSlug;
      _registeredDevice = null;
    }

    final isAlreadyRegistered =
        _lastRegisteredSessionId == sessionId &&
        _lastRegisteredTenantSlug == tenantSlug &&
        _lastRegisteredFcmToken != null;

    if (!_isRegistering &&
        !_hasFailedForCurrentContext &&
        !isAlreadyRegistered) {
      Future.microtask(() => registerDevice());
    }

    _setupTokenRefreshListener();

    ref.onDispose(() {
      _tokenRefreshSubscription?.cancel();
    });

    return isAlreadyRegistered ? _registeredDevice : null;
  }

  void _setupTokenRefreshListener() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = AppNotificationService().onTokenRefresh.listen((
      newToken,
    ) {
      if (!ref.mounted) return;
      final token = ref.read(authTokenProvider);
      if (token != null && token.isNotEmpty) {
        _hasFailedForCurrentContext = false;
        if (_isRegistering) {
          _queuedTokenRefresh = newToken;
        } else {
          registerDevice(forcedToken: newToken);
        }
      }
    });
  }

  bool _isRetryableError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.cancel) {
        return false;
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        if (statusCode >= 400 && statusCode < 500) {
          return false;
        }
        if (statusCode >= 500) {
          return true;
        }
        return false;
      }
      return true;
    }
    return false;
  }

  /// Public trigger to retry device registration after connectivity recovery
  /// or when triggered by network events.
  Future<DeviceDto?> retryRegistration() async {
    if (!ref.mounted) return null;
    _hasFailedForCurrentContext = false;
    return registerDevice();
  }

  Future<DeviceDto?> registerDevice({String? forcedToken}) async {
    if (!ref.mounted) return null;

    if (_inFlightRegistration != null) {
      return _inFlightRegistration!.future;
    }

    final capturedAuthToken = ref.read(authTokenProvider);
    if (capturedAuthToken == null || capturedAuthToken.isEmpty) return null;

    final capturedSessionId =
        ref.read(sessionCoordinatorProvider).currentSessionId ??
        capturedAuthToken;
    final capturedTenantSlug = ref.read(selectedTenantSlugProvider);

    final completer = Completer<DeviceDto?>();
    _inFlightRegistration = completer;
    _isRegistering = true;
    _lastAttemptedSessionId = capturedSessionId;
    _lastAttemptedTenantSlug = capturedTenantSlug;

    DeviceDto? resultDevice;

    try {
      final fcmToken =
          forcedToken ?? await AppNotificationService().getDeviceToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        resultDevice = null;
        return null;
      }

      final isSameContext =
          _lastRegisteredSessionId == capturedSessionId &&
          _lastRegisteredTenantSlug == capturedTenantSlug &&
          _lastRegisteredFcmToken == fcmToken;

      if (_registeredDevice != null && isSameContext) {
        resultDevice = _registeredDevice;
        return _registeredDevice;
      }

      String? appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = info.version;
      } catch (_) {}

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'IOS'
          : 'ANDROID';

      if (!ref.mounted) {
        resultDevice = null;
        return null;
      }
      final repository = ref.read(deviceRepositoryProvider);

      int retryAttempts = 0;
      const maxRetries = 2;
      DeviceDto? device;

      while (retryAttempts <= maxRetries) {
        try {
          device = await repository.registerDevice(
            RegisterDeviceRequest(
              token: fcmToken,
              platform: platform,
              appVersion: appVersion,
            ),
          );
          break;
        } catch (e) {
          if (!_isRetryableError(e)) {
            rethrow;
          }
          retryAttempts++;
          if (retryAttempts > maxRetries) rethrow;
          await Future.delayed(Duration(milliseconds: 200 * retryAttempts));
        }
      }

      if (!ref.mounted) {
        resultDevice = null;
        return null;
      }

      final latestAuthToken = ref.read(authTokenProvider);
      final latestSessionId =
          ref.read(sessionCoordinatorProvider).currentSessionId ??
          latestAuthToken;
      final latestTenantSlug = ref.read(selectedTenantSlugProvider);

      if (latestAuthToken == null ||
          latestAuthToken.isEmpty ||
          latestSessionId != capturedSessionId ||
          latestTenantSlug != capturedTenantSlug) {
        // Late registration finished after context changed or session ended!
        final lateDeviceId = device?.id;
        final activeDeviceIdForNewUser = _registeredDevice?.id;

        if (lateDeviceId != null &&
            lateDeviceId.isNotEmpty &&
            lateDeviceId != activeDeviceIdForNewUser) {
          unawaited(() async {
            try {
              final repo = ref.read(deviceRepositoryProvider);
              await repo
                  .deactivateDevice(lateDeviceId)
                  .timeout(const Duration(seconds: 3));
            } catch (e) {
              AppLogger.log(
                'Cleanup deactivation for late registration timed out or failed',
                name: 'FCM',
              );
            }
          }());
        }
        resultDevice = null;
        return null;
      }

      _lastRegisteredFcmToken = fcmToken;
      _lastRegisteredSessionId = capturedSessionId;
      _lastRegisteredTenantSlug = capturedTenantSlug;
      _hasFailedForCurrentContext = false;

      _registeredDevice = device;
      state = device;
      resultDevice = device;
      return device;
    } catch (e) {
      _hasFailedForCurrentContext = true;
      if (e is DioException) {
        AppLogger.log(
          'Device registration error (${e.response?.statusCode ?? e.type})',
          name: 'FCM',
        );
      } else {
        AppLogger.log(
          'Device registration exception: ${e.runtimeType}',
          name: 'FCM',
        );
      }
      resultDevice = null;
      return null;
    } finally {
      _isRegistering = false;
      _inFlightRegistration = null;
      if (!completer.isCompleted) {
        completer.complete(resultDevice);
      }

      if (ref.mounted) {
        final latestAuthToken = ref.read(authTokenProvider);
        final latestSessionId =
            ref.read(sessionCoordinatorProvider).currentSessionId ??
            latestAuthToken;
        final latestTenantSlug = ref.read(selectedTenantSlugProvider);

        if (_queuedTokenRefresh != null) {
          final nextToken = _queuedTokenRefresh;
          _queuedTokenRefresh = null;
          if (latestAuthToken != null && latestAuthToken.isNotEmpty) {
            _hasFailedForCurrentContext = false;
            Future.microtask(() => registerDevice(forcedToken: nextToken));
          }
        } else if (latestAuthToken != null &&
            latestAuthToken.isNotEmpty &&
            (latestSessionId != _lastRegisteredSessionId ||
                latestTenantSlug != _lastRegisteredTenantSlug) &&
            !_hasFailedForCurrentContext) {
          _hasFailedForCurrentContext = false;
          Future.microtask(() => registerDevice());
        }
      }
    }
  }

  Future<void> deactivateCurrentDeviceBeforeLogout() async {
    final currentDevice = _registeredDevice ?? state;
    if (currentDevice == null) return;
    state = null;
    _clearContext();

    if (currentDevice != null && currentDevice.id.isNotEmpty && ref.mounted) {
      try {
        final repository = ref.read(deviceRepositoryProvider);
        await repository
            .deactivateDevice(currentDevice.id)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        AppLogger.log(
          'Deactivation timeout or failure before logout',
          name: 'FCM',
        );
      }
    }
  }

  void _clearContext() {
    _lastRegisteredSessionId = null;
    _lastRegisteredFcmToken = null;
    _lastRegisteredTenantSlug = null;
    _lastAttemptedSessionId = null;
    _lastAttemptedTenantSlug = null;
    _queuedTokenRefresh = null;
    _hasFailedForCurrentContext = false;
    _registeredDevice = null;
  }
}
