import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/models/item.dart';
import 'package:my_first_app/models/khata.dart';
import 'package:my_first_app/models/ledger.dart';
import 'package:my_first_app/reports/excel_report.dart';
import 'package:my_first_app/reports/khata_report.dart';
import 'package:my_first_app/state/app_state.dart';

import 'support/fake_repository.dart';

const _business = Business(name: 'Raza Store', ownerName: 'Raza', phone: '0300 0000000');

Future<(FakeRepository, AppState)> _setup() async {
  final repo = FakeRepository(signedIn: true, business: _business);
  final state = AppState(repo, splashMinimum: Duration.zero);
  await state.start();
  return (repo, state);
}

void main() {
  test('cotton is an available item unit', () {
    expect(kItemUnits, contains('cotton'));
  });

  test('several purchases and payments in one day stay separate records with running balances', () async {
    final (repo, state) = await _setup();
    final rice = await state.addItem(name: 'Rice', price: 100, unit: 'kg');
    final fabric = await state.addItem(name: 'Padding', price: 50, unit: 'cotton');
    final ahmed = await state.addCustomer(name: 'Ahmed', phone: '0300 1');

    repo.now = DateTime(2026, 10, 14, 9, 5);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 2)], discount: 0, paid: 50); // +200, -50
    repo.now = DateTime(2026, 10, 14, 11, 30);
    await state.recordCustomerPayment(customerId: ahmed.id, amount: 30); // -30
    repo.now = DateTime(2026, 10, 14, 15, 45);
    await state.addKhata(
        customer: ahmed, selectedItems: [SelectedKhataItem(item: fabric, quantity: 4)], discount: 20, paid: 0); // +180
    repo.now = DateTime(2026, 10, 14, 18, 10);
    await state.recordCustomerPayment(customerId: ahmed.id, amount: 100); // -100
    repo.now = DateTime(2026, 10, 15, 8, 0);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0); // +100

    final ledger = state.ledgerForCustomer(ahmed.id);
    expect(ledger.map((e) => e.type), [
      LedgerEntryType.purchase,
      LedgerEntryType.payment, // paid with the first purchase
      LedgerEntryType.payment,
      LedgerEntryType.purchase,
      LedgerEntryType.payment,
      LedgerEntryType.purchase,
    ]);
    expect(ledger.map((e) => e.balanceAfter), [200, 150, 120, 300, 200, 300]);
    expect(ledger[1].withPurchase, isTrue);
    expect(ledger[3].lines.single.unit, 'cotton');
    expect(ledger[3].discount, 20);

    // The last balance always equals what the customer actually owes.
    expect(ledger.last.balanceAfter, state.outstandingForCustomer(ahmed.id));

    final days = summarizeByDay(ledger);
    expect(days, hasLength(2));
    expect(days[0].purchaseCount, 2);
    expect(days[0].paymentCount, 3);
    expect(days[0].closingBalance, 200);
    expect(days[1].purchaseCount, 1);
    expect(days[1].paymentCount, 0);
  });

  test('one payment spread over two khatas is a single payment entry', () async {
    final (repo, state) = await _setup();
    final rice = await state.addItem(name: 'Rice', price: 100, unit: 'kg');
    final ahmed = await state.addCustomer(name: 'Ahmed', phone: '0300 1');
    repo.now = DateTime(2026, 10, 1, 10);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 100); // settled
    repo.now = DateTime(2026, 10, 2, 10);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0);
    expect(state.khatasForCustomer(ahmed.id), hasLength(2));
    repo.now = DateTime(2026, 10, 3, 10);
    await state.recordCustomerPayment(customerId: ahmed.id, amount: 100);

    final payments = state.ledgerForCustomer(ahmed.id).where((e) => e.isPayment && !e.withPurchase).toList();
    expect(payments, hasLength(1));
    expect(payments.single.received, 100);
  });

  test('reports list every purchase and payment with times, counts per day and balance after', () async {
    final (repo, state) = await _setup();
    final rice = await state.addItem(name: 'Rice', price: 100, unit: 'kg');
    final ahmed = await state.addCustomer(name: 'Ahmed', phone: '0300 1');
    repo.now = DateTime(2026, 10, 14, 9, 5);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 2)], discount: 0, paid: 0);
    repo.now = DateTime(2026, 10, 14, 12, 0);
    await state.addKhata(customer: ahmed, selectedItems: [SelectedKhataItem(item: rice, quantity: 1)], discount: 0, paid: 0);
    repo.now = DateTime(2026, 10, 14, 14, 0);
    await state.recordCustomerPayment(customerId: ahmed.id, amount: 50);
    repo.now = DateTime(2026, 10, 14, 16, 0);
    await state.recordCustomerPayment(customerId: ahmed.id, amount: 25);

    final report = buildKhataReport(
      business: _business,
      customers: state.customers,
      khatas: state.khatas,
      filter: ReportFilter(from: DateTime(2026, 10, 14), to: DateTime(2026, 10, 14)),
    );
    expect(report.ledgers, hasLength(1));
    final l = report.ledgers.single;
    expect(l.purchaseCount, 2);
    expect(l.paymentCount, 2);
    expect(l.days.single.purchaseCount, 2);
    expect(l.days.single.paymentCount, 2);
    expect(l.entries.map((e) => e.balanceAfter), [200, 300, 250, 225]);
    expect(l.entries.map((e) => e.date.hour), [9, 12, 14, 16]);

    // A narrower range keeps true balances (computed over the whole history).
    final later = buildKhataReport(
      business: _business,
      customers: state.customers,
      khatas: state.khatas,
      filter: ReportFilter(from: DateTime(2026, 10, 14)),
    );
    expect(later.ledgers.single.entries.last.balanceAfter, 225);

    final xlsx = buildExcelReport(report);
    final names = ZipDecoder().decodeBytes(xlsx).files.map((f) => f.name).join(' ');
    final workbook = String.fromCharCodes(ZipDecoder().decodeBytes(xlsx).findFile('xl/workbook.xml')!.content as List<int>);
    expect(names, contains('worksheets'));
    expect(workbook, contains('Transaction History'));
    expect(workbook, contains('Daily Summary'));
  });
}
