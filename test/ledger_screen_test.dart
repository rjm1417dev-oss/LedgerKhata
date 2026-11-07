import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/l10n/translator.dart';
import 'package:my_first_app/models/khata.dart';
import 'package:my_first_app/models/khata_filters.dart';
import 'package:my_first_app/models/ledger.dart';
import 'package:my_first_app/models/shop_time.dart';
import 'package:my_first_app/widgets/transaction_history.dart';

import 'support/test_setup.dart';

KhataLineItem _line(String name, double price, double qty, String unit, DateTime d, String pid) =>
    KhataLineItem(itemId: name, purchaseId: pid, name: name, price: price, quantity: qty, unit: unit, date: d);

/// One khata: 10:07 purchase (Cheeni + rice + Cotton cloth), 11:00 payment,
/// 11:30 payment, 15:00 purchase — all on the same day.
List<LedgerEntry> _sameDay() {
  final d = DateTime(2026, 10, 14);
  final p1 = DateTime(d.year, d.month, d.day, 10, 7);
  final p2 = DateTime(d.year, d.month, d.day, 15, 0);
  final lines1 = [
    _line('Cheeni', 100, 5, 'kg', p1, 'a'),
    _line('rice', 200, 5, 'kg', p1, 'a'),
    _line('Gaddi', 50, 4, 'cotton', p1, 'a'),
    _line('Aata', 300, 1, 'kg', p1, 'a'),
  ];
  final k = Khata(
    id: 'k1',
    customerId: 'c1',
    customerName: 'Ahmed',
    customerInitials: 'A',
    date: p1,
    items: [...lines1, _line('Oil', 500, 1, 'piece', p2, 'b')],
    purchases: [
      KhataPurchase(id: 'a', date: p1, discount: 0, lines: lines1),
      KhataPurchase(id: 'b', date: p2, discount: 0, lines: [_line('Oil', 500, 1, 'piece', p2, 'b')]),
    ],
    payments: [
      KhataPayment(id: 'x1', amount: 500, date: DateTime(d.year, d.month, d.day, 11, 0)),
      KhataPayment(id: 'x2', amount: 300, date: DateTime(d.year, d.month, d.day, 11, 30)),
    ],
    discount: 0,
    paid: 800,
  );
  return buildCustomerLedger([k]);
}

Future<void> _pump(WidgetTester tester, Widget child, {AppLanguage lang = AppLanguage.english}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ignoreFontMetricOverflows();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: LanguageScope(
        language: lang,
        child: Directionality(
          textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('shop time is Karachi (UTC+5) and groups by the shop day, not the UTC day', () {
    // 19:30 UTC on 14 Oct is 00:30 on 15 Oct in Karachi.
    final t = shopTime(DateTime.utc(2026, 10, 14, 19, 30));
    expect((t.year, t.month, t.day, t.hour, t.minute), (2026, 10, 15, 0, 30));
    expect(t.isUtc, isFalse);
    // 18:59 UTC is still 14 Oct 23:59.
    expect(shopTime(DateTime.utc(2026, 10, 14, 18, 59)).day, 14);

    final a = DateTime.utc(2026, 10, 14, 18, 59);
    final b = DateTime.utc(2026, 10, 14, 19, 1);
    expect(dayOf(shopTime(a)) == dayOf(shopTime(b)), isFalse);
  });

  test('totals reconcile: purchased - paid == balance == last balance after', () {
    final ledger = _sameDay();
    final t = totalsOf(ledger);
    expect(t.purchased, 2000 + 500); // 500+1000+200+300 = 2000, +500 oil
    expect(t.paid, 800);
    expect(t.balance, 1700);
    expect(ledger.last.balanceAfter, t.balance);
    expect(t.purchaseCount, 2);
    expect(t.paymentCount, 2);
  });

  testWidgets('purchases and payments are separate tiles, oldest first, without a repeated balance', (tester) async {
    await _pump(tester, TransactionHistory(entries: _sameDay()));

    expect(find.text('Wednesday, 14 October 2026'), findsOneWidget);
    expect(find.text('2 purchases · 2 payments'), findsOneWidget);
    expect(find.text('Purchase'), findsNWidgets(2));
    expect(find.text('Payment received'), findsNWidgets(2));

    // Oldest first inside the day.
    double y(String t) => tester.getTopLeft(find.text(t).first).dy;
    expect(y('10:07 AM'), lessThan(y('11:00 AM')));
    expect(y('11:00 AM'), lessThan(y('11:30 AM')));
    expect(y('11:30 AM'), lessThan(y('3:00 PM')));

    // Amounts. The balance is shown once at the top of the page, not on each entry.
    expect(find.text('Rs 2,000'), findsWidgets);
    expect(find.text('+ Rs 500'), findsOneWidget);
    expect(find.text('+ Rs 300'), findsOneWidget);
    expect(find.text('Balance now'), findsNothing);
    // Day totals.
    expect(find.text('Rs 800'), findsWidgets);
  });

  testWidgets('a purchase shows each item with quantity, unit, price and line total; many items fold', (tester) async {
    await _pump(tester, TransactionHistory(entries: _sameDay()));

    expect(find.text('Cheeni'), findsOneWidget);
    expect(find.text('5 kg × Rs 100 each'), findsOneWidget);
    expect(find.text('Rs 500'), findsWidgets);
    // 4 items: the 4th (Aata) is folded until expanded.
    expect(find.text('Aata'), findsNothing);
    await tester.tap(find.text('Show all 4 items'));
    await tester.pumpAndSettle();
    expect(find.text('Aata'), findsOneWidget);
    // The cotton line was within the first three and shows its unit.
    expect(find.text('4 cotton × Rs 50 each'), findsOneWidget);
    expect(find.text('Show fewer'), findsOneWidget);
  });

  testWidgets('the type filter hides entries but keeps each day\'s totals and balances true', (tester) async {
    await _pump(
      tester,
      TransactionHistory(entries: _sameDay(), kinds: const {EntryKind.payment}),
    );
    expect(find.text('Purchase'), findsNothing);
    expect(find.text('Payment received'), findsNWidgets(2));
    // The day still reports both purchases (not just the visible payments)...
    expect(find.text('2 purchases · 2 payments'), findsOneWidget);
    // ...and the end-of-day balance still counts every entry of the day.
    expect(find.text('Rs 1,700'), findsWidgets);
  });

  testWidgets('Roman Urdu wording', (tester) async {
    await _pump(tester, TransactionHistory(entries: _sameDay()),
        lang: AppLanguage.romanUrdu);
    expect(find.text('Khareedari'), findsWidgets);
    expect(find.text('Jama Raqam'), findsWidgets);
    expect(find.text('Ab Baqi'), findsNothing);
    expect(find.text('Budh, 14 Aktoobar 2026'), findsOneWidget);
  });

  testWidgets('Urdu wording lays out right-to-left', (tester) async {
    await _pump(tester, TransactionHistory(entries: _sameDay()),
        lang: AppLanguage.urdu);
    expect(find.text('خریداری'), findsWidgets);
    expect(Directionality.of(tester.element(find.text('خریداری').first)), TextDirection.rtl);
  });

  testWidgets('long histories load in pages of days', (tester) async {
    final entries = <LedgerEntry>[];
    var bal = 0.0;
    for (var i = 0; i < 20; i++) {
      bal += 100;
      entries.add(LedgerEntry(
        type: LedgerEntryType.payment,
        id: 'p$i',
        customerId: 'c',
        date: DateTime(2026, 9, 1 + i, 12),
        khataIds: const ['k'],
        received: 100,
        balanceAfter: bal,
      ));
    }
    await _pump(tester, TransactionHistory(entries: entries, pageDays: 5));
    expect(find.textContaining('2026'), findsNWidgets(5));
    await tester.ensureVisible(find.text('Show older days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show older days'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026'), findsNWidgets(10));
  });
}
