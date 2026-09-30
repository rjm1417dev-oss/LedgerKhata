import 'item.dart';

class KhataLineItem {
  final String itemId;
  final String name;

  /// Unit price at the time this line was added (an item's price can
  /// change later without altering past khata lines).
  final double price;
  final double quantity;
  final String unit;

  /// When this specific purchase was recorded — a khata cycle can span many
  /// days, so each line keeps its own date rather than inheriting the
  /// cycle's start date.
  final DateTime date;

  const KhataLineItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.date,
  });

  double get lineTotal => price * quantity;
}

/// A payment recorded against a khata cycle.
class KhataPayment {
  final String id;
  final double amount;
  final DateTime date;

  const KhataPayment({required this.id, required this.amount, required this.date});
}

/// An item picked for a khata, still tied to the live [Item] (used while
/// building a khata, before it's saved).
class SelectedKhataItem {
  final Item item;
  final double quantity;

  const SelectedKhataItem({required this.item, required this.quantity});

  double get lineTotal => item.price * quantity;
}

/// One customer's khata cycle: a running tab that accumulates a new line
/// every time they buy on credit, until it's paid off in full. Traditional
/// khata-book practice — a cycle stays open (and keeps gaining rows) across
/// as many purchases and partial payments as it takes; once it's fully
/// settled, the customer's next purchase starts a new cycle.
class Khata {
  final String id;
  final String customerId;
  final String customerName;
  final String customerInitials;

  /// When this cycle was opened (its first purchase).
  final DateTime date;
  final List<KhataLineItem> items;
  final List<KhataPayment> payments;
  final double discount;
  final double paid;

  const Khata({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerInitials,
    required this.date,
    required this.items,
    required this.payments,
    required this.discount,
    required this.paid,
  });

  double get total => items.fold(0.0, (a, i) => a + i.lineTotal);
  double get remaining => total - discount - paid;
  bool get isSettled => remaining <= 0;
  String get itemsSummary => items.map((i) => '${i.name} (${formatQuantity(i.quantity)} ${i.unit})').join(', ');

  /// True when any purchase or payment on this cycle falls in [month]
  /// (year+month of any day); null matches every cycle ("All time").
  bool inMonth(DateTime? month) {
    if (month == null) return true;
    bool matches(DateTime d) => d.year == month.year && d.month == month.month;
    if (matches(date)) return true;
    if (items.any((i) => matches(i.date))) return true;
    if (payments.any((p) => matches(p.date))) return true;
    return false;
  }
}

/// Distinct months (as the 1st of each month) touched by any of [khatas],
/// newest first — the "All time" option is left for the caller to prepend.
List<DateTime> monthsIn(List<Khata> khatas) {
  final months = <DateTime>{};
  for (final k in khatas) {
    months.add(DateTime(k.date.year, k.date.month));
    for (final i in k.items) {
      months.add(DateTime(i.date.year, i.date.month));
    }
    for (final p in k.payments) {
      months.add(DateTime(p.date.year, p.date.month));
    }
  }
  final sorted = months.toList()..sort((a, b) => b.compareTo(a));
  return sorted;
}
