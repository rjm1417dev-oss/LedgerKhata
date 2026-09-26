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

  Future<List<Customer>> fetchCustomers();
  Future<Customer> addCustomer({required String name, required String phone});

  Future<List<Item>> fetchItems();
  Future<Item> addItem({required String name, required double price});

  Future<List<Khata>> fetchKhatas();
  Future<void> createKhata({
    required String customerId,
    required List<String> itemIds,
    required double discount,
    required double paid,
  });
}
