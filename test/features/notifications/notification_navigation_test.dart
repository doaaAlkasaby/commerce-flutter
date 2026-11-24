import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/services/notification_navigation_handler.dart';
import 'package:ecommerce/features/orders/presentation/screens/order_details_screen.dart';
import 'package:ecommerce/main.dart';

class TestAuthNotifier extends AuthTokenNotifier {
  String? _t;
  TestAuthNotifier([this._t]);

  @override
  String? build() => _t;

  @override
  Future<void> setToken(String? token, {String? refreshToken}) async {
    _t = token;
    state = token;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    NotificationNavigationHandler.resetForTesting();
  });

  group('Phase NOTIF-4 — Notification Tap Navigation Unit & Widget Tests', () {
    test('1. Extract orderId from data payload variants', () {
      expect(
        NotificationNavigationHandler.extractOrderId({'orderId': 'ord-101'}),
        equals('ord-101'),
      );
      expect(
        NotificationNavigationHandler.extractOrderId({'order_id': 'ord-102'}),
        equals('ord-102'),
      );
      expect(
        NotificationNavigationHandler.extractOrderId({'order': 'ord-103'}),
        equals('ord-103'),
      );
      expect(
        NotificationNavigationHandler.extractOrderId({'title': 'Hello'}),
        isNull,
      );
    });

    testWidgets(
      '2. Authenticated user notification tap navigates to OrderDetailsScreen',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(
              () => TestAuthNotifier('valid-token-123'),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: rootNavigatorKey,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      NotificationNavigationHandler.processNotificationTap(
                        {
                          'notificationId': 'notif-auth-101',
                          'orderId': 'order-uuid-999',
                          'eventType': 'ORDER_PLACED',
                        },
                        authToken: 'valid-token-123',
                        context: context,
                      );
                    },
                    child: const Text('Simulate Tap'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Simulate Tap'));
        await tester.pumpAndSettle();

        expect(find.byType(OrderDetailsScreen), findsOneWidget);
      },
    );

    testWidgets(
      '3. Unauthenticated notification tap sets pendingOrderId and navigates after login',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(() => TestAuthNotifier(null)),
          ],
        );

        late BuildContext testContext;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: rootNavigatorKey,
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    testContext = context;
                    return ElevatedButton(
                      onPressed: () {
                        NotificationNavigationHandler.processNotificationTap(
                          {
                            'notificationId': 'notif-unauth-202',
                            'orderId': 'order-pending-777',
                            'eventType': 'ORDER_PLACED',
                          },
                          authToken: container.read(authTokenProvider),
                          context: context,
                        );
                      },
                      child: const Text('Unauth Tap'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Tap while unauthenticated
        await tester.tap(find.text('Unauth Tap'));
        await tester.pump();

        // Screen should NOT navigate yet, pendingOrderId stored
        expect(find.byType(OrderDetailsScreen), findsNothing);
        expect(
          NotificationNavigationHandler.pendingOrderId,
          equals('order-pending-777'),
        );

        // User logs in via container notifier
        await container
            .read(authTokenProvider.notifier)
            .setToken('new-user-token');
        await tester.pump();

        // Check and navigate pending
        NotificationNavigationHandler.checkAndNavigatePending(
          authToken: container.read(authTokenProvider),
          context: testContext,
        );
        await tester.pumpAndSettle();

        expect(find.byType(OrderDetailsScreen), findsOneWidget);
        expect(NotificationNavigationHandler.pendingOrderId, isNull);
      },
    );

    testWidgets(
      '4. Duplicate notification taps are deduplicated and navigate only once',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith(
              () => TestAuthNotifier('valid-token-123'),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: rootNavigatorKey,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      // First tap call
                      final res1 =
                          NotificationNavigationHandler.processNotificationTap(
                            {
                              'notificationId': 'notif-dup-555',
                              'orderId': 'order-dup-555',
                              'eventType': 'ORDER_PLACED',
                            },
                            authToken: 'valid-token-123',
                            context: context,
                          );
                      // Duplicate tap call
                      final res2 =
                          NotificationNavigationHandler.processNotificationTap(
                            {
                              'notificationId': 'notif-dup-555',
                              'orderId': 'order-dup-555',
                              'eventType': 'ORDER_PLACED',
                            },
                            authToken: 'valid-token-123',
                            context: context,
                          );

                      expect(res1, isTrue);
                      expect(res2, isFalse); // Deduplicated!
                    },
                    child: const Text('Duplicate Tap'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Duplicate Tap'));
        await tester.pumpAndSettle();

        expect(find.byType(OrderDetailsScreen), findsOneWidget);
      },
    );
  });
}
