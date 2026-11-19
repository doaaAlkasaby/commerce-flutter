import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';

void main() {
  group('AppPriceText Widget Tests', () {
    testWidgets('renders price and currency with distinct font sizes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppPriceTextRow(
              price: '145.75',
              currency: 'KWD',
              priceStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      final priceFinder = find.text('145.750');
      final currencyFinder = find.text('KWD');

      expect(priceFinder, findsOneWidget);
      expect(currencyFinder, findsOneWidget);

      final priceWidget = tester.widget<Text>(priceFinder);
      final currencyWidget = tester.widget<Text>(currencyFinder);

      expect(priceWidget.style?.fontSize, 20.0);
      expect(currencyWidget.style?.fontSize, 13.0);
    });

    testWidgets('correctly isolates currency for negative amounts', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppPriceTextRow(price: '-3.800', currency: 'KWD'),
          ),
        ),
      );

      final priceFinder = find.text('-3.800');
      final currencyFinder = find.text('KWD');

      expect(priceFinder, findsOneWidget);
      expect(currencyFinder, findsOneWidget);
    });
  });
}
