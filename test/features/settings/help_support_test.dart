import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/network/session_coordinator.dart';
import 'package:ecommerce/features/settings/models/help_support_model.dart';
import 'package:ecommerce/features/settings/presentation/providers/help_support_provider.dart';
import 'package:ecommerce/features/settings/presentation/screens/help_support_screen.dart';
import 'package:ecommerce/features/settings/presentation/screens/settings_screen.dart';
import 'package:ecommerce/features/settings/utils/support_launcher.dart';

class MockHelpSupportHttpAdapter implements HttpClientAdapter {
  final List<String> requests = [];
  final List<String> requestedSlugs = [];
  bool emptySettings = false;
  bool shouldFail = false;
  Completer<void>? tenantBCompleter;
  Completer<void>? tenantBStartedSignal;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.path);

    final tenantSlug = options.headers['X-Tenant-Slug'] as String?;
    if (tenantSlug != null) {
      requestedSlugs.add(tenantSlug);
    }

    if (tenantSlug == 'dev81-independent') {
      if (tenantBStartedSignal != null && !tenantBStartedSignal!.isCompleted) {
        tenantBStartedSignal!.complete();
      }
      if (tenantBCompleter != null) {
        await tenantBCompleter!.future;
      }
    }

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Server Error'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (emptySettings) {
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final email = tenantSlug == 'dev81-independent'
        ? 'support@noura.com'
        : 'support@luma.com';

    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': [
          {'key': 'support_email', 'value': email, 'isPublic': true},
          {'key': 'support_phone', 'value': '+96521212121', 'isPublic': true},
          {'key': 'whatsapp', 'value': '96521212121', 'isPublic': true},
          {
            'key': 'business_hours',
            'value': 'Sat-Thu: 9AM - 10PM',
            'isPublic': true,
          },
          {
            'key': 'shipping_policy',
            'value': 'Standard delivery takes 1-2 days.',
            'isPublic': true,
          },
          {
            'key': 'return_policy',
            'value': 'Returns accepted within 14 days.',
            'isPublic': true,
          },
          {
            'key': 'privacy_policy_url',
            'value': 'https://luma.com/privacy',
            'isPublic': true,
          },
          {
            'key': 'faq',
            'value': [
              {
                'question': 'How can I track my order?',
                'answer': 'Go to My Orders screen to track order status.',
              },
            ],
            'isPublic': true,
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'is_tenant_confirmed': true,
      'selected_tenant_slug': 'dev81-kuwait-fashion',
      'access_token': 'test-token',
    });
    sharedPreferences = await SharedPreferences.getInstance();
  });

  group('Help & Support Unit & Integration Tests', () {
    test(
      '1. HelpSupportModel parses contact, FAQ, and policy settings correctly',
      () {
        final model = HelpSupportModel.fromSettingsData([
          {'key': 'support_email', 'value': 'support@luma.com'},
          {'key': 'support_phone', 'value': '+96521212121'},
          {'key': 'whatsapp', 'value': '96521212121'},
          {'key': 'business_hours', 'value': '9AM - 10PM'},
          {'key': 'shipping_policy', 'value': 'Fast local delivery'},
          {
            'key': 'faq',
            'value': [
              {
                'question': 'What is return policy?',
                'answer': 'Returns accepted within 14 days.',
              },
            ],
          },
        ]);

        expect(model.email, 'support@luma.com');
        expect(model.phone, '+96521212121');
        expect(model.whatsapp, '96521212121');
        expect(model.businessHours, '9AM - 10PM');
        expect(model.shippingPolicy, 'Fast local delivery');
        expect(model.faqs.length, 1);
        expect(model.faqs.first.question, 'What is return policy?');
        expect(model.isEmpty, false);
      },
    );

    test(
      '2. HelpSupportModel handles empty or missing settings gracefully',
      () {
        final model = HelpSupportModel.fromSettingsData([]);
        expect(model.isEmpty, true);
        expect(model.hasContactInfo, false);
        expect(model.hasFaqs, false);
        expect(model.hasPolicies, false);
      },
    );

    test(
      '3. SupportLauncher strictly validates inputs and rejects malformed or insecure URLs',
      () async {
        expect(await SupportLauncher.launchEmail(''), false);
        expect(await SupportLauncher.launchEmail('user@com'), false);
        expect(await SupportLauncher.launchPhone(''), false);
        expect(await SupportLauncher.launchPhone('abc-xyz'), false);
        expect(await SupportLauncher.launchWhatsApp(''), false);
        expect(await SupportLauncher.launchWhatsApp('abc'), false);
        expect(await SupportLauncher.launchWebUrl('not-a-url'), false);
        expect(
          await SupportLauncher.launchWebUrl('http://insecure.com'),
          false,
        );
        expect(SupportLauncher.isHttpsUrl('http://insecure.com'), false);
        expect(SupportLauncher.isHttpsUrl('https://luma.com/privacy'), true);
      },
    );

    testWidgets(
      '4. HelpSupportScreen renders tenant support contact channels, FAQs, and policies',
      (tester) async {
        final mockAdapter = MockHelpSupportHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
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
            child: const MaterialApp(home: HelpSupportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Help & Support'), findsOneWidget);
        expect(find.text('Contact Us'), findsOneWidget);
        expect(find.text('support@luma.com'), findsOneWidget);
        expect(find.text('+96521212121'), findsOneWidget);
        expect(find.text('Frequently Asked Questions'), findsOneWidget);
        expect(find.text('How can I track my order?'), findsOneWidget);
      },
    );

    testWidgets(
      '5. HelpSupportScreen renders empty state when tenant has no support settings',
      (tester) async {
        final mockAdapter = MockHelpSupportHttpAdapter()..emptySettings = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
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
            child: const MaterialApp(home: HelpSupportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text(
            'No support information is available for this store currently.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('6. SettingsScreen support item opens HelpSupportScreen', (
      tester,
    ) async {
      final mockAdapter = MockHelpSupportHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      final supportTile = find.text('Support');
      expect(supportTile, findsOneWidget);
      await tester.tap(supportTile);
      await tester.pumpAndSettle();

      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });

    test(
      '7. Tenant switch invalidates support data without stale tenant data leakage',
      () async {
        final mockAdapter = MockHelpSupportHttpAdapter();

        final container = ProviderContainer(
          overrides: [
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
        );

        container.listen(helpSupportProvider, (_, _) {});

        final model1 = await container.read(helpSupportProvider.future);
        expect(model1.email, 'support@luma.com');

        // Tenant switch to Noura
        await container
            .read(selectedTenantSlugProvider.notifier)
            .setTenantSlug('dev81-independent');
        final model2 = await container.read(helpSupportProvider.future);

        expect(model2.email, 'support@noura.com');
      },
    );

    testWidgets(
      '8. Plain-text shipping policy tile opens modal detail bottom sheet',
      (tester) async {
        final mockAdapter = MockHelpSupportHttpAdapter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
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
            child: const MaterialApp(home: HelpSupportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll down to reveal Store Policies section
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        final policyTile = find.text('Shipping Policy');
        expect(policyTile, findsOneWidget);
        await tester.tap(policyTile);
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Standard delivery takes 1-2 days.'), findsWidgets);
      },
    );

    test(
      '9. Tenant switch with delayed API response out-of-order resolution retains latest tenant support data',
      () async {
        final completerB = Completer<void>();
        final startedB = Completer<void>();
        final mockAdapter = MockHelpSupportHttpAdapter()
          ..tenantBCompleter = completerB
          ..tenantBStartedSignal = startedB;

        final container = ProviderContainer(
          overrides: [
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
        );

        container.listen(helpSupportProvider, (_, _) {});

        // Step 1: Fetch for tenant Luma (A)
        final modelA = await container.read(helpSupportProvider.future);
        expect(modelA.email, 'support@luma.com');

        // Step 2: Switch to Noura (B) with delayed response
        final setSlugBFuture = container
            .read(selectedTenantSlugProvider.notifier)
            .setTenantSlug('dev81-independent');

        // Step 3 & 6: Verify request B was actually started and is blocked
        await startedB.future;
        expect(mockAdapter.requestedSlugs.contains('dev81-independent'), true);

        // Step 7 & 8: Immediately switch back to Luma (A)
        await container
            .read(selectedTenantSlugProvider.notifier)
            .setTenantSlug('dev81-kuwait-fashion');

        final modelA2 = await container.read(helpSupportProvider.future);
        expect(modelA2.email, 'support@luma.com');

        // Step 9: Release delayed B response
        completerB.complete();
        await setSlugBFuture;

        // Step 10: Assert Tenant A data remains active and not overwritten
        expect(
          container.read(helpSupportProvider).value?.email,
          'support@luma.com',
        );
      },
    );

    testWidgets(
      '13. Widget-level test: HelpSupportScreen never displays Tenant B contact info when switching to B (delayed) and back to A',
      (tester) async {
        final completerB = Completer<void>();
        final startedB = Completer<void>();
        final mockAdapter = MockHelpSupportHttpAdapter()
          ..tenantBCompleter = completerB
          ..tenantBStartedSignal = startedB;

        late ProviderContainer container;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container = ProviderContainer(
              overrides: [
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
            ),
            child: const MaterialApp(home: HelpSupportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Step 1: Verify Tenant A contact info is displayed
        expect(find.text('support@luma.com'), findsOneWidget);
        expect(find.text('support@noura.com'), findsNothing);

        // Step 2: Switch to Tenant B (delayed) on same mounted container
        final setSlugBFuture = container
            .read(selectedTenantSlugProvider.notifier)
            .setTenantSlug('dev81-independent');

        await tester.pump();

        // Step 3: Verify Tenant B HTTP request started and is blocked
        await startedB.future;
        expect(mockAdapter.requestedSlugs.contains('dev81-independent'), true);

        // Step 4: Switch back to Tenant A without recreating widget or scope
        await container
            .read(selectedTenantSlugProvider.notifier)
            .setTenantSlug('dev81-kuwait-fashion');

        await tester.pump();

        // Step 5: Release delayed B response
        completerB.complete();
        await setSlugBFuture;
        await tester.pumpAndSettle();

        // Step 6: Tenant B contact info is never displayed
        expect(find.text('support@luma.com'), findsOneWidget);
        expect(find.text('support@noura.com'), findsNothing);
      },
    );
  });
}
