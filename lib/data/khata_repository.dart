import 'dart:typed_data';

import '../models/business.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';

/// A failure with a message that is safe to show the shopkeeper.
class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);

  @override
  String toString() => message;
}

/// An item and how many units of it went into a khata being created.
class KhataItemSelection {
  final String itemId;
  final double quantity;
  const KhataItemSelection({required this.itemId, required this.quantity});
}

/// Everything the app needs from a backend. The Supabase implementation is
/// the real one; tests use an in-memory fake.
abstract class KhataRepository {
  bool get hasSession;
  String? get userEmail;

  /// Returns true when the user is signed in straight away, false when the
  /// project requires email confirmation first.
  Future<bool> signUp({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    String? address,
    String? contactNumber,
  });

  Future<void> signIn({required String email, required String password});
  Future<void> signOut();

  /// The signed-in user's business, creating it from the sign-up details on
  /// first sign-in (needed when email confirmation delayed the first insert).
  Future<Business> ensureBusiness();

  Future<Business> updateBusiness({
    required String name,
    required String ownerName,
    required String phone,
    String? address,
    String? contactNumber,
  });

  /// Uploads a new business logo and saves it on the business, returning its URL.
  Future<String> uploadBusinessLogo({required Uint8List bytes, required String fileExtension});

  Future<List<Customer>> fetchCustomers();
  Future<Customer> addCustomer({required String name, required String phone});
  Future<Customer> updateCustomer({required String id, required String name, required String phone});
  Future<void> deleteCustomer(String id);

  Future<List<Item>> fetchItems();
  Future<Item> addItem({required String name, required double price, required String unit});
  Future<Item> updateItem({required String id, required String name, required double price, required String unit});
  Future<void> deleteItem(String id);

  Future<List<Khata>> fetchKhatas();

  /// Adds a purchase for this customer. Following traditional khata-book
  /// practice, this becomes a new line on their existing open (unsettled)
  /// cycle when they have one; only a customer with no open cycle gets a
  /// brand new khata.
  Future<void> createKhata({
    required String customerId,
    required List<KhataItemSelection> items,
    required double discount,
    required double paid,
  });

  /// Records a payment against a khata cycle, moving it toward settled.
  Future<void> recordKhataPayment({required String khataId, required double amount});
}
