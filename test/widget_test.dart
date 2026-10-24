import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ecommerce/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EcommerceApp(),
      ),
    );

    // Wait for async repository data to load
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app loads successfully.
    expect(find.text('Hello, Guest!'), findsOneWidget);
  });
}
