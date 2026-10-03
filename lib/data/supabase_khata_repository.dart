import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';
import 'khata_repository.dart';

class SupabaseKhataRepository implements KhataRepository {
  SupabaseClient get _db => Supabase.instance.client;

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const RepositoryException('Please sign in again.');
    return id;
  }

  @override
  bool get hasSession => _db.auth.currentSession != null;

  @override
  String? get userEmail => _db.auth.currentUser?.email;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on RepositoryException {
      rethrow;
    } on AuthException catch (e) {
      throw RepositoryException(_authMessage(e));
    } on PostgrestException catch (e) {
      throw RepositoryException(_postgrestMessage(e));
    } on StorageException catch (e) {
      throw RepositoryException(_storageMessage(e));
    } catch (e) {
      final text = e.toString();
      if (text.contains('SocketException') ||
          text.contains('Failed host lookup') ||
          text.contains('ClientException') ||
          text.contains('XMLHttpRequest')) {
        throw const RepositoryException('No internet connection. Check your network and try again.');
      }
      throw const RepositoryException('Something went wrong. Please try again.');
    }
  }

  String _authMessage(AuthException e) {
    // The server can refuse an address that looks fine (unreachable domain,
    // an address its mail provider has flagged), so say that, not "invalid format".
    if (e.code == 'email_address_invalid') {
      return 'This email address was rejected. Please use a different, working email address.';
    }
    if (e.code == 'user_already_exists' || e.code == 'email_exists') {
      return 'An account with this email already exists. Sign in instead.';
    }
    if (e.code == 'over_email_send_rate_limit' || e.code == 'over_request_rate_limit') {
      return 'Too many attempts. Wait a minute and try again.';
    }
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'Wrong email or password.';
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'An account with this email already exists. Sign in instead.';
    }
    if (m.contains('email not confirmed')) return 'Confirm your email first, then sign in.';
    if (m.contains('password') && m.contains('characters')) return 'Password must be at least 6 characters.';
    if (m.contains('rate limit') || m.contains('too many')) return 'Too many attempts. Wait a minute and try again.';
    if (m.contains('invalid') && m.contains('email')) return 'Enter a valid email address.';
    if (m.contains('fetch') || m.contains('network') || m.contains('socket')) {
      return 'No internet connection. Check your network and try again.';
    }
    return e.message;
  }

  String _postgrestMessage(PostgrestException e) {
    // Errors we raise ourselves inside create_khata() are already worded for users.
    if (e.code == 'P0001') return e.message;
    if (e.code == '23503') return 'This can’t be deleted — it’s still used in existing khatas.';
    if (e.code == '23514') return 'That payment is more than the remaining amount.';
    if (e.code == '42501') return 'You don’t have permission to do that.';
    if (e.code == '42P01' || e.code == 'PGRST205' || e.code == 'PGRST202') {
      return 'The database isn’t set up yet. Run the Supabase migration first.';
    }
    return 'Something went wrong. Please try again.';
  }

  String _storageMessage(StorageException e) {
    if (e.statusCode == '404') return 'Logo storage isn’t set up yet. Run the Supabase migration first.';
    if (e.statusCode == '403') return 'You don’t have permission to do that.';
    return 'Couldn’t upload the logo. Please try again.';
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
  }) {
    return _guard(() async {
      final res = await _db.auth.signUp(
        email: email,
        password: password,
        data: {
          'business_name': businessName,
          'owner_name': ownerName,
          'phone': phone,
          if (address != null && address.isNotEmpty) 'address': address,
          if (contactNumber != null && contactNumber.isNotEmpty) 'contact_number': contactNumber,
        },
      );
      // An existing address returns a user with no identities instead of an error.
      if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
        throw const RepositoryException('An account with this email already exists. Sign in instead.');
      }
      return res.session != null;
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() => _db.auth.signInWithPassword(email: email, password: password));
  }

  @override
  Future<void> signOut() => _guard(() => _db.auth.signOut());

  @override
  Future<Business> ensureBusiness() {
    return _guard(() async {
      final existing = await _profile();
      if (existing != null) return existing;

      final meta = _db.auth.currentUser?.userMetadata ?? const {};
      final name = (meta['business_name'] as String?)?.trim() ?? '';
      final owner = (meta['owner_name'] as String?)?.trim() ?? '';
      final phone = (meta['phone'] as String?)?.trim() ?? '';
      if (name.isEmpty || owner.isEmpty || phone.isEmpty) {
        throw const RepositoryException('Your business profile is missing. Please register again.');
      }
      await _db.rpc('register_tenant', params: {
        'p_name': name,
        'p_owner_name': owner,
        'p_phone': phone,
        'p_address': (meta['address'] as String?)?.trim(),
        'p_contact_number': (meta['contact_number'] as String?)?.trim(),
      });
      return (await _profile()) ??
          (throw const RepositoryException('Your business profile is missing. Please register again.'));
    });
  }

  /// The signed-in user's profile row joined to its tenant (Row Level Security
  /// only ever returns their own).
  Future<Business?> _profile() async {
    final row = await _db.from('users').select('name, phone, tenants(name, address, logo_url, contact_number)').eq('id', _uid).maybeSingle();
    if (row == null) return null;
    final tenant = row['tenants'] as Map<String, dynamic>;
    return Business(
      name: tenant['name'] as String,
      ownerName: row['name'] as String,
      phone: row['phone'] as String,
      address: tenant['address'] as String?,
      logoUrl: tenant['logo_url'] as String?,
      contactNumber: tenant['contact_number'] as String?,
    );
  }

  Future<String> _tenantId() async {
    final row = await _db.from('users').select('tenant_id').eq('id', _uid).single();
    return row['tenant_id'] as String;
  }

  String? _blankToNull(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Future<Business> updateBusiness({
    required String name,
    required String ownerName,
    required String phone,
    String? address,
    String? contactNumber,
  }) {
    return _guard(() async {
      final tenantId = await _tenantId();
      await _db.from('tenants').update({
        'name': name.trim(),
        'address': _blankToNull(address),
        'contact_number': _blankToNull(contactNumber),
      }).eq('id', tenantId);
      await _db.from('users').update({'name': ownerName.trim(), 'phone': phone.trim()}).eq('id', _uid);
      return (await _profile()) ??
          (throw const RepositoryException('Your business profile is missing. Please register again.'));
    });
  }

  @override
  Future<String> uploadBusinessLogo({required Uint8List bytes, required String fileExtension}) {
    return _guard(() async {
      final tenantId = await _tenantId();
      final path = '$tenantId/logo.$fileExtension';
      await _db.storage.from('business-logos').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = '${_db.storage.from('business-logos').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
      await _db.from('tenants').update({'logo_url': url}).eq('id', tenantId);
      return url;
    });
  }

  Customer _customer(Map<String, dynamic> r) =>
      Customer(id: r['id'] as String, name: r['name'] as String, phone: r['phone'] as String);

  Item _item(Map<String, dynamic> r) => Item(
        id: r['id'] as String,
        name: r['name'] as String,
        price: (r['price'] as num).toDouble(),
        unit: r['unit'] as String,
      );

  @override
  Future<List<Customer>> fetchCustomers() {
    return _guard(() async {
      final rows = await _db.from('customers').select().order('created_at', ascending: true);
      return rows.map(_customer).toList();
    });
  }

  @override
  Future<Customer> addCustomer({required String name, required String phone}) {
    return _guard(() async {
      final row = await _db.from('customers').insert({'name': name.trim(), 'phone': phone.trim()}).select().single();
      return _customer(row);
    });
  }

  @override
  Future<Customer> updateCustomer({required String id, required String name, required String phone}) {
    return _guard(() async {
      final row = await _db.from('customers').update({'name': name.trim(), 'phone': phone.trim()}).eq('id', id).select().single();
      return _customer(row);
    });
  }

  @override
  Future<void> deleteCustomer(String id) {
    return _guard(() => _db.from('customers').delete().eq('id', id));
  }

  @override
  Future<List<Item>> fetchItems() {
    return _guard(() async {
      final rows = await _db.from('items').select().order('created_at', ascending: true);
      return rows.map(_item).toList();
    });
  }

  @override
  Future<Item> addItem({required String name, required double price, required String unit}) {
    return _guard(() async {
      final row = await _db.from('items').insert({'name': name.trim(), 'price': price, 'unit': unit.trim()}).select().single();
      return _item(row);
    });
  }

  @override
  Future<Item> updateItem({required String id, required String name, required double price, required String unit}) {
    return _guard(() async {
      final row =
          await _db.from('items').update({'name': name.trim(), 'price': price, 'unit': unit.trim()}).eq('id', id).select().single();
      return _item(row);
    });
  }

  @override
  Future<void> deleteItem(String id) {
    return _guard(() => _db.from('items').delete().eq('id', id));
  }

  @override
  Future<List<Khata>> fetchKhatas() {
    return _guard(() async {
      final rows = await _db
          .from('khatas')
          .select(
            'id, customer_id, discount, paid_amount, created_at, customers(name), '
            'khata_items(item_id, item_name, item_price, quantity, item_unit, created_at), '
            'khata_payments(id, amount, created_at)',
          )
          .order('created_at', ascending: false);
      return rows.map(_khata).toList();
    });
  }

  Khata _khata(Map<String, dynamic> r) {
    final lines = ((r['khata_items'] as List?) ?? const []).cast<Map<String, dynamic>>().toList()
      ..sort((a, b) => DateTime.parse(a['created_at'] as String).compareTo(DateTime.parse(b['created_at'] as String)));
    final payments = ((r['khata_payments'] as List?) ?? const []).cast<Map<String, dynamic>>().toList()
      ..sort((a, b) => DateTime.parse(a['created_at'] as String).compareTo(DateTime.parse(b['created_at'] as String)));
    final name = (r['customers'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';
    return Khata(
      id: r['id'] as String,
      customerId: r['customer_id'] as String,
      customerName: name,
      customerInitials: initialsOf(name),
      date: DateTime.parse(r['created_at'] as String).toLocal(),
      items: lines
          .map((l) => KhataLineItem(
                itemId: (l['item_id'] as String?) ?? '',
                name: l['item_name'] as String,
                price: (l['item_price'] as num).toDouble(),
                quantity: (l['quantity'] as num).toDouble(),
                unit: l['item_unit'] as String,
                date: DateTime.parse(l['created_at'] as String).toLocal(),
              ))
          .toList(),
      payments: payments
          .map((p) => KhataPayment(
                id: p['id'] as String,
                amount: (p['amount'] as num).toDouble(),
                date: DateTime.parse(p['created_at'] as String).toLocal(),
              ))
          .toList(),
      discount: (r['discount'] as num).toDouble(),
      paid: (r['paid_amount'] as num).toDouble(),
    );
  }

  @override
  Future<void> createKhata({
    required String customerId,
    required List<KhataItemSelection> items,
    required double discount,
    required double paid,
  }) {
    return _guard(() async {
      await _db.rpc('create_khata', params: {
        'p_customer_id': customerId,
        'p_item_ids': items.map((i) => i.itemId).toList(),
        'p_quantities': items.map((i) => i.quantity).toList(),
        'p_discount': discount,
        'p_paid': paid,
      });
    });
  }

  @override
  Future<void> recordCustomerPayment({required String customerId, required double amount}) {
    return _guard(() async {
      await _db.rpc('record_customer_payment', params: {'p_customer_id': customerId, 'p_amount': amount});
    });
  }
}
