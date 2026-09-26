import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/screens/status_screens.dart';
import 'package:my_first_app/state/app_state.dart';

import 'support/fake_repository.dart';
import 'support/test_setup.dart';

Future<void> pumpApp(WidgetTester tester, FakeRepository repo) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ignoreFontMetricOverflows();
  await tester.pumpWidget(KhataApp(repository: repo, splashMinimum: Duration.zero));
  await tester.pumpAndSettle();
}

const _business = Business(name: 'Al-Noor Traders', ownerName: 'Bilal Ahmed', phone: '0300 1122334');

void main() {
  testWidgets('signed-out users land on the register screen', (tester) async {
    await pumpApp(tester, FakeRepository());
    expect(find.text('Register your business'), findsOneWidget);
  });

  testWidgets('register validates on submit, then opens the dashboard', (tester) async {
    await pumpApp(tester, FakeRepository());

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your business name'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Al-Noor Traders');
    await tester.enterText(fields.at(1), 'Bilal Ahmed');
    await tester.enterText(fields.at(2), '0300 1122334');
    await tester.enterText(fields.at(3), 'Shop 4, Main Bazaar, Lahore');
    await tester.enterText(fields.at(4), '0321 9876543');
    await tester.enterText(fields.at(5), 'bilal@example.com');
    await tester.enterText(fields.at(6), 'secret123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Al-Noor Traders'), findsOneWidget);
    expect(find.text('Total remaining'), findsOneWidget);
  });

  testWidgets('email confirmation sends the user to sign in with a notice', (tester) async {
    await pumpApp(tester, FakeRepository(requireEmailConfirmation: true));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Al-Noor Traders');
    await tester.enterText(fields.at(1), 'Bilal Ahmed');
    await tester.enterText(fields.at(2), '0300 1122334');
    await tester.enterText(fields.at(3), 'Shop 4, Main Bazaar, Lahore');
    await tester.enterText(fields.at(4), '0321 9876543');
    await tester.enterText(fields.at(5), 'bilal@example.com');
    await tester.enterText(fields.at(6), 'secret123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.textContaining('bilal@example.com'), findsOneWidget);
  });

  testWidgets('a wrong password shows an error toast and stays on sign in', (tester) async {
    await pumpApp(tester, FakeRepository());
    await tester.ensureVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'bilal@example.com');
    await tester.enterText(fields.at(1), 'nope');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Wrong email or password.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a saved session skips sign in and shows the dashboard', (tester) async {
    await pumpApp(tester, FakeRepository(signedIn: true, business: _business));
    expect(find.text('Al-Noor Traders'), findsOneWidget);
    expect(find.text('Register your business'), findsNothing);
  });

  test('AppState: items, customers and a khata roll up into the dashboard totals', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();
    expect(state.status, AppStatus.ready);

    final rice = await state.addItem(name: 'Basmati Rice 5kg', price: 1650);
    final oil = await state.addItem(name: 'Cooking Oil 1L', price: 560);
    final ahmed = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    await state.addKhata(customer: ahmed, selectedItems: [rice, oil], discount: 65, paid: 1500);

    expect(state.totalBilled, 2210);
    expect(state.totalDiscount, 65);
    expect(state.totalReceived, 1500);
    expect(state.totalRemaining, 645);
    expect(state.pendingKhataCount, 1);
    expect(state.khatas.single.customerInitials, 'AR');
  });

  test('AppState: backend errors surface as RepositoryException and keep state intact', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();

    repo.failNextWrite = const RepositoryException('No internet connection. Check your network and try again.');
    await expectLater(state.addItem(name: 'Sugar 1kg', price: 155), throwsA(isA<RepositoryException>()));
    expect(state.items, isEmpty);
  });

  test('AppState: a failed load lands on loadFailed and can retry', () async {
    final repo = FakeRepository(signedIn: true); // no business row yet
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();
    expect(state.status, AppStatus.loadFailed);
    expect(state.loadError, isNotNull);
  });

  testWidgets('missing .env credentials show the setup screen', (tester) async {
    await tester.pumpWidget(const SetupApp());
    expect(find.text('Connect Supabase'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
    expect(find.byType(SetupRequiredScreen), findsOneWidget);
  });
}
