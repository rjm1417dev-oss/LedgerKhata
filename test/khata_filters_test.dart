import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/l10n/translator.dart';
import 'package:my_first_app/models/khata.dart';
import 'package:my_first_app/models/khata_filters.dart';
import 'package:my_first_app/models/ledger.dart';
import 'package:my_first_app/widgets/khata_filters.dart';

import 'support/test_setup.dart';

LedgerEntry _entry(DateTime d, {bool purchase = true}) => LedgerEntry(
      type: purchase ? LedgerEntryType.purchase : LedgerEntryType.payment,
      id: '${d.microsecondsSinceEpoch}',
      customerId: 'c',
      date: d,
      khataIds: const ['k'],
      lines: const [],
      received: purchase ? 0 : 10,
      balanceAfter: 0,
    );

Khata _khata(DateTime opened, {List<DateTime> paid = const []}) => Khata(
      id: 'k',
      customerId: 'c',
      customerName: 'A',
      customerInitials: 'A',
      date: opened,
      items: [
        KhataLineItem(itemId: 'i', name: 'x', price: 1, quantity: 1, unit: 'kg', date: opened),
      ],
      payments: [for (final d in paid) KhataPayment(id: '$d', amount: 1, date: d)],
      discount: 0,
      paid: 0,
    );

void main() {
  tearDown(() => AppLocale.language = AppLanguage.english);

  group('filter logic', () {
    test('nothing set matches everything', () {
      expect(KhataFilters.none.isActive, isFalse);
      expect(KhataFilters.none.matchesEntry(_entry(DateTime(2026, 1, 1))), isTrue);
    });

    test('date range is inclusive by day, ignoring the time of day', () {
      final f = KhataFilters(from: DateTime(2026, 10, 14), to: DateTime(2026, 10, 15));
      expect(f.matchesDate(DateTime(2026, 10, 13, 23, 59)), isFalse);
      expect(f.matchesDate(DateTime(2026, 10, 14, 0, 0)), isTrue);
      expect(f.matchesDate(DateTime(2026, 10, 15, 23, 59)), isTrue);
      expect(f.matchesDate(DateTime(2026, 10, 16)), isFalse);
      // Open-ended ranges.
      expect(KhataFilters(from: DateTime(2026, 10, 14)).matchesDate(DateTime(2030)), isTrue);
      expect(KhataFilters(to: DateTime(2026, 10, 14)).matchesDate(DateTime(2020)), isTrue);
    });

    test('filters combine with AND', () {
      final f = KhataFilters(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31), kinds: const {EntryKind.payment});
      expect(f.matchesEntry(_entry(DateTime(2026, 10, 5), purchase: false)), isTrue);
      expect(f.matchesEntry(_entry(DateTime(2026, 10, 5))), isFalse); // wrong kind
      expect(f.matchesEntry(_entry(DateTime(2026, 11, 5), purchase: false)), isFalse); // wrong date
      // Several kinds = either.
      final both = f.copyWith(kinds: const {EntryKind.payment, EntryKind.purchase});
      expect(both.matchesEntry(_entry(DateTime(2026, 10, 5))), isTrue);
    });

    test('a start date after the end date is reported and not applied', () {
      final f = KhataFilters(from: DateTime(2026, 10, 20), to: DateTime(2026, 10, 10));
      expect(f.hasInvalidRange, isTrue);
      expect(f.matchesDate(DateTime(2026, 1, 1)), isTrue);
    });

    test('a month quick pick is the whole month, and is recognised', () {
      final f = KhataFilters.none.forMonth(DateTime(2026, 2, 17));
      expect(f.from, DateTime(2026, 2, 1));
      expect(f.to, DateTime(2026, 2, 28));
      expect(f.isMonth(DateTime(2026, 2)), isTrue);
      expect(f.isMonth(DateTime(2026, 3)), isFalse);
      expect(f.copyWith(clearTo: true).isMonth(DateTime(2026, 2)), isFalse);
    });

    test('a khata matches when opened, or any purchase or payment, is in range (old month rule)', () {
      final k = _khata(DateTime(2026, 9, 28), paid: [DateTime(2026, 10, 5)]);
      expect(KhataFilters.none.forMonth(DateTime(2026, 10)).matchesKhata(k), isTrue); // payment in Oct
      expect(KhataFilters.none.forMonth(DateTime(2026, 9)).matchesKhata(k), isTrue); // opened in Sep
      expect(KhataFilters.none.forMonth(DateTime(2026, 8)).matchesKhata(k), isFalse);
    });
  });

  group('filter panel', () {
    Future<void> pump(WidgetTester tester, KhataFilters initial, {bool kinds = true, AppLanguage lang = AppLanguage.english}) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      ignoreFontMetricOverflows();
      var filters = initial;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LanguageScope(
            language: lang,
            child: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: KhataFilterPanel(
                  filters: filters,
                  months: [DateTime(2026, 10), DateTime(2026, 9)],
                  showKinds: kinds,
                  onChanged: (f) => setState(() => filters = f),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('date range comes first, then Type; nothing is set at the start', (tester) async {
      await pump(tester, KhataFilters.none);
      final date = tester.getTopLeft(find.text('Date range')).dy;
      final type = tester.getTopLeft(find.text('Type').first).dy;
      expect(date, lessThan(type));
      expect(find.text('From…'), findsOneWidget);
      expect(find.text('To…'), findsOneWidget);
      expect(find.text('All'), findsOneWidget); // Type: All
      expect(find.text('Clear all filters'), findsNothing);
    });

    testWidgets('the Type dropdown stays open while several options are ticked', (tester) async {
      await pump(tester, KhataFilters.none);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Purchases').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payments').last);
      await tester.pumpAndSettle();
      // Still open: both rows and the Done button are on screen.
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Purchases, Payments'), findsOneWidget);
      expect(find.text('Clear all filters'), findsOneWidget);
    });

    testWidgets('each filter clears on its own, and Clear all resets everything', (tester) async {
      await pump(tester, KhataFilters(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31), kinds: const {EntryKind.payment}));
      expect(find.text('From: 1 Oct 2026'), findsOneWidget);
      expect(find.text('To: 31 Oct 2026'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Clear From date'));
      await tester.pumpAndSettle();
      expect(find.text('From…'), findsOneWidget);
      expect(find.text('To: 31 Oct 2026'), findsOneWidget); // others untouched

      await tester.tap(find.bySemanticsLabel('Clear Type'));
      await tester.pumpAndSettle();
      expect(find.text('All'), findsOneWidget);

      await tester.tap(find.text('Clear all filters'));
      await tester.pumpAndSettle();
      expect(find.text('To…'), findsOneWidget);
      expect(find.text('Clear all filters'), findsNothing);
    });

    testWidgets('a month quick pick sets the range', (tester) async {
      await pump(tester, KhataFilters.none);
      await tester.tap(find.text('Sep 2026'));
      await tester.pumpAndSettle();
      expect(find.text('From: 1 Sep 2026'), findsOneWidget);
      expect(find.text('To: 30 Sep 2026'), findsOneWidget);
    });

    testWidgets('an invalid range shows a message', (tester) async {
      await pump(tester, KhataFilters(from: DateTime(2026, 10, 20), to: DateTime(2026, 10, 10)));
      expect(find.text('The start date can’t be after the end date'), findsOneWidget);
    });

    testWidgets('labels follow the chosen language', (tester) async {
      AppLocale.language = AppLanguage.romanUrdu;
      await pump(tester, KhataFilters.none, lang: AppLanguage.romanUrdu);
      expect(find.text('Record Dhoondein'), findsOneWidget);
      expect(find.text('Tareekh'), findsWidgets);
      expect(find.text('Qism'), findsWidgets);
      expect(find.text('Sab'), findsOneWidget);
    });

    testWidgets('the Type filter is left out where it does not apply', (tester) async {
      await pump(tester, KhataFilters.none, kinds: false);
      expect(find.text('Type'), findsNothing);
      expect(find.text('Date range'), findsOneWidget);
    });
  });
}
