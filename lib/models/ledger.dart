import 'khata.dart';

enum LedgerEntryType { purchase, payment }

/// One transaction in a customer's history: a single purchase or a single
/// payment, with the balance the customer owed right after it.
class LedgerEntry {
  final LedgerEntryType type;

  /// Purchase id or payment id.
  final String id;
  final String customerId;
  final DateTime date;

  /// Khatas this entry touches (a payment can be split over several).
  final List<String> khataIds;

  /// Purchases only: the lines bought, the subtotal and the discount given.
  final List<KhataLineItem> lines;
  final double subtotal;
  final double discount;

  /// Payments only: the amount received, and whether it was handed over
  /// together with a purchase.
  final double received;
  final bool withPurchase;

  /// Payments only: 'cash', 'online' or null when not recorded.
  final String? method;

  /// What the customer owed right after this entry.
  final double balanceAfter;

  const LedgerEntry({
    required this.type,
    required this.id,
    required this.customerId,
    required this.date,
    required this.khataIds,
    this.lines = const [],
    this.subtotal = 0,
    this.discount = 0,
    this.received = 0,
    this.withPurchase = false,
    this.method,
    required this.balanceAfter,
  });

  bool get isPurchase => type == LedgerEntryType.purchase;
  bool get isPayment => type == LedgerEntryType.payment;

  /// Purchase value after its discount.
  double get net => subtotal - discount;

  /// Money this entry moves: what was billed, or what was received.
  double get amount => isPurchase ? net : received;
}

/// A customer's purchases and payments from [khatas] (all belonging to that
/// one customer) as one chronological list, oldest first, with the running
/// balance after each. At the same instant a purchase sorts before a payment
/// (money handed over with an item follows it), then by recorded order.
List<LedgerEntry> buildCustomerLedger(List<Khata> khatas) {
  final raw =
      <
        ({
          LedgerEntryType type,
          DateTime date,
          int seq,
          KhataPurchase? purchase,
          List<KhataPayment>? parts,
          String customerId,
          List<String> khataIds,
        })
      >[];
  var seq = 0;

  for (final k in khatas) {
    for (final p in k.effectivePurchases) {
      raw.add((
        type: LedgerEntryType.purchase,
        date: p.date,
        seq: seq++,
        purchase: p,
        parts: null,
        customerId: k.customerId,
        khataIds: [k.id],
      ));
    }
  }

  // Allocations of one payment (possibly across khatas) become one entry.
  final byPayment = <String, List<(Khata, KhataPayment)>>{};
  for (final k in khatas) {
    for (final p in k.effectivePayments) {
      byPayment.putIfAbsent(p.paymentId, () => []).add((k, p));
    }
  }
  for (final group in byPayment.values) {
    group.sort((a, b) => a.$2.date.compareTo(b.$2.date));
    raw.add((
      type: LedgerEntryType.payment,
      date: group.first.$2.date,
      seq: seq++,
      purchase: null,
      parts: [for (final g in group) g.$2],
      customerId: group.first.$1.customerId,
      khataIds: {for (final g in group) g.$1.id}.toList(),
    ));
  }

  raw.sort((a, b) {
    final c = a.date.compareTo(b.date);
    if (c != 0) return c;
    if (a.type != b.type) return a.type == LedgerEntryType.purchase ? -1 : 1;
    return a.seq.compareTo(b.seq);
  });

  var balance = 0.0;
  final out = <LedgerEntry>[];
  for (final r in raw) {
    if (r.type == LedgerEntryType.purchase) {
      final p = r.purchase!;
      balance += p.net;
      out.add(
        LedgerEntry(
          type: r.type,
          id: p.id,
          customerId: r.customerId,
          date: p.date,
          khataIds: r.khataIds,
          lines: p.lines,
          subtotal: p.subtotal,
          discount: p.discount,
          balanceAfter: balance,
        ),
      );
    } else {
      final parts = r.parts!;
      final amount = parts.fold(0.0, (a, p) => a + p.amount);
      balance -= amount;
      out.add(
        LedgerEntry(
          type: r.type,
          id: parts.first.paymentId,
          customerId: r.customerId,
          date: r.date,
          khataIds: r.khataIds,
          received: amount,
          withPurchase: parts.any((p) => p.purchaseId != null),
          method: parts.map((p) => p.method).whereType<String>().firstOrNull,
          balanceAfter: balance,
        ),
      );
    }
  }
  return out;
}

/// What happened on one calendar day (in the device's timezone).
class DaySummary {
  final DateTime day;
  final int purchaseCount;
  final int paymentCount;
  final double purchased;
  final double received;

  /// The balance after the day's last entry.
  final double closingBalance;

  const DaySummary({
    required this.day,
    required this.purchaseCount,
    required this.paymentCount,
    required this.purchased,
    required this.received,
    required this.closingBalance,
  });
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Per-day counts and totals for [entries] (oldest first in, oldest first out).
List<DaySummary> summarizeByDay(List<LedgerEntry> entries) {
  final days = <DateTime, List<LedgerEntry>>{};
  for (final e in entries) {
    days.putIfAbsent(dayOf(e.date), () => []).add(e);
  }
  final keys = days.keys.toList()..sort();
  return [
    for (final d in keys)
      DaySummary(
        day: d,
        purchaseCount: days[d]!.where((e) => e.isPurchase).length,
        paymentCount: days[d]!.where((e) => e.isPayment).length,
        purchased: days[d]!
            .where((e) => e.isPurchase)
            .fold(0.0, (a, e) => a + e.net),
        received: days[d]!
            .where((e) => e.isPayment)
            .fold(0.0, (a, e) => a + e.received),
        closingBalance: days[d]!.last.balanceAfter,
      ),
  ];
}

/// Whole-history figures for a customer. Purchases are counted after
/// discount, so `purchased - paid == balance` always holds.
class LedgerTotals {
  final double purchased;
  final double paid;
  final int purchaseCount;
  final int paymentCount;

  const LedgerTotals({
    required this.purchased,
    required this.paid,
    required this.purchaseCount,
    required this.paymentCount,
  });

  double get balance => purchased - paid;
  bool get isSettled => balance <= 0;
}

LedgerTotals totalsOf(List<LedgerEntry> entries) => LedgerTotals(
  purchased: entries.where((e) => e.isPurchase).fold(0.0, (a, e) => a + e.net),
  paid: entries.where((e) => e.isPayment).fold(0.0, (a, e) => a + e.received),
  purchaseCount: entries.where((e) => e.isPurchase).length,
  paymentCount: entries.where((e) => e.isPayment).length,
);
