class KhataLineItem {
  final String itemId;
  final String name;
  final double price;

  const KhataLineItem({required this.itemId, required this.name, required this.price});
}

class Khata {
  final String id;
  final String customerId;
  final String customerName;
  final String customerInitials;
  final DateTime date;
  final List<KhataLineItem> items;
  final double discount;
  final double paid;

  const Khata({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerInitials,
    required this.date,
    required this.items,
    required this.discount,
    required this.paid,
  });

  double get total => items.fold(0.0, (a, i) => a + i.price);
  double get remaining => total - discount - paid;
  bool get isSettled => remaining <= 0;
  String get itemsSummary => items.map((i) => i.name).join(', ');
}
