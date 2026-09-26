import 'package:flutter/foundation.dart';

import '../data/khata_repository.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';

enum AppStatus { starting, signedOut, ready, loadFailed }

/// Source of truth for the UI. Reads and writes go through [KhataRepository]
/// (Supabase in the app); this class keeps the loaded lists for the screens.
class AppState extends ChangeNotifier {
  final KhataRepository _repo;
  final Duration splashMinimum;

  AppState(this._repo, {this.splashMinimum = const Duration(milliseconds: 1200)});

  AppStatus _status = AppStatus.starting;
  String? _loadError;
  Business? _business;
  List<Customer> _customers = [];
  List<Item> _items = [];
  List<Khata> _khatas = [];

  AppStatus get status => _status;
  String? get loadError => _loadError;
  Business? get business => _business;
  String? get email => _repo.userEmail;
  List<Customer> get customers => List.unmodifiable(_customers);
  List<Item> get items => List.unmodifiable(_items);
  List<Khata> get khatas => List.unmodifiable(_khatas);

  /// Shows the splash for at least [splashMinimum] while the saved session
  /// (if any) is restored.
  Future<void> start() async {
    await Future.wait([Future<void>.delayed(splashMinimum), _restoreSession()]);
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    if (!_repo.hasSession) {
      _status = AppStatus.signedOut;
      return;
    }
    await _loadAll();
  }

  Future<void> retryLoad() async {
    _status = AppStatus.starting;
    notifyListeners();
    await _loadAll();
    notifyListeners();
  }

  Future<void> _loadAll() async {
    try {
      _business = await _repo.ensureBusiness();
      final results = await Future.wait([
        _repo.fetchCustomers(),
        _repo.fetchItems(),
        _repo.fetchKhatas(),
      ]);
      _customers = results[0] as List<Customer>;
      _items = results[1] as List<Item>;
      _khatas = results[2] as List<Khata>;
      _loadError = null;
      _status = AppStatus.ready;
    } on RepositoryException catch (e) {
      _loadError = e.message;
      _status = AppStatus.loadFailed;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _repo.signIn(email: email, password: password);
    await _loadAll();
    notifyListeners();
  }

  /// Returns false when the project wants the email confirmed before sign-in.
  Future<bool> signUp({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    String? address,
    String? contactNumber,
  }) async {
    final signedIn = await _repo.signUp(
      email: email,
      password: password,
      businessName: businessName,
      ownerName: ownerName,
      phone: phone,
      address: address,
      contactNumber: contactNumber,
    );
    if (!signedIn) return false;
    await _loadAll();
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _business = null;
    _customers = [];
    _items = [];
    _khatas = [];
    _loadError = null;
    _status = AppStatus.signedOut;
    notifyListeners();
  }

  Future<Customer> addCustomer({required String name, required String phone}) async {
    final customer = await _repo.addCustomer(name: name, phone: phone);
    _customers = [..._customers, customer];
    notifyListeners();
    return customer;
  }

  Future<Item> addItem({required String name, required double price}) async {
    final item = await _repo.addItem(name: name, price: price);
    _items = [..._items, item];
    notifyListeners();
    return item;
  }

  Future<void> addKhata({
    required Customer customer,
    required List<Item> selectedItems,
    required double discount,
    required double paid,
  }) async {
    await _repo.createKhata(
      customerId: customer.id,
      itemIds: selectedItems.map((i) => i.id).toList(),
      discount: discount,
      paid: paid,
    );
    _khatas = await _repo.fetchKhatas();
    notifyListeners();
  }

  // Dashboard aggregates
  double get totalBilled => _khatas.fold(0.0, (a, k) => a + k.total);
  double get totalDiscount => _khatas.fold(0.0, (a, k) => a + k.discount);
  double get totalReceived => _khatas.fold(0.0, (a, k) => a + k.paid);
  double get totalRemaining => _khatas.fold(0.0, (a, k) => a + (k.remaining > 0 ? k.remaining : 0));
  int get pendingKhataCount => _khatas.where((k) => !k.isSettled).length;
  List<Khata> get recentKhatas => _khatas.take(3).toList();
}
