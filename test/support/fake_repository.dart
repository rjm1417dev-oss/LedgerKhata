import 'dart:typed_data';

import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/models/customer.dart';
import 'package:my_first_app/models/item.dart';
import 'package:my_first_app/models/khata.dart';

/// In-memory stand-in for Supabase so tests never touch the network.
class FakeRepository implements KhataRepository {
  final bool requireEmailConfirmation;
  bool _signedIn;
  Business? business;
  String? _email;
  final List<Customer> _customers = [];
  final List<Item> _items = [];
  final List<Khata> _khatas = [];
  int _seq = 0;
  RepositoryException? failNextWrite;

  /// "Today", used to date new khata lines and payments. Tests can advance
  /// it between calls to simulate purchases/payments on different days.
  DateTime now = DateTime(2026, 9, 25);

  FakeRepository({this.requireEmailConfirmation = false, bool signedIn = false, this.business})
      : _signedIn = signedIn {
    if (signedIn) _email = 'owner@example.com';
  }

  @override
  bool get hasSession => _signedIn;

  @override
  String? get userEmail => _email;

  void _maybeFail() {
    final e = failNextWrite;
    if (e != null) {
      failNextWrite = null;
      throw e;
    }
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    String? address,
    String? contactNumber,
  }) async {
    business = Business(
      name: businessName,
      ownerName: ownerName,
      phone: phone,
      address: address,
      contactNumber: contactNumber,
    );
    _email = email;
    if (requireEmailConfirmation) return false;
    _signedIn = true;
    return true;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (password != 'secret123') throw const RepositoryException('Wrong email or password.');
    _email = email;
    _signedIn = true;
  }

  @override
  Future<void> signOut() async => _signedIn = false;

  @override
  Future<Business> ensureBusiness() async =>
      business ?? (throw const RepositoryException('Your business profile is missing. Please register again.'));

  @override
  Future<Business> updateBusiness({
    required String name,
    required String ownerName,
    required String phone,
    String? address,
    String? contactNumber,
  }) async {
    _maybeFail();
    final updated = Business(
      name: name.trim(),
      ownerName: ownerName.trim(),
      phone: phone.trim(),
      address: (address == null || address.trim().isEmpty) ? null : address.trim(),
      contactNumber: (contactNumber == null || contactNumber.trim().isEmpty) ? null : contactNumber.trim(),
      logoUrl: business?.logoUrl,
    );
    business = updated;
    return updated;
  }

  @override
  Future<String> uploadBusinessLogo({required Uint8List bytes, required String fileExtension}) async {
    _maybeFail();
    final url = 'fake://business-logos/logo.$fileExtension';
    final b = business;
    business = Business(
      name: b?.name ?? '',
      ownerName: b?.ownerName ?? '',
      phone: b?.phone ?? '',
      address: b?.address,
      contactNumber: b?.contactNumber,
      logoUrl: url,
    );
    return url;
  }

  @override
  Future<List<Customer>> fetchCustomers() async => List.of(_customers);

  @override
  Future<Customer> addCustomer({required String name, required String phone}) async {
    _maybeFail();
    final c = Customer(id: 'c${++_seq}', name: name.trim(), phone: phone.trim());
    _customers.add(c);
    return c;
  }

  @override
  Future<Customer> updateCustomer({required String id, required String name, required String phone}) async {
    _maybeFail();
    final updated = Customer(id: id, name: name.trim(), phone: phone.trim());
    _customers[_customers.indexWhere((c) => c.id == id)] = updated;
    return updated;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    _maybeFail();
    if (_khatas.any((k) => k.customerId == id)) {
      throw const RepositoryException('This can’t be deleted — it’s still used in existing khatas.');
    }
    _customers.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<Item>> fetchItems() async => List.of(_items);

  @override
  Future<Item> addItem({required String name, required double price, required String unit}) async {
    _maybeFail();
    final i = Item(id: 'i${++_seq}', name: name.trim(), price: price, unit: unit.trim());
    _items.add(i);
    return i;
  }

  @override
  Future<Item> updateItem({required String id, required String name, required double price, required String unit}) async {
    _maybeFail();
    final updated = Item(id: id, name: name.trim(), price: price, unit: unit.trim());
    _items[_items.indexWhere((i) => i.id == id)] = updated;
    return updated;
  }

  @override
  Future<void> deleteItem(String id) async {
    _maybeFail();
    _items.removeWhere((i) => i.id == id);
  }

  @override
  Future<List<Khata>> fetchKhatas() async => List.of(_khatas.reversed);

  @override
  Future<void> createKhata({
    required String customerId,
    required List<KhataItemSelection> items,
    required double discount,
    required double paid,
  }) async {
    _maybeFail();
    final customer = _customers.firstWhere((c) => c.id == customerId);
    final lines = items.map((s) => (item: _items.firstWhere((i) => i.id == s.itemId), quantity: s.quantity)).toList();
    final newTotal = lines.fold(0.0, (a, l) => a + l.item.price * l.quantity);
    final newLines = lines
        .map((l) => KhataLineItem(
              itemId: l.item.id,
              name: l.item.name,
              price: l.item.price,
              quantity: l.quantity,
              unit: l.item.unit,
              date: now,
            ))
        .toList();

    // Traditional khata-book practice: keep adding rows to the customer's
    // open (unsettled) cycle; only start a new one once the last is settled.
    var openIndex = -1;
    for (var i = _khatas.length - 1; i >= 0; i--) {
      if (_khatas[i].customerId == customerId && !_khatas[i].isSettled) {
        openIndex = i;
        break;
      }
    }

    if (openIndex != -1) {
      final existing = _khatas[openIndex];
      final combinedTotal = existing.total + newTotal;
      final combinedDiscount = existing.discount + discount;
      final combinedPaid = existing.paid + paid;
      if (combinedDiscount + combinedPaid > combinedTotal) {
        throw const RepositoryException('Discount and paid amount can’t be more than the items total');
      }
      _khatas[openIndex] = Khata(
        id: existing.id,
        customerId: existing.customerId,
        customerName: existing.customerName,
        customerInitials: existing.customerInitials,
        date: existing.date,
        items: [...existing.items, ...newLines],
        payments: existing.payments,
        discount: combinedDiscount,
        paid: combinedPaid,
      );
    } else {
      if (discount + paid > newTotal) {
        throw const RepositoryException('Discount and paid amount can’t be more than the items total');
      }
      _khatas.add(Khata(
        id: 'k${++_seq}',
        customerId: customer.id,
        customerName: customer.name,
        customerInitials: customer.initials,
        date: now,
        items: newLines,
        payments: const [],
        discount: discount,
        paid: paid,
      ));
    }
  }

  @override
  Future<void> recordCustomerPayment({required String customerId, required double amount}) async {
    _maybeFail();
    if (amount <= 0) {
      throw const RepositoryException('Enter a payment amount greater than 0');
    }
    bool owes(Khata k) => k.customerId == customerId && k.remaining > 0;
    final outstanding = _khatas.where(owes).fold(0.0, (a, k) => a + k.remaining);
    if (outstanding <= 0) {
      throw const RepositoryException('This customer has no outstanding khata');
    }
    if (amount > outstanding) {
      throw RepositoryException('That payment is more than the outstanding amount (${outstanding.round()})');
    }
    var left = amount;
    for (var idx = 0; idx < _khatas.length && left > 0; idx++) {
      if (!owes(_khatas[idx])) continue;
      final existing = _khatas[idx];
      final apply = left < existing.remaining ? left : existing.remaining;
      _khatas[idx] = Khata(
        id: existing.id,
        customerId: existing.customerId,
        customerName: existing.customerName,
        customerInitials: existing.customerInitials,
        date: existing.date,
        items: existing.items,
        payments: [...existing.payments, KhataPayment(id: 'p${++_seq}', amount: apply, date: now)],
        discount: existing.discount,
        paid: existing.paid + apply,
      );
      left -= apply;
    }
  }
}
