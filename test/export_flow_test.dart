import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/reports/report_exporter.dart';
import 'package:my_first_app/screens/export_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/state/app_state.dart';

import 'support/fake_repository.dart';
import 'support/test_setup.dart';

const _business = Business(name: 'Al-Noor Traders', ownerName: 'Bilal Ahmed', phone: '0300 1122334');

Future<FakeRepository> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ignoreFontMetricOverflows();
  final repo = FakeRepository(signedIn: true, business: _business);
  final rice = await repo.addItem(name: 'Rice', price: 200, unit: 'kg');
  final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
  final sana = await repo.addCustomer(name: 'Sana Malik', phone: '0311 7654321');
  // Ahmed: partially paid. Sana: pending.
  await repo.createKhata(customerId: ahmed.id, items: [KhataItemSelection(itemId: rice.id, quantity: 3)], discount: 50, paid: 100);
  await repo.createKhata(customerId: sana.id, items: [KhataItemSelection(itemId: rice.id, quantity: 1)], discount: 0, paid: 0);
  await tester.pumpWidget(KhataApp(repository: repo, splashMinimum: Duration.zero));
  await tester.pumpAndSettle();
  return repo;
}

Excel _decode(ReportFile f) => Excel.decodeBytes(f.bytes);

void main() {
  late List<ReportFile> saved;
  setUp(() {
    saved = [];
    reportSaver = (file) async => saved.add(file);
  });
  tearDown(() => reportSaver = (file) async {});

  testWidgets('Dashboard → Export Reports exports an Excel file with all customers', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Export Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Report type'), findsOneWidget);
    expect(find.text('Khata transactions'), findsOneWidget); // preview

    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export Excel'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(saved.single.fileName, endsWith('.xlsx'));
    final tx = _decode(saved.single)['Khata Transactions'];
    expect(tx.maxRows, 3); // header + both customers
    final names = tx.rows.skip(1).map((r) => r[3]!.value.toString()).toSet();
    expect(names, {'Ahmed Raza', 'Sana Malik'});
  });

  testWidgets('Pending preset keeps only khatas that still owe money', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Export Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cleared Khatas'));
    await tester.pumpAndSettle();
    expect(find.text('No Khata records match these filters.'), findsOneWidget);

    // Nothing to export → a message, and no file.
    await tester.tap(find.text('Export PDF'));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.text('Pending Khatas'));
    await tester.pumpAndSettle();
    expect(find.text('No Khata records match these filters.'), findsNothing);
    expect(find.text('2'), findsWidgets); // two transactions in the preview
  });

  testWidgets('Customer Detail → Export Report uses that customer automatically', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Customers').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sana Malik'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export Report'));
    await tester.pumpAndSettle();

    // Customer is shown, fixed — no picker, no report-type chooser.
    expect(find.text('Sana Malik · 0311 7654321'), findsOneWidget);
    expect(find.text('Report type'), findsNothing);
    expect(find.text('All customers'), findsNothing);
    // Date range + payment status filters are available.
    expect(find.text('Date range (khata opened)'), findsOneWidget);
    expect(find.text('Partially Paid'), findsOneWidget);

    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export Excel'));
    await tester.pumpAndSettle();

    final book = _decode(saved.single);
    final tx = book['Khata Transactions'];
    expect(tx.maxRows, 2); // header + Sana only
    expect(tx.rows[1][3]!.value.toString(), 'Sana Malik');
    expect(book['Report Summary'].rows.expand((r) => r).map((c) => c?.value.toString()), contains('Sana Malik (0311 7654321)'));
    expect(saved.single.fileName, contains('Sana_Malik'));
  });

  testWidgets('PDF export produces a PDF', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Export Reports'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Export PDF'));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(String.fromCharCodes(saved.single.bytes.take(5)), '%PDF-');
    expect(saved.single.fileName, endsWith('.pdf'));
  });

  testWidgets('an end date before the start date is rejected with a message', (tester) async {
    final repo = await _pump(tester);
    expect(repo, isNotNull);
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<AppState>.value(
        value: Provider.of<AppState>(context, listen: false),
        child: ExportReportScreen(initialFrom: DateTime(2026, 10, 10), initialTo: DateTime(2026, 10, 1)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('The start date can’t be after the end date'), findsOneWidget);
    expect(find.text('Fix the date range to see a preview.'), findsOneWidget);
    await tester.tap(find.text('Export PDF'));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    await tester.pump(const Duration(seconds: 4));
  });
}
