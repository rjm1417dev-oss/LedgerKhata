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
  Future<List<Customer>> fetchCustomers() async => List.of(_customers);

  @override
  Future<Customer> addCustomer({required String name, required String phone}) async {
    _maybeFail();
    final c = Customer(id: 'c${++_seq}', name: name.trim(), phone: phone.trim());
    _customers.add(c);
    return c;
  }

  @override
  Future<List<Item>> fetchItems() async => List.of(_items);

  @override
  Future<Item> addItem({required String name, required double price}) async {
    _maybeFail();
    final i = Item(id: 'i${++_seq}', name: name.trim(), price: price);
    _items.add(i);
    return i;
  }

  @override
  Future<List<Khata>> fetchKhatas() async => List.of(_khatas.reversed);

  @override
  Future<void> createKhata({
    required String customerId,
    required List<String> itemIds,
    required double discount,
    required double paid,
  }) async {
    _maybeFail();
    final customer = _customers.firstWhere((c) => c.id == customerId);
    final lines = itemIds.map((id) => _items.firstWhere((i) => i.id == id)).toList();
    final total = lines.fold(0.0, (a, i) => a + i.price);
    if (discount + paid > total) {
      throw const RepositoryException('Discount and paid amount can’t be more than the items total');
    }
    _khatas.add(Khata(
      id: 'k${++_seq}',
      customerId: customer.id,
      customerName: customer.name,
      customerInitials: customer.initials,
      date: DateTime(2026, 9, 25),
      items: lines.map((i) => KhataLineItem(itemId: i.id, name: i.name, price: i.price)).toList(),
      discount: discount,
      paid: paid,
    ));
  }
}
