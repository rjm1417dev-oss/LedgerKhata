import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/screens/splash_screen.dart';

import 'support/test_setup.dart';

void main() {
  testWidgets('SplashScreen renders branding elements and default loading text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ignoreFontMetricOverflows();

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial pump
    await tester.pump();

    expect(find.text('Khata'), findsOneWidget);
    expect(find.text('Khata Management'), findsOneWidget);
    expect(find.text('Loading\u2026'), findsOneWidget);

    // Advance frame for entrance animation
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Khata'), findsOneWidget);

    // Advance frame for full entrance completion
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Loading\u2026'), findsOneWidget);
  });

  testWidgets('SplashScreen displays custom message when provided', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ignoreFontMetricOverflows();

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(message: 'Restoring ledger data...'),
      ),
    );

    await tester.pump();
    expect(find.text('Restoring ledger data...'), findsOneWidget);
  });
}
