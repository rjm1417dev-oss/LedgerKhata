import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/widgets/buttons.dart';

import 'support/fake_repository.dart';
import 'support/test_setup.dart';

const _business = Business(
  name: 'Al-Noor Store',
  ownerName: 'Bilal Ahmed',
  phone: '0300 1122334',
);

Future<void> _openSettings(WidgetTester tester, FakeRepository repo) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ignoreFontMetricOverflows();

  await tester.pumpWidget(
    KhataApp(repository: repo, splashMinimum: Duration.zero),
  );
  await tester.pumpAndSettle();

  // Switch to Settings tab
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
}

Future<void> _openUpdatePassword(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Update'), 100);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Update'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Settings screen displays Security section with password card', (
    tester,
  ) async {
    final repo = FakeRepository(signedIn: true, business: _business);
    await _openSettings(tester, repo);

    await tester.scrollUntilVisible(find.text('SECURITY'), 100);
    await tester.pumpAndSettle();

    expect(find.text('SECURITY'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Change your account password'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets(
    'Update password sheet validates empty, short, and mismatched fields',
    (tester) async {
      final repo = FakeRepository(signedIn: true, business: _business);
      await _openSettings(tester, repo);
      await _openUpdatePassword(tester);

      // Sheet title
      expect(find.text('Update password'), findsWidgets);

      // Submit with empty fields
      await tester.tap(find.widgetWithText(PrimaryButton, 'Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your current password'), findsOneWidget);
      expect(find.text('Enter a new password'), findsOneWidget);
      expect(find.text('Confirm your new password'), findsOneWidget);

      // Enter short new password (< 6 chars)
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), '12345');
      await tester.enterText(fields.at(2), '12345');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Enter same password as current
      await tester.enterText(fields.at(1), 'secret123');
      await tester.enterText(fields.at(2), 'secret123');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Update password'));
      await tester.pumpAndSettle();

      expect(
        find.text('New password must be different from current password'),
        findsOneWidget,
      );

      // Mismatched confirm password
      await tester.enterText(fields.at(1), 'newsecret123');
      await tester.enterText(fields.at(2), 'different123');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    },
  );

  testWidgets('Wrong current password shows error toast', (tester) async {
    final repo = FakeRepository(signedIn: true, business: _business);
    await _openSettings(tester, repo);
    await _openUpdatePassword(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'wrong_current_pass');
    await tester.enterText(fields.at(1), 'newsecret123');
    await tester.enterText(fields.at(2), 'newsecret123');

    await tester.tap(find.widgetWithText(PrimaryButton, 'Update password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Current password is incorrect.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets(
    'Successfully updates password and allows signing in with new password',
    (tester) async {
      final repo = FakeRepository(signedIn: true, business: _business);
      await _openSettings(tester, repo);
      await _openUpdatePassword(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), 'newsecret123');
      await tester.enterText(fields.at(2), 'newsecret123');

      await tester.tap(find.widgetWithText(PrimaryButton, 'Update password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Password updated successfully'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      // Sheet dismissed
      expect(find.widgetWithText(PrimaryButton, 'Update password'), findsNothing);

      // Now scroll and sign out
      await tester.scrollUntilVisible(find.text('Sign out'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // We should be on sign in screen
      expect(find.text('Welcome back'), findsOneWidget);

      // Try signing in with old password -> should fail
      final authFields = find.byType(TextField);
      await tester.enterText(authFields.at(0), 'owner@example.com');
      await tester.enterText(authFields.at(1), 'secret123');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Wrong email or password.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      // Sign in with new password -> should succeed!
      await tester.enterText(authFields.at(1), 'newsecret123');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Total remaining'), findsOneWidget);
    },
  );
}
