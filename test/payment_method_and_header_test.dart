import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/l10n/translator.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/models/khata.dart';
import 'package:my_first_app/reports/excel_report.dart';
import 'package:my_first_app/reports/khata_report.dart';
import 'package:my_first_app/state/app_state.dart';
import 'package:my_first_app/widgets/buttons.dart';
import 'package:my_first_app/widgets/language_selector.dart';

import 'support/fake_repository.dart';
import 'support/test_setup.dart';

const _business = Business(name: 'Al-Noor Traders', ownerName: 'Bilal Ahmed', phone: '0300 1122334');

Future<FakeRepository> _pump(WidgetTester tester, {Future<void> Function(FakeRepository)? seed}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ignoreFontMetricOverflows();
  final repo = FakeRepository(signedIn: true, business: _business);
  await seed?.call(repo);
  await tester.pumpWidget(KhataApp(repository: repo, splashMinimum: Duration.zero));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _seedOwing(FakeRepository repo) async {
  final rice = await repo.addItem(name: 'Rice', price: 1000, unit: 'kg');
  final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
  await repo.createKhata(
    customerId: ahmed.id,
    items: [KhataItemSelection(itemId: rice.id, quantity: 3)],
    discount: 0,
    paid: 0,
  );
}

Future<void> _openAhmed(WidgetTester tester) async {
  await tester.tap(find.text('Customers').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ahmed Raza'));
  await tester.pumpAndSettle();
}

Future<void> settleToasts(WidgetTester tester) => tester.pump(const Duration(seconds: 4));

void main() {
  tearDown(() => AppLocale.language = AppLanguage.english);

  group('payment method when clearing a khata', () {
    testWidgets('defaults to Cash and is saved with the payment', (tester) async {
      final repo = await _pump(tester, seed: _seedOwing);
      await _openAhmed(tester);
      await tester.tap(find.widgetWithText(PrimaryButtonSmall, 'Clear Khata'));
      await tester.pumpAndSettle();

      expect(find.text('Payment method'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget); // the default

      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Clear Khata'));
      await tester.pumpAndSettle();

      final payments = (await repo.fetchKhatas()).single.payments;
      expect(payments.single.amount, 1000);
      expect(payments.single.method, 'cash');
      await settleToasts(tester);
    });

    testWidgets('can be switched to Online, or left unselected (saved as null)', (tester) async {
      final repo = await _pump(tester, seed: _seedOwing);
      await _openAhmed(tester);
      await tester.tap(find.widgetWithText(PrimaryButtonSmall, 'Clear Khata'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '500');
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Online').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'Clear Khata'));
      await tester.pumpAndSettle();
      await settleToasts(tester);
      expect((await repo.fetchKhatas()).single.payments.last.method, 'online');

      await tester.tap(find.widgetWithText(PrimaryButtonSmall, 'Clear Khata'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '500');
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not selected').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'Clear Khata'));
      await tester.pumpAndSettle();
      await settleToasts(tester);
      expect((await repo.fetchKhatas()).single.payments.last.method, isNull);
    });

    test('shows in the history and in the Excel report; money is unaffected', () async {
      final repo = FakeRepository(signedIn: true, business: _business);
      final state = AppState(repo, splashMinimum: Duration.zero);
      await state.start();
      final rice = await state.addItem(name: 'Rice', price: 1000, unit: 'kg');
      final c = await state.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
      repo.now = DateTime(2026, 10, 1, 9);
      await state.addKhata(customer: c, selectedItems: [SelectedKhataItem(item: rice, quantity: 3)], discount: 0, paid: 0);
      repo.now = DateTime(2026, 10, 2, 9);
      await state.recordCustomerPayment(customerId: c.id, amount: 500, method: 'online');
      repo.now = DateTime(2026, 10, 3, 9);
      await state.recordCustomerPayment(customerId: c.id, amount: 700); // not recorded
      repo.now = DateTime(2026, 10, 4, 9);
      await state.recordCustomerPayment(customerId: c.id, amount: 300, method: 'cash');

      final payments = state.ledgerForCustomer(c.id).where((e) => e.isPayment).toList();
      expect(payments.map((e) => e.method), ['online', null, 'cash']);
      expect(state.outstandingForCustomer(c.id), 1500); // 3000 − 1500, unchanged by methods

      final report = buildKhataReport(
        business: _business,
        customers: state.customers,
        khatas: state.khatas,
        filter: const ReportFilter(),
      );
      final book = ZipDecoder().decodeBytes(buildExcelReport(report));
      final strings = String.fromCharCodes(book.findFile('xl/sharedStrings.xml')!.content as List<int>);
      expect(strings, contains('Payment method'));
      expect(strings, contains('Online'));
      expect(strings, contains('Cash'));
    });
  });

  group('customer page balance', () {
    testWidgets('"Balance now" is shown once at the top, never on each entry, and follows new payments', (tester) async {
      final repo = await _pump(tester, seed: (repo) async {
        await _seedOwing(repo);
        final ahmed = (await repo.fetchCustomers()).single;
        await repo.recordCustomerPayment(customerId: ahmed.id, amount: 500, method: 'cash');
      });
      await _openAhmed(tester);
      expect(find.text('Balance now'), findsOneWidget);
      expect(find.text('Payment received'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget); // payment method on the payment entry
      expect(find.text('Payment method'), findsOneWidget);

      // Another payment: still a single "Balance now" (the amount itself is animated).
      final ahmed = (await repo.fetchCustomers()).single;
      await tester.tap(find.widgetWithText(PrimaryButtonSmall, 'Clear Khata'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '500');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Clear Khata'));
      await tester.pumpAndSettle();
      await settleToasts(tester);
      expect(find.text('Balance now'), findsOneWidget);
      expect(find.text('Payment received'), findsNWidgets(2));
      expect(await repo.fetchKhatas().then((k) => k.single.paid), 1000);
      expect(ahmed.name, 'Ahmed Raza');
    });
  });

  group('top bar', () {
    testWidgets('every tab has the globe at the right; it opens the language popup', (tester) async {
      await _pump(tester);
      for (final tab in ['Dashboard', 'Khata', 'Items', 'Customers', 'Settings']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        final globe = find.byType(LanguageButton);
        expect(globe, findsOneWidget, reason: tab);
        expect(tester.getCenter(globe).dx, greaterThan(300), reason: '$tab: right side');
      }

      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      expect(find.text('Select language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Roman Urdu'), findsOneWidget);
      expect(find.text('اردو'), findsOneWidget);

      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();
      expect(find.text('Select language'), findsNothing);
      expect(Directionality.of(tester.element(find.byType(LanguageButton))), TextDirection.rtl);
      // In right-to-left the globe moves to the opposite edge.
      expect(tester.getCenter(find.byType(LanguageButton)).dx, lessThan(100));
    });

    testWidgets('Customers and Items have a round add button in the top-right, same style', (tester) async {
      await _pump(tester);
      final sizes = <Size>[];
      for (final tab in ['Customers', 'Items']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(PrimaryButtonSmall, 'Add'), findsNothing);
        final fab = find.byType(CircleActionButton);
        expect(fab, findsOneWidget, reason: tab);
        final c = tester.getCenter(fab);
        expect(c.dx, greaterThan(250), reason: tab);
        expect(c.dy, lessThan(120), reason: tab);
        sizes.add(tester.getSize(fab));
      }
      expect(sizes[0], sizes[1]);
      expect(sizes[0], const Size(48, 48));

      // Still opens the same Add sheets.
      await tester.tap(find.byType(CircleActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Add item'), findsWidgets);
    });
  });
}
