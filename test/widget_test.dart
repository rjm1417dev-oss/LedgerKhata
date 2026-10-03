import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/models/khata.dart';
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

    final rice = await state.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
    final oil = await state.addItem(name: 'Cooking Oil 1L', price: 560, unit: 'piece');
    final ahmed = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    await state.addKhata(
      customer: ahmed,
      selectedItems: [
        SelectedKhataItem(item: rice, quantity: 1),
        SelectedKhataItem(item: oil, quantity: 1),
      ],
      discount: 65,
      paid: 1500,
    );

    expect(state.totalBilled, 2210);
    expect(state.totalDiscount, 65);
    expect(state.totalReceived, 1500);
    expect(state.totalRemaining, 645);
    expect(state.pendingKhataCount, 1);
    expect(state.khatas.single.customerInitials, 'AR');
  });

  test('AppState: a second purchase for the same customer lands on their open khata, not a new one', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();

    final rice = await state.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
    final oil = await state.addItem(name: 'Cooking Oil 1L', price: 560, unit: 'piece');
    final ahmed = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');

    repo.now = DateTime(2026, 9, 1);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0);
    expect(state.khatas, hasLength(1));

    repo.now = DateTime(2026, 9, 10);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: oil, quantity: 1)], discount: 0, paid: 0);

    // Still one khata (cycle) — the second purchase became a new row on it.
    expect(state.khatas, hasLength(1));
    final khata = state.khatas.single;
    expect(khata.items, hasLength(2));
    expect(khata.total, 2210);
    expect(khata.items[0].date, DateTime(2026, 9, 1));
    expect(khata.items[1].date, DateTime(2026, 9, 10));
  });

  test('AppState: once a khata is fully paid, the next purchase starts a new cycle', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();

    final rice = await state.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
    final sugar = await state.addItem(name: 'Sugar', price: 100, unit: 'kg');
    final ahmed = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');

    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 1650);
    expect(state.khatas.single.isSettled, isTrue);

    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: sugar, quantity: 2)], discount: 0, paid: 0);

    // A second, separate cycle — the first stays settled and untouched.
    expect(state.khatas, hasLength(2));
    final settled = state.khatas.firstWhere((k) => k.isSettled);
    final open = state.khatas.firstWhere((k) => !k.isSettled);
    expect(settled.items.single.name, 'Basmati Rice 5kg');
    expect(open.items.single.name, 'Sugar');
    expect(open.total, 200);
  });

  test('AppState: clearing a customer khata spreads the payment oldest first and keeps every record', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();

    final rice = await state.addItem(name: 'Basmati Rice 5kg', price: 5000, unit: 'piece');
    final oil = await state.addItem(name: 'Cooking Oil 1L', price: 3000, unit: 'piece');
    final sugar = await state.addItem(name: 'Sugar', price: 1000, unit: 'kg');
    final ahmed = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');

    // Three purchases on one open khata cycle: 5,000 + 3,000 + 1,000 = 9,000.
    repo.now = DateTime(2026, 9, 1);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0);
    repo.now = DateTime(2026, 9, 8);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: oil, quantity: 1)], discount: 0, paid: 0);
    repo.now = DateTime(2026, 9, 20);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: sugar, quantity: 1)], discount: 0, paid: 0);
    expect(state.outstandingForCustomer(ahmed.id), 9000);

    await state.recordCustomerPayment(customerId: ahmed.id, amount: 4000);
    expect(state.outstandingForCustomer(ahmed.id), 5000);
    final cycle = state.khatas.single;
    expect(cycle.paid, 4000);
    expect(cycle.payments.single.amount, 4000);

    await state.recordCustomerPayment(customerId: ahmed.id, amount: 5000);
    expect(state.outstandingForCustomer(ahmed.id), 0);
    expect(state.customersWithOutstanding, isEmpty);
    // The purchase lines are still there as history.
    expect(state.khatas.single.items, hasLength(3));
    expect(state.khatas.single.isSettled, isTrue);
  });

  test('AppState: clearing across two open khatas pays the older one first', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();

    final rice = await state.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
    final ahmed = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0);
    // Settle the first cycle, so the next purchase opens a second one.
    await state.recordCustomerPayment(customerId: ahmed.id, amount: 1650);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0);
    expect(state.khatas, hasLength(2));

    await state.recordCustomerPayment(customerId: ahmed.id, amount: 100);
    final open = state.khatas.firstWhere((k) => !k.isSettled);
    expect(open.paid, 100);
    expect(state.outstandingForCustomer(ahmed.id), 1550);
  });

  test('AppState: a payment larger than the outstanding amount is rejected', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();

    final rice = await state.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
    final ahmed = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0);

    await expectLater(
      state.recordCustomerPayment(customerId: ahmed.id, amount: 2000),
      throwsA(isA<RepositoryException>()),
    );
    expect(state.outstandingForCustomer(ahmed.id), 1650);
  });

  test('AppState: updating business details persists name, owner, phone, address and contact number', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();
    expect(state.business?.address, isNull);

    await state.updateBusiness(
      name: 'Al-Noor Traders Ltd',
      ownerName: 'Bilal A. Khan',
      phone: '0300 1122335',
      address: 'Shop 4, Main Bazaar, Lahore',
      contactNumber: '0321 9876543',
    );

    expect(state.business?.name, 'Al-Noor Traders Ltd');
    expect(state.business?.ownerName, 'Bilal A. Khan');
    expect(state.business?.phone, '0300 1122335');
    expect(state.business?.address, 'Shop 4, Main Bazaar, Lahore');
    expect(state.business?.contactNumber, '0321 9876543');
  });

  test('AppState: uploading a business logo updates the stored URL without touching other fields', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();
    expect(state.business?.logoUrl, isNull);

    await state.uploadBusinessLogo(bytes: Uint8List.fromList([1, 2, 3]), fileExtension: 'png');

    expect(state.business?.logoUrl, isNotNull);
    expect(state.business?.name, _business.name);
  });

  test('AppState: backend errors surface as RepositoryException and keep state intact', () async {
    final repo = FakeRepository(signedIn: true, business: _business);
    final state = AppState(repo, splashMinimum: Duration.zero);
    await state.start();

    repo.failNextWrite = const RepositoryException('No internet connection. Check your network and try again.');
    await expectLater(state.addItem(name: 'Sugar 1kg', price: 155, unit: 'kg'), throwsA(isA<RepositoryException>()));
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
