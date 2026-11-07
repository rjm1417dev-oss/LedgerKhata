import 'item.dart';

class KhataLineItem {
  final String itemId;
  final String name;

  /// Unit price at the time this line was added (an item's price can
  /// change later without altering past khata lines).
  final double price;
  final double quantity;
  final String unit;

  /// The purchase (one save of items) this line belongs to. Lines sharing a
  /// purchase id were bought together; empty only for hand-built test data.
  final String purchaseId;

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
    this.purchaseId = '',
  });

  double get lineTotal => price * quantity;
}

/// One purchase transaction: the items bought together at one moment, plus
/// the discount given on that purchase.
class KhataPurchase {
  final String id;
  final DateTime date;
  final double discount;
  final List<KhataLineItem> lines;

  const KhataPurchase({
    required this.id,
    required this.date,
    required this.discount,
    required this.lines,
  });

  double get subtotal => lines.fold(0.0, (a, l) => a + l.lineTotal);

  /// What this purchase adds to the customer's balance.
  double get net => subtotal - discount;
}

/// A payment recorded against a khata cycle. One payment by the customer can
/// be split across several khatas; [paymentId] ties those allocations
/// together. [purchaseId] is set when the money was handed over together with
/// a purchase.
class KhataPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String paymentId;
  final String? purchaseId;

  /// How it was paid: 'cash', 'online', or null when not recorded (older
  /// payments, money paid with a purchase, or left unselected).
  final String? method;

  const KhataPayment({
    required this.id,
    required this.amount,
    required this.date,
    String? paymentId,
    this.purchaseId,
    this.method,
  }) : paymentId = paymentId ?? id;
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

  /// Every purchase on this cycle, oldest first. Each is its own record, even
  /// when several happen on the same day.
  final List<KhataPurchase> purchases;
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
    this.purchases = const [],
    required this.discount,
    required this.paid,
  });

  double get total => items.fold(0.0, (a, i) => a + i.lineTotal);
  double get remaining => total - discount - paid;
  bool get isSettled => remaining <= 0;
  String get itemsSummary => items
      .map((i) => '${i.name} (${formatQuantity(i.quantity)} ${i.unit})')
      .join(', ');

  /// [purchases] when recorded; otherwise rebuilt from the item lines (one
  /// purchase per purchase id, or per instant when lines carry none), so data
  /// without purchase records still reads as a ledger. The cycle's discount
  /// goes on its first rebuilt purchase.
  List<KhataPurchase> get effectivePurchases {
    if (purchases.isNotEmpty || items.isEmpty) return purchases;
    final groups = <String, List<KhataLineItem>>{};
    for (final l in items) {
      groups
          .putIfAbsent(
            l.purchaseId.isNotEmpty
                ? l.purchaseId
                : 'at-${l.date.microsecondsSinceEpoch}',
            () => [],
          )
          .add(l);
    }
    final built = [
      for (final e in groups.entries)
        KhataPurchase(
          id: '$id/${e.key}',
          date: e.value.first.date,
          discount: 0,
          lines: e.value,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    built[0] = KhataPurchase(
      id: built[0].id,
      date: built[0].date,
      discount: discount,
      lines: built[0].lines,
    );
    return built;
  }

  /// [payments] plus, for older data, one estimated payment for money that
  /// was paid with the purchase but never logged (paid − logged payments),
  /// stamped right after the cycle's first purchase.
  List<KhataPayment> get effectivePayments {
    final logged = payments.fold(0.0, (a, p) => a + p.amount);
    final gap = paid - logged;
    final first = effectivePurchases.firstOrNull;
    if (gap <= 0 || first == null) return payments;
    return [
      KhataPayment(
        id: '$id/with-purchase',
        amount: gap,
        date: first.date.add(const Duration(microseconds: 1)),
        purchaseId: first.id,
      ),
      ...payments,
    ];
  }

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
