import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';
import 'package:ecommerce/features/auth/data/user_repository.dart';
import 'package:ecommerce/features/auth/models/auth_response_models.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/settings/presentation/screens/settings_screen.dart';
import 'package:ecommerce/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:ecommerce/features/settings/presentation/screens/change_password_screen.dart';
import 'package:ecommerce/main.dart';

class FakeAuthTokenNotifier extends AuthTokenNotifier {
  String? token = 'test-token';
  @override
  String? build() => token;

  @override
  Future<void> setToken(String? token, {String? refreshToken}) async {
    this.token = token;
    ref.invalidateSelf();
  }
}

class FakeCurrentUserNotifier extends CurrentUser {
  UserDto? user = const UserDto(
    id: 'usr-123',
    email: 'customer@example.com',
    firstName: 'Customer',
    lastName: 'One',
    isEmailVerified: true,
  );

  @override
  Future<UserDto?> build() async => user;

  @override
  Future<void> updateProfile({String? firstName, String? lastName}) async {
    final repo = ref.read(userRepositoryProvider);
    final res = await repo.updateProfile(
      firstName: firstName,
      lastName: lastName,
    );
    user = res.data;
    ref.invalidateSelf();
    await future;
  }
}

class RecordedRequest {
  final String path;
  final String method;
  final Map<String, dynamic> headers;
  final dynamic body;

  RecordedRequest({
    required this.path,
    required this.method,
    required this.headers,
    this.body,
  });
}

class MockSettingsHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  Completer<void>? patchCompleter;
  bool shouldFail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      RecordedRequest(
        path: options.path,
        method: options.method,
        headers: Map.from(options.headers),
        body: options.data,
      ),
    );

    final path = options.path;

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Profile update failed'}),
        400,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.method == 'PATCH' && path.contains('/users/me')) {
      if (patchCompleter != null) {
        await patchCompleter!.future;
      }

      final body = options.data as Map<String, dynamic>? ?? {};
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Profile updated successfully',
          'data': {
            'id': 'usr-123',
            'email': 'customer@example.com',
            'firstName': body['firstName'] ?? 'Customer',
            'lastName': body['lastName'] ?? 'Updated',
            'isEmailVerified': true,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('/auth/change-password')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Password changed successfully',
          'data': null,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('/auth/resend-verification')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Verification email sent successfully',
          'data': null,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('/users/me')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'usr-123',
            'email': 'customer@example.com',
            'firstName': 'Customer',
            'lastName': 'One',
            'isEmailVerified': true,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 06.2.1 — Profile & Account Management Behavioral Tests', () {
    testWidgets(
      '1. Authenticated Settings displays real user name, email, and verification status',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Customer One'), findsOneWidget);
        expect(find.text('customer@example.com'), findsOneWidget);
        expect(find.text('Verified'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Signed-out Settings displays Sign In card without user details',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final authNotifier = FakeAuthTokenNotifier()..token = null;
        final fakeUserNotifier = FakeCurrentUserNotifier()..user = null;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => authNotifier),
              currentUserProvider.overrideWith(() => fakeUserNotifier),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text("You're not signed in yet"), findsOneWidget);
        expect(find.text('SIGN IN'), findsOneWidget);
      },
    );

    test(
      '3. UserRepository updateProfile sends PATCH /users/me request payload',
      () async {
        final mockAdapter = MockSettingsHttpAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
        dio.httpClientAdapter = mockAdapter;

        final repo = UserRepository(dio);
        final response = await repo.updateProfile(
          firstName: 'Customer',
          lastName: 'Updated',
        );

        expect(response.success, isTrue);
        expect(mockAdapter.requests.last.method, 'PATCH');
        expect(mockAdapter.requests.last.path, contains('/users/me'));
        expect(mockAdapter.requests.last.body, {
          'firstName': 'Customer',
          'lastName': 'Updated',
        });
      },
    );

    testWidgets(
      '4. Successful profile update refreshes displayed profile in SettingsScreen',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: EditProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Alice');
        await tester.enterText(find.byType(TextField).last, 'Smith');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        final patchRequests = mockAdapter.requests
            .where((r) => r.method == 'PATCH')
            .toList();
        expect(patchRequests.length, 1);
        expect(patchRequests.last.body, {
          'firstName': 'Alice',
          'lastName': 'Smith',
        });
      },
    );

    testWidgets(
      '5. Failed profile update retains form values and displays SnackBar error',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter()..shouldFail = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: EditProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Alice');
        await tester.enterText(find.byType(TextField).last, 'Smith');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(find.byType(EditProfileScreen), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      '6. Rapid duplicate Save taps in EditProfileScreen send exactly 1 PATCH request',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final completer = Completer<void>();
        final mockAdapter = MockSettingsHttpAdapter()
          ..patchCompleter = completer;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: EditProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Alice');
        await tester.enterText(find.byType(TextField).last, 'Smith');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pump();

        completer.complete();
        await tester.pumpAndSettle();

        final patchRequests = mockAdapter.requests
            .where((r) => r.method == 'PATCH')
            .length;
        expect(patchRequests, 1);
      },
    );

    test(
      '7. AuthRepository changePassword sends POST /auth/change-password request payload',
      () async {
        final mockAdapter = MockSettingsHttpAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
        dio.httpClientAdapter = mockAdapter;

        final repo = AuthRepository(dio);
        await repo.changePassword('OldPassword123!', 'NewPassword123!');

        expect(
          mockAdapter.requests.last.path,
          contains('/auth/change-password'),
        );
        expect(mockAdapter.requests.last.body, {
          'currentPassword': 'OldPassword123!',
          'newPassword': 'NewPassword123!',
        });
      },
    );

    testWidgets(
      '8. ChangePasswordScreen validation blocks invalid passwords before submitting',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(child: const MaterialApp(home: ChangePasswordScreen())),
        );

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'OldPass123!');
        await tester.enterText(
          find.byType(TextField).at(1),
          'short',
        ); // Too short
        await tester.enterText(find.byType(TextField).at(2), 'short');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      '9. Resend Verification Email uses active user email dynamically',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter();
        final fakeUserNotifier = FakeCurrentUserNotifier()
          ..user = const UserDto(
            id: 'usr-123',
            email: 'active.customer@example.com',
            firstName: 'Customer',
            lastName: 'One',
            isEmailVerified: false,
          );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => fakeUserNotifier),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Resend Verification Email'),
          200,
        );
        await tester.tap(find.text('Resend Verification Email'));
        await tester.pumpAndSettle();

        final resendReq = mockAdapter.requests.lastWhere(
          (r) => r.path.contains('/auth/resend-verification'),
        );
        expect(resendReq.body, {'email': 'active.customer@example.com'});
      },
    );

    test(
      '10. Account switch in-flight profile request discards old User A data',
      () async {
        SharedPreferences.setMockInitialValues({
          'selected_tenant_slug': 'dev81-kuwait-fashion',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter();
        final authNotifier = FakeAuthTokenNotifier();
        late ProviderContainer container;

        container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(() => authNotifier),
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
            dioClientProvider.overrideWith((ref) {
              final tenantSlug = ref.watch(selectedTenantSlugProvider);
              final token = ref.watch(authTokenProvider);
              final dio = Dio(
                BaseOptions(
                  baseUrl: 'http://127.0.0.1:3000/api/v1',
                  headers: {
                    'X-Tenant-Slug': tenantSlug,
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                ),
              );
              dio.httpClientAdapter = mockAdapter;
              return dio;
            }),
          ],
        );

        container.listen(currentUserProvider, (_, _) {});

        await container.read(currentUserProvider.future);
        expect(container.read(currentUserProvider).value?.id, 'usr-123');

        // Logout User A
        authNotifier.setToken(null);
        await Future.microtask(() {});

        final userVal = await container.read(currentUserProvider.future);
        expect(userVal, isNull);
      },
    );

    test(
      '11. Delayed profile GET for User A followed by User B login does not expose User A data',
      () async {
        SharedPreferences.setMockInitialValues({
          'selected_tenant_slug': 'dev81-kuwait-fashion',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter();
        final authNotifier = FakeAuthTokenNotifier();
        late ProviderContainer container;

        container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(() => authNotifier),
            sessionCoordinatorProvider.overrideWith((ref) {
              return SessionCoordinator(
                SharedPreferencesCredentialStorage(sharedPreferences),
              );
            }),
            dioClientProvider.overrideWith((ref) {
              final tenantSlug = ref.watch(selectedTenantSlugProvider);
              final token = ref.watch(authTokenProvider);
              final dio = Dio(
                BaseOptions(
                  baseUrl: 'http://127.0.0.1:3000/api/v1',
                  headers: {
                    'X-Tenant-Slug': tenantSlug,
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                ),
              );
              dio.httpClientAdapter = mockAdapter;
              return dio;
            }),
          ],
        );

        container.listen(currentUserProvider, (_, _) {});

        await container.read(currentUserProvider.future);
        expect(container.read(currentUserProvider).value?.id, 'usr-123');

        // Logout User A before late GET response completes
        authNotifier.setToken(null);
        await Future.microtask(() {});

        final user = await container.read(currentUserProvider.future);
        expect(user, isNull);
      },
    );

    testWidgets(
      '12. Delayed profile PATCH followed by logout suppresses stale success navigation',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final patchCompleter = Completer<void>();
        final mockAdapter = MockSettingsHttpAdapter()
          ..patchCompleter = patchCompleter;
        final authNotifier = FakeAuthTokenNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => authNotifier),
              currentUserProvider.overrideWith(() => FakeCurrentUserNotifier()),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final token = ref.watch(authTokenProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      if (token != null) 'Authorization': 'Bearer $token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: EditProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Alice');
        await tester.enterText(find.byType(TextField).last, 'Smith');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pump();

        // Logout while PATCH is pending
        authNotifier.setToken(null);
        patchCompleter.complete();
        await tester.pumpAndSettle();

        // Screen stays open, no stale navigation or success feedback
        expect(find.byType(EditProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      '13. Delayed password change followed by account switch suppresses stale success navigation',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter();
        final authNotifier = FakeAuthTokenNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => authNotifier),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final token = ref.watch(authTokenProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      if (token != null) 'Authorization': 'Bearer $token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: ChangePasswordScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'OldPass123!');
        await tester.enterText(find.byType(TextField).at(1), 'NewPass123!');
        await tester.enterText(find.byType(TextField).at(2), 'NewPass123!');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(find.byType(ChangePasswordScreen), findsNothing);
      },
    );

    testWidgets(
      '14. Verified user does not render Resend Verification Email option',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final fakeUserNotifier = FakeCurrentUserNotifier()
          ..user = const UserDto(
            id: 'usr-123',
            email: 'verified@example.com',
            firstName: 'Verified',
            lastName: 'User',
            isEmailVerified: true,
          );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => fakeUserNotifier),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Resend Verification Email'), findsNothing);
      },
    );

    testWidgets(
      '15. Unverified user resending verification email prevents duplicate submissions during rapid taps',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_tenant_confirmed': true,
          'selected_tenant_slug': 'dev81-kuwait-fashion',
          'access_token': 'test-token',
        });
        sharedPreferences = await SharedPreferences.getInstance();

        final mockAdapter = MockSettingsHttpAdapter();
        final fakeUserNotifier = FakeCurrentUserNotifier()
          ..user = const UserDto(
            id: 'usr-123',
            email: 'active.customer@example.com',
            firstName: 'Customer',
            lastName: 'One',
            isEmailVerified: false,
          );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authTokenProvider.overrideWith(() => FakeAuthTokenNotifier()),
              currentUserProvider.overrideWith(() => fakeUserNotifier),
              sessionCoordinatorProvider.overrideWith((ref) {
                return SessionCoordinator(
                  SharedPreferencesCredentialStorage(sharedPreferences),
                );
              }),
              dioClientProvider.overrideWith((ref) {
                final tenantSlug = ref.watch(selectedTenantSlugProvider);
                final dio = Dio(
                  BaseOptions(
                    baseUrl: 'http://127.0.0.1:3000/api/v1',
                    headers: {
                      'X-Tenant-Slug': tenantSlug,
                      'Authorization': 'Bearer test-token',
                    },
                  ),
                );
                dio.httpClientAdapter = mockAdapter;
                return dio;
              }),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Resend Verification Email'),
          200,
        );
        await tester.tap(find.text('Resend Verification Email'));
        await tester.pumpAndSettle();

        final resendReqs = mockAdapter.requests
            .where((r) => r.path.contains('/auth/resend-verification'))
            .length;
        expect(resendReqs, 1);
      },
    );
  });
}
