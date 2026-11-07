import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/models/customer.dart';
import 'package:my_first_app/models/khata.dart';
import 'package:my_first_app/services/whatsapp.dart';

const _business = Business(name: 'Al-Noor Traders', ownerName: 'Bilal', phone: '0300 1122334', contactNumber: '0321 9988776');
const _ahmed = Customer(id: 'c1', name: 'Ahmed Raza', phone: '0300 1234567');

KhataLineItem _line(String name, double price, double qty, DateTime d) =>
    KhataLineItem(itemId: name, name: name, price: price, quantity: qty, unit: 'kg', date: d);

void main() {
  group('whatsAppNumber', () {
    test('local, international and punctuated formats become wa.me digits', () {
      expect(whatsAppNumber('0300 1234567'), '923001234567');
      expect(whatsAppNumber('0300-1234567'), '923001234567');
      expect(whatsAppNumber('+92 300 1234567'), '923001234567');
      expect(whatsAppNumber('0092 300 1234567'), '923001234567');
      expect(whatsAppNumber('+1 (415) 555-0132'), '14155550132');
      expect(whatsAppNumber('3001234567'), '923001234567');
    });

    test('unusable numbers return null', () {
      expect(whatsAppNumber(''), isNull);
      expect(whatsAppNumber('12345'), isNull);
    });
  });

  test('whatsAppUri url-encodes the message for the right number', () {
    final uri = whatsAppUri('0300 1234567', 'Rs 100 & more\nline 2')!;
    expect(uri.toString(), startsWith('https://wa.me/923001234567?text='));
    expect(uri.queryParameters['text'], 'Rs 100 & more\nline 2');
    expect(whatsAppUri('abc', 'x'), isNull);
  });

  group('messages', () {
    final day = DateTime(2026, 10, 14);
    final earlier = _line('Sugar', 100, 2, DateTime(2026, 10, 1));
    final rice = _line('Rice', 200, 3, day);
    final khata = Khata(
      id: 'k1',
      customerId: 'c1',
      customerName: 'Ahmed Raza',
      customerInitials: 'AR',
      date: DateTime(2026, 10, 1),
      items: [earlier, rice],
      payments: const [],
      discount: 50,
      paid: 300,
    );

    test('entry message lists only this entry and the running balance', () {
      final msg = khataEntryMessage(
        KhataEntry(customer: _ahmed, khata: khata, lines: [rice], discount: 50, paid: 300, date: day),
        _business,
      );
      expect(msg, contains('*Al-Noor Traders* — Khata entry'));
      expect(msg, contains('Dear Ahmed Raza'));
      expect(msg, contains('14 Oct 2026'));
      expect(msg, contains('1. Rice — 3 kg × Rs 200 = *Rs 600*'));
      expect(msg, isNot(contains('Sugar'))); // earlier purchase is not part of this entry
      expect(msg, contains('Items total: Rs 600'));
      expect(msg, contains('Discount: −Rs 50'));
      expect(msg, contains('Paid: Rs 300'));
      expect(msg, contains('This entry: *Rs 250*'));
      expect(msg, contains('Total balance due on your khata: Rs 450'));
      expect(msg, contains('0321 9988776'));
    });

    test('statement message lists every line and says settled when paid off', () {
      final msg = khataStatementMessage(khata, _business);
      expect(msg, contains('Khata statement'));
      expect(msg, contains('Sugar'));
      expect(msg, contains('Rice'));
      expect(msg, contains('Balance due: Rs 450'));

      final settled = Khata(
        id: 'k2',
        customerId: 'c1',
        customerName: 'Ahmed Raza',
        customerInitials: 'AR',
        date: day,
        items: [rice],
        payments: const [],
        discount: 0,
        paid: 600,
      );
      expect(khataStatementMessage(settled, _business), contains('fully settled'));
    });
  });
}
