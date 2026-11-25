import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/models/auth_response_models.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/special_orders/data/special_orders_repository.dart';
import 'package:ecommerce/features/special_orders/models/confirmed_special_order_model.dart';
import 'package:ecommerce/features/special_orders/models/special_order_request_model.dart';
import 'package:ecommerce/features/special_orders/models/special_orders_pagination_model.dart';
import 'package:ecommerce/features/special_orders/presentation/providers/special_orders_availability_provider.dart';
import 'package:ecommerce/features/special_orders/presentation/providers/special_orders_provider.dart';
import 'package:ecommerce/features/special_orders/presentation/screens/special_order_request_detail_screen.dart';
import 'package:ecommerce/features/special_orders/presentation/screens/special_orders_list_screen.dart';
import 'package:ecommerce/features/storefront/models/storefront_model.dart';
import 'package:ecommerce/features/storefront/presentation/providers/storefront_provider.dart';
import 'package:ecommerce/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  group('1. Storefront Special Orders Settings & Availability Tests', () {
    test('SpecialOrderSettingsModel parses enabled, instructionsAr, and instructionsEn', () {
      final json = {
        'enabled': true,
        'instructionsAr': 'يرجى كتابة اسم المنتج بدقة',
        'instructionsEn': 'Please enter exact product name',
      };
      final model = SpecialOrderSettingsModel.fromJson(json);

      expect(model.enabled, isTrue);
      expect(model.instructionsAr, 'يرجى كتابة اسم المنتج بدقة');
      expect(model.instructionsEn, 'Please enter exact product name');
    });

    test('StorefrontModel returns specialOrders settings model', () {
      final storefrontJson = {
        'id': 'st-1',
        'slug': 'kuwait-store',
        'name': 'Kuwait Store',
        'currency': 'KWD',
        'settings': {
          'specialOrders': {
            'enabled': true,
            'instructionsEn': 'Special order guidelines',
          },
        },
      };
      final storefront = StorefrontModel.fromJson(storefrontJson);

      expect(storefront.specialOrders.enabled, isTrue);
      expect(storefront.specialOrders.instructionsEn, 'Special order guidelines');
    });

    test('SpecialOrdersAvailability provider evaluates storefront settings', () async {
      final container = ProviderContainer(
        overrides: [
          storefrontProvider.overrideWith(
            (ref) => const StorefrontModel(
              id: 'st-1',
              slug: 'test-slug',
              name: 'Test Store',
              currency: 'KWD',
              settings: {
                'specialOrders': {'enabled': true},
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(storefrontProvider.future);
      final isAvailable = container.read(specialOrdersAvailabilityProvider);
      expect(isAvailable, isTrue);
    });

    test('SpecialOrdersAvailability provider defaults to false when storefront is disabled', () async {
      final container = ProviderContainer(
        overrides: [
          storefrontProvider.overrideWith(
            (ref) => const StorefrontModel(
              id: 'st-1',
              slug: 'test-slug',
              name: 'Test Store',
              currency: 'KWD',
              settings: {
                'specialOrders': {'enabled': false},
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(storefrontProvider.future);
      final isAvailable = container.read(specialOrdersAvailabilityProvider);
      expect(isAvailable, isFalse);
    });
  });

  group('2. Special Orders Typed Models Tests', () {
    test('SpecialOrderRequestModel parses JSON with requested items and attachments', () {
      final requestJson = {
        'id': 'req-101',
        'requestNumber': 'REQ-1001',
        'status': 'QUOTED',
        'contactPhone': '+96590001122',
        'notes': 'Urgent request for medicine',
        'createdAt': '2026-11-25T10:00:00Z',
        'items': [
          {
            'id': 'item-1',
            'name': 'Panadol Extra',
            'quantity': 3,
            'specifications': '500mg 24 Tablets',
          },
        ],
        'attachments': [
          {
            'id': 'att-1',
            'fileKey': 'rx/prescription.pdf',
            'fileName': 'prescription.pdf',
            'mimeType': 'application/pdf',
            'fileSize': 102400,
            'isPrescription': true,
          },
        ],
      };

      final request = SpecialOrderRequestModel.fromJson(requestJson);

      expect(request.id, 'req-101');
      expect(request.requestNumber, 'REQ-1001');
      expect(request.status, 'QUOTED');
      expect(request.totalRequestedQuantity, 3);
      expect(request.items.length, 1);
      expect(request.items.first.name, 'Panadol Extra');
      expect(request.attachments.length, 1);
      expect(request.attachments.first.isPrescription, isTrue);
    });

    test('ConfirmedSpecialOrderModel parses monetary fields and currency string', () {
      final orderJson = {
        'id': 'so-501',
        'orderNumber': 'SO-1001',
        'requestId': 'req-101',
        'status': 'PROCESSING',
        'paymentStatus': 'PAID',
        'fulfillmentStatus': 'NOT_FULFILLED',
        'currency': 'KWD',
        'subtotal': '15.500',
        'shippingFee': '2.000',
        'taxAmount': '0.000',
        'totalAmount': '17.500',
        'createdAt': '2026-11-25T12:00:00Z',
      };

      final order = ConfirmedSpecialOrderModel.fromJson(orderJson);

      expect(order.id, 'so-501');
      expect(order.orderNumber, 'SO-1001');
      expect(order.currency, 'KWD');
      expect(order.subtotal, '15.500');
      expect(order.shippingFee, '2.000');
      expect(order.totalAmount, '17.500');
      expect(order.paymentStatus, 'PAID');
    });
  });

  group('3. Special Orders Screen Foundation & Historical Access Tests', () {
    testWidgets('SpecialOrdersListScreen renders Requests and Confirmed Orders tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            authTokenProvider.overrideWith(() => _MockAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => _MockCurrentUserNotifier()),
            storefrontProvider.overrideWith((ref) => _mockEnabledStorefront()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _EnabledSpecialOrdersAvailability(),
            ),
            specialOrdersRepositoryProvider.overrideWithValue(_MockSpecialOrdersRepository()),
          ],
          child: const MaterialApp(
            home: SpecialOrdersListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Confirmed Orders'), findsOneWidget);
      expect(find.text('Request # REQ-1001'), findsOneWidget);
    });

    testWidgets('Submissions disabled notice displays when submission is disabled but history remains accessible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            authTokenProvider.overrideWith(() => _MockAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => _MockCurrentUserNotifier()),
            storefrontProvider.overrideWith((ref) => _mockDisabledStorefront()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _DisabledSpecialOrdersAvailability(),
            ),
            specialOrdersRepositoryProvider.overrideWithValue(_MockSpecialOrdersRepository()),
          ],
          child: const MaterialApp(
            home: SpecialOrdersListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Notice should be displayed
      expect(
        find.text(
          'New product submissions are currently disabled by the store. You can still view your previous orders below.',
        ),
        findsOneWidget,
      );

      // Historical request REQ-1001 should still be accessible!
      expect(find.text('Request # REQ-1001'), findsOneWidget);
    });

    testWidgets('Tapping request row navigates to SpecialOrderRequestDetailScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            authTokenProvider.overrideWith(() => _MockAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => _MockCurrentUserNotifier()),
            storefrontProvider.overrideWith((ref) => _mockEnabledStorefront()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _EnabledSpecialOrdersAvailability(),
            ),
            specialOrdersRepositoryProvider.overrideWithValue(_MockSpecialOrdersRepository()),
          ],
          child: const MaterialApp(
            home: SpecialOrdersListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on REQ-1001 item
      await tester.tap(find.text('Request # REQ-1001'));
      await tester.pumpAndSettle();

      expect(find.byType(SpecialOrderRequestDetailScreen), findsOneWidget);
      expect(find.text('Panadol Extra'), findsOneWidget);
    });

    testWidgets('Tapping confirmed order tab displays confirmed orders list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationLoaderProvider.overrideWith(() => _MockLocalizationLoader()),
            authTokenProvider.overrideWith(() => _MockAuthTokenNotifier()),
            currentUserProvider.overrideWith(() => _MockCurrentUserNotifier()),
            storefrontProvider.overrideWith((ref) => _mockEnabledStorefront()),
            specialOrdersAvailabilityProvider.overrideWith(
              () => _EnabledSpecialOrdersAvailability(),
            ),
            specialOrdersRepositoryProvider.overrideWithValue(_MockSpecialOrdersRepository()),
          ],
          child: const MaterialApp(
            home: SpecialOrdersListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Confirmed Orders tab
      await tester.tap(find.text('Confirmed Orders'));
      await tester.pumpAndSettle();

      expect(find.text('Order #SO-1001'), findsOneWidget);
    });
  });
}

class _MockLocalizationLoader extends AppLocalizationLoader {
  @override
  Future<Map<String, String>> build() async => const <String, String>{};
}

class _DisabledSpecialOrdersAvailability extends SpecialOrdersAvailability {
  @override
  bool build() => false;
}

class _EnabledSpecialOrdersAvailability extends SpecialOrdersAvailability {
  @override
  bool build() => true;
}

class _MockAuthTokenNotifier extends AuthTokenNotifier {
  @override
  String? build() => 'valid-jwt-token';
}

class _MockCurrentUserNotifier extends CurrentUser {
  @override
  Future<UserDto?> build() async {
    return const UserDto(
      id: 'usr-101',
      email: 'customer@example.com',
      firstName: 'Test',
      lastName: 'Customer',
      isEmailVerified: true,
    );
  }
}

StorefrontModel _mockEnabledStorefront() {
  return const StorefrontModel(
    id: 'st-1',
    slug: 'test-slug',
    name: 'Test Store',
    currency: 'KWD',
    settings: {
      'specialOrders': {'enabled': true},
    },
  );
}

StorefrontModel _mockDisabledStorefront() {
  return const StorefrontModel(
    id: 'st-1',
    slug: 'test-slug',
    name: 'Test Store',
    currency: 'KWD',
    settings: {
      'specialOrders': {'enabled': false},
    },
  );
}

class _MockSpecialOrdersRepository implements SpecialOrdersRepository {
  @override
  Future<PaginatedSpecialOrdersModel<SpecialOrderRequestModel>> getMyRequests({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return const PaginatedSpecialOrdersModel<SpecialOrderRequestModel>(
      items: [
        SpecialOrderRequestModel(
          id: 'req-101',
          requestNumber: 'REQ-1001',
          status: 'QUOTED',
          createdAt: '2026-11-25 10:00',
          items: [
            SpecialRequestedItemModel(
              id: 'item-1',
              name: 'Panadol Extra',
              quantity: 3,
              specifications: '500mg',
            ),
          ],
        ),
      ],
      pagination: SpecialOrdersPaginationModel(
        page: 1,
        limit: 20,
        totalItems: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<SpecialOrderRequestModel?> getRequestById(String id) async {
    return const SpecialOrderRequestModel(
      id: 'req-101',
      requestNumber: 'REQ-1001',
      status: 'QUOTED',
      createdAt: '2026-11-25 10:00',
      items: [
        SpecialRequestedItemModel(
          id: 'item-1',
          name: 'Panadol Extra',
          quantity: 3,
          specifications: '500mg',
        ),
      ],
    );
  }

  @override
  Future<PaginatedSpecialOrdersModel<ConfirmedSpecialOrderModel>> getMyConfirmedOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return const PaginatedSpecialOrdersModel<ConfirmedSpecialOrderModel>(
      items: [
        ConfirmedSpecialOrderModel(
          id: 'so-501',
          orderNumber: 'SO-1001',
          requestId: 'req-101',
          status: 'PROCESSING',
          paymentStatus: 'PAID',
          fulfillmentStatus: 'NOT_FULFILLED',
          currency: 'KWD',
          subtotal: '15.500',
          shippingFee: '2.000',
          taxAmount: '0.000',
          totalAmount: '17.500',
          createdAt: '2026-11-25 12:00',
        ),
      ],
      pagination: SpecialOrdersPaginationModel(
        page: 1,
        limit: 20,
        totalItems: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<ConfirmedSpecialOrderModel?> getConfirmedOrderById(String id) async {
    return const ConfirmedSpecialOrderModel(
      id: 'so-501',
      orderNumber: 'SO-1001',
      requestId: 'req-101',
      status: 'PROCESSING',
      paymentStatus: 'PAID',
      fulfillmentStatus: 'NOT_FULFILLED',
      currency: 'KWD',
      subtotal: '15.500',
      shippingFee: '2.000',
      taxAmount: '0.000',
      totalAmount: '17.500',
      createdAt: '2026-11-25 12:00',
    );
  }

  @override
  Future<ConfirmedSpecialOrderModel?> getConfirmedOrderForRequest(String requestId) async {
    return getConfirmedOrderById('so-501');
  }
}
