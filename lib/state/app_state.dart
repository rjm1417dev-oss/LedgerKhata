import 'package:flutter/foundation.dart';

import '../data/khata_repository.dart';
import '../l10n/translator.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';
import '../models/ledger.dart';
import '../services/whatsapp.dart';

enum AppStatus { starting, signedOut, ready, loadFailed }

/// Source of truth for the UI. Reads and writes go through [KhataRepository]
/// (Supabase in the app); this class keeps the loaded lists for the screens.
/// Remembers the chosen language between launches.
abstract class LanguageStore {
  Future<AppLanguage> load();
  Future<void> save(AppLanguage language);
}

class AppState extends ChangeNotifier {
  final KhataRepository _repo;
  final Duration splashMinimum;
  final LanguageStore? _languageStore;

  AppState(
    this._repo, {
    this.splashMinimum = const Duration(milliseconds: 1200),
    LanguageStore? languageStore,
  }) : _languageStore = languageStore;

  AppLanguage _language = AppLanguage.english;

  /// Language of the redesigned ledger screen (English until the user picks).
  AppLanguage get language => _language;

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    AppLocale.language = language;
    notifyListeners();
    await _languageStore?.save(language);
  }

  AppStatus _status = AppStatus.starting;
  String? _loadError;
  Business? _business;
  List<Customer> _customers = [];
  List<Item> _items = [];
  List<Khata> _khatas = [];
  bool _cameFromSignOut = false;

  AppStatus get status => _status;
  String? get loadError => _loadError;
  Business? get business => _business;

  /// True once the user has explicitly signed out this session — tells the
  /// auth flow to open on Sign in rather than Register.
  bool get cameFromSignOut => _cameFromSignOut;
  String? get email => _repo.userEmail;
  List<Customer> get customers => List.unmodifiable(_customers);
  List<Item> get items => List.unmodifiable(_items);
  List<Khata> get khatas => List.unmodifiable(_khatas);

  /// Shows the splash for at least [splashMinimum] while the saved session
  /// (if any) is restored.
  Future<void> start() async {
    final stored = await _languageStore?.load();
    if (stored != null) {
      _language = stored;
      AppLocale.language = stored;
    }
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

  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    await _repo.updatePassword(
      newPassword: newPassword,
      currentPassword: currentPassword,
    );
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
    _cameFromSignOut = true;
    _status = AppStatus.signedOut;
    notifyListeners();
  }

  Future<void> updateBusiness({
    required String name,
    required String ownerName,
    required String phone,
    String? address,
    String? contactNumber,
  }) async {
    _business = await _repo.updateBusiness(
      name: name,
      ownerName: ownerName,
      phone: phone,
      address: address,
      contactNumber: contactNumber,
    );
    notifyListeners();
  }

  Future<void> uploadBusinessLogo({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final url = await _repo.uploadBusinessLogo(
      bytes: bytes,
      fileExtension: fileExtension,
    );
    final b = _business;
    if (b != null) {
      _business = Business(
        name: b.name,
        ownerName: b.ownerName,
        phone: b.phone,
        address: b.address,
        contactNumber: b.contactNumber,
        logoUrl: url,
      );
      notifyListeners();
    }
  }

  Future<Customer> addCustomer({
    required String name,
    required String phone,
  }) async {
    final customer = await _repo.addCustomer(name: name, phone: phone);
    _customers = [..._customers, customer];
    notifyListeners();
    return customer;
  }

  Future<Customer> updateCustomer({
    required String id,
    required String name,
    required String phone,
  }) async {
    final customer = await _repo.updateCustomer(
      id: id,
      name: name,
      phone: phone,
    );
    _customers = [
      for (final c in _customers)
        if (c.id == id) customer else c,
    ];
    notifyListeners();
    return customer;
  }

  Future<void> deleteCustomer(String id) async {
    await _repo.deleteCustomer(id);
    _customers = _customers.where((c) => c.id != id).toList();
    notifyListeners();
  }

  Future<Item> addItem({
    required String name,
    required double price,
    required String unit,
  }) async {
    final item = await _repo.addItem(name: name, price: price, unit: unit);
    _items = [..._items, item];
    notifyListeners();
    return item;
  }

  Future<Item> updateItem({
    required String id,
    required String name,
    required double price,
    required String unit,
  }) async {
    final item = await _repo.updateItem(
      id: id,
      name: name,
      price: price,
      unit: unit,
    );
    _items = [
      for (final i in _items)
        if (i.id == id) item else i,
    ];
    notifyListeners();
    return item;
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteItem(id);
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
  }

  /// How many saved khatas mention this customer — used to block/inform on delete.
  int khataCountForCustomer(String customerId) =>
      _khatas.where((k) => k.customerId == customerId).length;

  /// How many saved khatas include this item — informational, since deleting
  /// an item never touches those khatas' saved name/price/unit.
  int khataUsageCountForItem(String itemId) =>
      _khatas.where((k) => k.items.any((l) => l.itemId == itemId)).length;

  /// Saves a purchase and returns what was just recorded, so the shopkeeper
  /// can send exactly that entry to the customer.
  Future<KhataEntry> addKhata({
    required Customer customer,
    required List<SelectedKhataItem> selectedItems,
    required double discount,
    required double paid,
  }) async {
    final before = khatasForCustomer(customer.id);
    final openBefore = before.where((k) => !k.isSettled).firstOrNull;
    final knownIds = before.map((k) => k.id).toSet();
    await _repo.createKhata(
      customerId: customer.id,
      items: selectedItems
          .map(
            (s) => KhataItemSelection(itemId: s.item.id, quantity: s.quantity),
          )
          .toList(),
      discount: discount,
      paid: paid,
    );
    _khatas = await _repo.fetchKhatas();
    notifyListeners();

    // The entry lands on the customer's open cycle, or starts a new one.
    final after = khatasForCustomer(customer.id);
    final khata =
        after.where((k) => k.id == openBefore?.id).firstOrNull ??
        after.where((k) => !knownIds.contains(k.id)).firstOrNull ??
        after.first;
    // Use the time the server actually stamped on this purchase.
    final saved = khata.effectivePurchases.lastOrNull;
    final now = saved?.date ?? DateTime.now();
    return KhataEntry(
      customer: customer,
      khata: khata,
      lines: [
        for (final s in selectedItems)
          KhataLineItem(
            itemId: s.item.id,
            name: s.item.name,
            price: s.item.price,
            quantity: s.quantity,
            unit: s.item.unit,
            date: now,
            purchaseId: saved?.id ?? '',
          ),
      ],
      discount: discount,
      paid: paid,
      date: now,
    );
  }

  Future<void> recordCustomerPayment({
    required String customerId,
    required double amount,
    String? method,
  }) async {
    await _repo.recordCustomerPayment(
      customerId: customerId,
      amount: amount,
      method: method,
    );
    _khatas = await _repo.fetchKhatas();
    notifyListeners();
  }

  /// Every purchase and payment this customer made, oldest first, each with
  /// the balance owed right after it.
  List<LedgerEntry> ledgerForCustomer(String customerId) =>
      buildCustomerLedger(khatasForCustomer(customerId));

  List<Khata> khatasForCustomer(String customerId) =>
      _khatas.where((k) => k.customerId == customerId).toList();

  /// What a customer still owes across all their khatas (never negative).
  double outstandingForCustomer(String customerId) => khatasForCustomer(
    customerId,
  ).fold(0.0, (a, k) => a + (k.remaining > 0 ? k.remaining : 0));

  /// Customers with an unpaid balance, largest first.
  List<Customer> get customersWithOutstanding {
    final owing = _customers
        .where((c) => outstandingForCustomer(c.id) > 0)
        .toList();
    owing.sort(
      (a, b) =>
          outstandingForCustomer(b.id).compareTo(outstandingForCustomer(a.id)),
    );
    return owing;
  }

  // Dashboard aggregates
  double get totalBilled => _khatas.fold(0.0, (a, k) => a + k.total);
  double get totalDiscount => _khatas.fold(0.0, (a, k) => a + k.discount);
  double get totalReceived => _khatas.fold(0.0, (a, k) => a + k.paid);
  double get totalRemaining =>
      _khatas.fold(0.0, (a, k) => a + (k.remaining > 0 ? k.remaining : 0));
  int get pendingKhataCount => _khatas.where((k) => !k.isSettled).length;
  List<Khata> get recentKhatas => _khatas.take(3).toList();
}
