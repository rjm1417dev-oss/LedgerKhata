import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/models/customer.dart';
import 'package:my_first_app/models/khata.dart';
import 'package:my_first_app/reports/excel_report.dart';
import 'package:my_first_app/reports/khata_report.dart';
import 'package:my_first_app/reports/pdf_report.dart';

const _business = Business(name: 'Al-Noor Traders', ownerName: 'Bilal', phone: '0300 1122334');
const _ahmed = Customer(id: 'c1', name: 'Ahmed Raza', phone: '0300 1234567');
const _urdu = Customer(id: 'c2', name: 'محمد علی', phone: '0311 7654321');
const _sana = Customer(id: 'c3', name: 'Sana Malik', phone: '0322 1112223');

KhataLineItem _line(String name, double price, double qty, DateTime d, {String unit = 'kg'}) =>
    KhataLineItem(itemId: name, name: name, price: price, quantity: qty, unit: unit, date: d);

Khata _khata(String id, Customer c, DateTime d, List<KhataLineItem> items,
        {double discount = 0, double paid = 0, List<KhataPayment> payments = const []}) =>
    Khata(
      id: id,
      customerId: c.id,
      customerName: c.name,
      customerInitials: c.initials,
      date: d,
      items: items,
      payments: payments,
      discount: discount,
      paid: paid,
    );

final _customers = [_ahmed, _urdu, _sana];
final _khatas = [
  // partially paid: 800 total − 50 discount − 300 paid (100 later payment + 200 with purchase)
  _khata('aaaaaaaa-1', _ahmed, DateTime(2026, 10, 1), [
    _line('Sugar', 100, 2, DateTime(2026, 10, 1)),
    _line('Rice', 200, 3, DateTime(2026, 10, 5)),
  ], discount: 50, paid: 300, payments: [KhataPayment(id: 'p1', amount: 100, date: DateTime(2026, 10, 8))]),
  // cleared
  _khata('bbbbbbbb-2', _urdu, DateTime(2026, 9, 10), [_line('چینی', 150, 2, DateTime(2026, 9, 10))], paid: 300),
  // pending: nothing paid
  _khata('cccccccc-3', _sana, DateTime(2026, 10, 12), [_line('Oil', 560, 1, DateTime(2026, 10, 12), unit: 'L')]),
  // second pending khata for Ahmed (older cycle was cleared before this one)
  _khata('dddddddd-4', _ahmed, DateTime(2026, 8, 3), [_line('Tea', 400, 1, DateTime(2026, 8, 3))], paid: 400),
];

KhataReport _report(ReportFilter f) =>
    buildKhataReport(business: _business, customers: _customers, khatas: _khatas, filter: f, now: DateTime(2026, 10, 14, 15, 30));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Tests don't load the app's declared fonts; load the report ones so Urdu
  // text is drawn with real glyphs.
  setUpAll(() async {
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }

    await load('ReportUrdu', ['NotoNaskhArabic-Regular.ttf']);
    await load('ReportSans', ['NotoSans-Regular.ttf']);
  });

  group('accounting', () {
    test('statuses and totals follow remaining = total − discount − paid', () {
      final r = _report(const ReportFilter());
      expect(r.count, 4);
      expect(r.pendingCount, 1);
      expect(r.partialCount, 1);
      expect(r.clearedCount, 2);
      expect(r.totalSales, 800 + 300 + 560 + 400);
      expect(r.totalDiscount, 50);
      expect(r.totalGrand, 800 + 300 + 560 + 400 - 50);
      expect(r.totalPaid, 300 + 300 + 0 + 400);
      expect(r.totalOutstanding, 450 + 560);
      // value, payments and outstanding stay consistent
      expect(r.totalGrand - r.totalPaid, r.totalOutstanding);
      final t = r.transactions.firstWhere((t) => t.khata.id == 'aaaaaaaa-1');
      expect(t.paidWithPurchases, 200);
      expect(t.weekday, 'Thursday');
    });

    test('pending report keeps only outstanding khatas and totals per customer', () {
      final r = _report(const ReportFilter(statuses: PaymentStatus.outstanding));
      expect(r.transactions.map((t) => t.status).toSet(), PaymentStatus.outstanding);
      expect(r.clearedCount, 0);
      expect(r.title, 'Pending Khatas Report');
      expect(r.customerBalances.map((b) => b.name), ['Sana Malik', 'Ahmed Raza']);
      expect(r.customerBalances.first.outstanding, 560);
    });

    test('filters combine: date range + customer + status', () {
      final r = _report(ReportFilter(
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 31),
        customerId: 'c1',
        statuses: const {PaymentStatus.cleared},
      ));
      expect(r.transactions.single.khata.id, 'dddddddd-4');
      expect(r.customer?.name, 'Ahmed Raza');
      // another customer's records never leak in
      expect(r.transactions.every((t) => t.khata.customerId == 'c1'), isTrue);
    });

    test('date range is inclusive of both end days and validated', () {
      final r = _report(ReportFilter(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 12)));
      expect(r.count, 2);
      expect(ReportFilter(from: DateTime(2026, 10, 5), to: DateTime(2026, 10, 1)).rangeError, isNotNull);
      expect(const ReportFilter().rangeError, isNull);
    });

    test('empty result is handled', () {
      final r = _report(ReportFilter(from: DateTime(2030, 1, 1)));
      expect(r.isEmpty, isTrue);
      expect(r.totalOutstanding, 0);
    });
  });

  group('files', () {
    final out = Platform.environment['REPORT_OUT'];

    test('PDF builds for full and empty reports, including Urdu names', () async {
      final fonts = await ReportFonts.load();
      final full = await buildPdfReport(_report(const ReportFilter()), fonts);
      expect(String.fromCharCodes(full.take(5)), '%PDF-');
      final empty = await buildPdfReport(_report(ReportFilter(from: DateTime(2030, 1, 1))), fonts);
      expect(String.fromCharCodes(empty.take(5)), '%PDF-');
      // Many transactions → several pages, no layout exception.
      final many = [
        for (var i = 0; i < 60; i++)
          _khata('k$i-xxxxxxxx', i.isEven ? _ahmed : _urdu, DateTime(2026, 9, 1).add(Duration(days: i)), [
            for (var j = 0; j < 4; j++) _line('Item $j', 10.0 + j, 1.5 + j, DateTime(2026, 9, 1)),
          ], paid: 10),
      ];
      final big = await buildPdfReport(
        buildKhataReport(business: _business, customers: _customers, khatas: many, filter: const ReportFilter()),
        fonts,
      );
      expect(big.length, greaterThan(full.length));
      if (out != null) {
        File('$out/report.pdf').writeAsBytesSync(full);
        File('$out/report_empty.pdf').writeAsBytesSync(empty);
        File('$out/report_many.pdf').writeAsBytesSync(big);
      }
    });

    test('Excel has the expected sheets, numeric cells, filter and frozen header', () {
      final bytes = buildExcelReport(_report(const ReportFilter()));
      if (out != null) File('$out/report.xlsx').writeAsBytesSync(bytes);

      final book = Excel.decodeBytes(bytes);
      expect(book.tables.keys, containsAll(['Report Summary', 'Khata Transactions', 'Item Details', 'Customer Balances', 'Payments']));

      final tx = book['Khata Transactions'];
      expect(tx.maxRows, 5); // header + 4
      final header = tx.row(0).map((c) => c?.value.toString()).toList();
      expect(header, containsAll(['Transaction ID', 'Day', 'Customer', 'Remaining balance', 'Payment status']));
      final rem = header.indexOf('Remaining balance');
      final ahmedRow = tx.rows.firstWhere((r) => r[0]?.value.toString() == 'K-AAAAAAAA');
      final remValue = ahmedRow[rem]!.value;
      expect(remValue, anyOf(isA<DoubleCellValue>(), isA<IntCellValue>())); // numeric, not text
      expect(num.parse(remValue.toString()), 450);
      expect(ahmedRow[header.indexOf('Phone')]!.value.toString(), '0300 1234567'); // text keeps the leading 0
      expect(ahmedRow[1]!.value, isA<DateCellValue>());

      // Item rows: one per line, not duplicated per item for totals.
      expect(book['Item Details'].maxRows, 1 + 2 + 1 + 1 + 1);

      final zip = ZipDecoder().decodeBytes(bytes);
      final sheetXml = zip.files.where((f) => f.name.startsWith('xl/worksheets/')).map((f) => utf8.decode(f.content as List<int>)).toList();
      expect(sheetXml.where((x) => x.contains('<autoFilter ref="A1:M5"/>')), hasLength(1));
      expect(sheetXml.where((x) => x.contains('state="frozen"')), isNotEmpty);
    });
  });
}
