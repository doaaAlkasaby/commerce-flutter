import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/categories/presentation/providers/categories_provider.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/providers/home_provider.dart';
import 'package:ecommerce/features/main_shell_screen.dart';
import 'package:ecommerce/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:ecommerce/features/orders/presentation/providers/orders_provider.dart';
import 'package:ecommerce/features/settings/presentation/screens/settings_screen.dart';
import 'package:ecommerce/features/special_orders/presentation/providers/special_orders_availability_provider.dart';
import 'package:ecommerce/features/special_orders/presentation/screens/special_orders_list_screen.dart';
import 'package:ecommerce/features/special_orders/presentation/widgets/special_orders_banner.dart';
import 'package:ecommerce/features/storefront/models/storefront_model.dart';
import 'package:ecommerce/features/storefront/presentation/providers/storefront_provider.dart';
import 'package:ecommerce/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  group('1. Special Orders Availability Tests', () {
    test('Default availability evaluates storefront settings (disabled by default)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isAvailable = container.read(specialOrdersAvailabilityProvider);
      expect(isAvailable, isFalse);
    });

    test('Notifier setEnabled dynamically updates availability state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(specialOrdersAvailabilityProvider), isFalse);

      container.read(specialOrdersAvailabilityProvider.notifier).setEnabled(true);
      expect(container.read(specialOrdersAvailabilityProvider), isTrue);

      container.read(specialOrdersAvailabilityProvider.notifier).setEnabled(false);
      expect(container.read(specialOrdersAvailabilityProvider), isFalse);
    });
  });

  group('2. SpecialOrdersBanner Widget Tests', () {
    testWidgets('Returns SizedBox.shrink when preview is disabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _DisabledSpecialOrdersAvailability(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SpecialOrdersBanner(
                bannerContext: SpecialOrdersBannerContext.home,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SpecialOrdersBanner), findsOneWidget);
      expect(find.text('Can\'t find a product?'), findsNothing);
    });

    testWidgets('Renders correct English title and description when enabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _EnabledSpecialOrdersAvailability(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Material(
                child: SpecialOrdersBanner(
                  bannerContext: SpecialOrdersBannerContext.home,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Can\'t find a product?'), findsOneWidget);
      expect(find.text('Request it directly from the store.'), findsOneWidget);
    });

    testWidgets('Tapping SpecialOrdersBanner sets navigation index to MainShellDestination.specialOrders', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
          specialOrdersAvailabilityProvider.overrideWith(
            () => _EnabledSpecialOrdersAvailability(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(navigationIndexProvider, (_, __) {});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Material(
                child: SpecialOrdersBanner(
                  bannerContext: SpecialOrdersBannerContext.home,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(container.read(navigationIndexProvider), MainShellDestination.home);

      await tester.tap(find.text('Can\'t find a product?'));
      await tester.pumpAndSettle();

      expect(container.read(navigationIndexProvider), MainShellDestination.specialOrders);
    });
  });

  group('3. MainShellScreen Bottom Navigation Tests', () {
    testWidgets('Renders 4 navigation items and no Settings tab when disabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _DisabledSpecialOrdersAvailability(),
            ),
            storefrontProvider.overrideWith((ref) async => _mockStorefrontModel()),
            homeDataProvider.overrideWith((ref) async => _mockHomeResponse()),
            cartProvider.overrideWith(() => _MockEmptyCartNotifier()),
            myOrdersControllerProvider.overrideWith(() => _MockEmptyOrdersNotifier()),
            mainCategoriesProvider.overrideWith((ref) async => []),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
          ],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      final BottomNavigationBar navBar = tester.widget(navBarFinder);
      expect(navBar.items.length, 4);

      expect(find.text('Settings'), findsNothing);
      expect(find.text('Special Orders'), findsNothing);
    });

    testWidgets('Renders 5 navigation items including Special Orders when enabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _EnabledSpecialOrdersAvailability(),
            ),
            storefrontProvider.overrideWith((ref) async => _mockStorefrontModel()),
            homeDataProvider.overrideWith((ref) async => _mockHomeResponse()),
            cartProvider.overrideWith(() => _MockEmptyCartNotifier()),
            myOrdersControllerProvider.overrideWith(() => _MockEmptyOrdersNotifier()),
            mainCategoriesProvider.overrideWith((ref) async => []),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
          ],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      final BottomNavigationBar navBar = tester.widget(navBarFinder);
      expect(navBar.items.length, 5);

      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('Tapping 5th tab displays SpecialOrdersListScreen foundation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            authTokenProvider.overrideWith(() => _MockAuthTokenNotifier()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _EnabledSpecialOrdersAvailability(),
            ),
            storefrontProvider.overrideWith((ref) async => _mockStorefrontModel()),
            homeDataProvider.overrideWith((ref) async => _mockHomeResponse()),
            cartProvider.overrideWith(() => _MockEmptyCartNotifier()),
            myOrdersControllerProvider.overrideWith(() => _MockEmptyOrdersNotifier()),
            mainCategoriesProvider.overrideWith((ref) async => []),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
          ],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 5th tab of BottomNavigationBar
      final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      navBar.onTap!(MainShellDestination.specialOrders);
      await tester.pumpAndSettle();

      expect(find.byType(SpecialOrdersListScreen), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
    });

    testWidgets('Disabling availability while on Special Orders tab safely returns index to Home', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
          specialOrdersAvailabilityProvider.overrideWith(
            () => _EnabledSpecialOrdersAvailability(),
          ),
          storefrontProvider.overrideWith((ref) async => _mockStorefrontModel()),
          homeDataProvider.overrideWith((ref) async => _mockHomeResponse()),
          cartProvider.overrideWith(() => _MockEmptyCartNotifier()),
          myOrdersControllerProvider.overrideWith(() => _MockEmptyOrdersNotifier()),
          mainCategoriesProvider.overrideWith((ref) async => []),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to tab 4
      container.read(navigationIndexProvider.notifier).setIndex(MainShellDestination.specialOrders);
      await tester.pumpAndSettle();

      expect(container.read(navigationIndexProvider), MainShellDestination.specialOrders);

      // Disable availability
      container.read(specialOrdersAvailabilityProvider.notifier).setEnabled(false);
      await tester.pumpAndSettle();

      // Verify clamped index returns to Home (0)
      expect(container.read(navigationIndexProvider), MainShellDestination.home);
    });
  });

  group('4. Settings Relocation & Navigation Tests', () {
    testWidgets('Home Header shows Settings icon button which opens SettingsScreen with BackButton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _EnabledSpecialOrdersAvailability(),
            ),
            storefrontProvider.overrideWith((ref) async => _mockStorefrontModel()),
            homeDataProvider.overrideWith((ref) async => _mockHomeResponse()),
            cartProvider.overrideWith(() => _MockEmptyCartNotifier()),
            myOrdersControllerProvider.overrideWith(() => _MockEmptyOrdersNotifier()),
            mainCategoriesProvider.overrideWith((ref) async => []),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
          ],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find Settings icon button in header
      final settingsIconFinder = find.byTooltip('Settings');
      expect(settingsIconFinder, findsOneWidget);

      // Tap Settings icon button
      await tester.tap(settingsIconFinder);
      await tester.pumpAndSettle();

      // Verify SettingsScreen is pushed
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      // Tap BackButton to return to Home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(MainShellScreen), findsOneWidget);
    });
  });
}

class _MockLocalizationLoader extends AppLocalizationLoader {
  @override
  Future<Map<String, String>> build() async => const <String, String>{};
}

class _MockAuthTokenNotifier extends AuthTokenNotifier {
  @override
  String? build() => 'test-token';
}

class _DisabledSpecialOrdersAvailability extends SpecialOrdersAvailability {
  @override
  bool build() => false;
}

class _EnabledSpecialOrdersAvailability extends SpecialOrdersAvailability {
  @override
  bool build() => true;
}

class _MockEmptyCartNotifier extends CartNotifier {
  @override
  Future<CartModel> build() async => const CartModel.empty();
}

class _MockEmptyOrdersNotifier extends MyOrdersController {
  @override
  Future<PaginatedOrdersState> build() async {
    return const PaginatedOrdersState(items: [], page: 1, totalPages: 1);
  }
}

StorefrontModel _mockStorefrontModel() {
  return const StorefrontModel(
    id: 'st-1',
    slug: 'test-store',
    name: 'Test Store',
    currency: 'KWD',
    settings: {},
  );
}

HomeResponseModel _mockHomeResponse() {
  return const HomeResponseModel(
    success: true,
    data: HomeDataModel(
      platform: 'mobile',
      banners: [],
      categories: [],
      sections: [],
      brands: [],
    ),
  );
}
