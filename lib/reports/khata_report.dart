import 'package:intl/intl.dart';

import '../l10n/translator.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';
import '../models/ledger.dart';

/// Payment status of one khata, derived from the app's accounting model:
/// remaining = total − discount − paid.
enum PaymentStatus {
  pending('Pending'),
  partiallyPaid('Partially Paid'),
  cleared('Cleared');

  /// English wording; [label] converts it to the language in force.
  final String _label;
  const PaymentStatus(this._label);

  String get label => tr(_label);

  /// Statuses that still owe money.
  static const outstanding = {pending, partiallyPaid};
}

PaymentStatus paymentStatusOf(Khata k) {
  if (k.remaining <= 0) return PaymentStatus.cleared;
  return k.paid > 0 ? PaymentStatus.partiallyPaid : PaymentStatus.pending;
}

/// What the shopkeeper asked for. Every field narrows the result; all of them
/// combine.
class ReportFilter {
  /// Inclusive day range on the khata's opening date (time of day ignored).
  final DateTime? from;
  final DateTime? to;
  final Set<PaymentStatus> statuses;
  final String? customerId;

  const ReportFilter({
    this.from,
    this.to,
    this.statuses = const {
      PaymentStatus.pending,
      PaymentStatus.partiallyPaid,
      PaymentStatus.cleared,
    },
    this.customerId,
  });

  static const allStatuses = {
    PaymentStatus.pending,
    PaymentStatus.partiallyPaid,
    PaymentStatus.cleared,
  };

  /// Null when valid, otherwise a message for the shopkeeper.
  String? get rangeError {
    if (from != null && to != null && _day(from!).isAfter(_day(to!))) {
      return tr('The start date can’t be after the end date');
    }
    return null;
  }

  String get title {
    if (_same(statuses, PaymentStatus.outstanding))
      return tr('Pending Khatas Report');
    if (_same(statuses, {PaymentStatus.cleared}))
      return tr('Cleared Khatas Report');
    if (_same(statuses, allStatuses)) return tr('All Khatas Report');
    return tr('Khata Report');
  }

  String get rangeLabel {
    final f = AppLocale.translator;
    if (from == null && to == null) return tr('All dates');
    if (from != null && to != null) return '${f.date(from!)} – ${f.date(to!)}';
    return from != null ? 'From ${f.date(from!)}' : 'Up to ${f.date(to!)}';
  }

  String get statusLabel {
    if (_same(statuses, allStatuses)) return tr('All statuses');
    return [
      for (final s in PaymentStatus.values)
        if (statuses.contains(s)) s.label,
    ].join(', ');
  }

  static bool _same(Set<PaymentStatus> a, Set<PaymentStatus> b) =>
      a.length == b.length && a.containsAll(b);
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

class ReportTransaction {
  final Khata khata;
  final String customerName;
  final String customerPhone;

  const ReportTransaction({
    required this.khata,
    required this.customerName,
    required this.customerPhone,
  });

  /// Short display id (the full id is a UUID).
  String get id =>
      'K-${khata.id.length > 8 ? khata.id.substring(0, 8).toUpperCase() : khata.id.toUpperCase()}';
  DateTime get date => khata.date;
  String get weekday => AppLocale.translator.weekday(khata.date.weekday);
  List<KhataLineItem> get lines => khata.items;

  /// Sum of item subtotals, before discount.
  double get subtotal => khata.total;
  double get discount => khata.discount;
  double get grandTotal => khata.total - khata.discount;
  double get paid => khata.paid;
  double get remaining => khata.remaining > 0 ? khata.remaining : 0;
  PaymentStatus get status => paymentStatusOf(khata);

  /// Payments logged against this khata after it was opened.
  List<KhataPayment> get loggedPayments => khata.payments;

  /// Paid at purchase time: the khata's paid total minus the logged payments.
  double get paidWithPurchases {
    final logged = khata.payments.fold(0.0, (a, p) => a + p.amount);
    final v = khata.paid - logged;
    return v > 0 ? v : 0;
  }

  double get totalQuantity => lines.fold(0.0, (a, l) => a + l.quantity);
}

class CustomerBalance {
  final String customerId;
  final String name;
  final String phone;
  final int transactions;
  final double grandTotal;
  final double paid;
  final double outstanding;

  const CustomerBalance({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.transactions,
    required this.grandTotal,
    required this.paid,
    required this.outstanding,
  });
}

/// One customer's purchases and payments inside the report's date range, in
/// time order, each with the balance owed right after it.
class CustomerLedger {
  final String customerId;
  final String name;
  final String phone;
  final List<LedgerEntry> entries;
  final List<DaySummary> days;

  const CustomerLedger({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.entries,
    required this.days,
  });

  int get purchaseCount => entries.where((e) => e.isPurchase).length;
  int get paymentCount => entries.where((e) => e.isPayment).length;
}

class KhataReport {
  final Business business;
  final ReportFilter filter;
  final DateTime generatedAt;
  final List<ReportTransaction> transactions;
  final List<CustomerBalance> customerBalances;

  /// Transaction history per customer (every purchase and payment in range).
  final List<CustomerLedger> ledgers;

  /// Set when the report is for a single customer's detail page.
  final Customer? customer;

  const KhataReport({
    required this.business,
    required this.filter,
    required this.generatedAt,
    required this.transactions,
    required this.customerBalances,
    this.ledgers = const [],
    this.customer,
  });

  int get purchaseEventCount => ledgers.fold(0, (a, l) => a + l.purchaseCount);
  int get paymentEventCount => ledgers.fold(0, (a, l) => a + l.paymentCount);

  bool get isEmpty => transactions.isEmpty && ledgers.isEmpty;
  int get count => transactions.length;

  /// Total value of items sold on credit, before discounts.
  double get totalSales => transactions.fold(0.0, (a, t) => a + t.subtotal);
  double get totalDiscount => transactions.fold(0.0, (a, t) => a + t.discount);
  double get totalGrand => transactions.fold(0.0, (a, t) => a + t.grandTotal);

  /// Payments received (at purchase and logged later).
  double get totalPaid => transactions.fold(0.0, (a, t) => a + t.paid);
  double get totalOutstanding =>
      transactions.fold(0.0, (a, t) => a + t.remaining);
  int countOf(PaymentStatus s) =>
      transactions.where((t) => t.status == s).length;
  int get pendingCount => countOf(PaymentStatus.pending);
  int get partialCount => countOf(PaymentStatus.partiallyPaid);
  int get clearedCount => countOf(PaymentStatus.cleared);

  String get title =>
      customer == null ? filter.title : '${filter.title} — ${customer!.name}';

  /// Human-readable list of the applied filters, for report headers.
  List<String> get filterLines => [
    tr('Date range: ${filter.rangeLabel}'),
    tr('Payment status: ${filter.statusLabel}'),
    tr('Customer: ${customer?.name ?? tr('All customers')}'),
  ];

  /// File-name friendly stem, e.g. `Khata_Report_Ahmed_Raza_20261014_1530`.
  String get fileStem {
    final who = customer?.name ?? business.name;
    final safe = who
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(generatedAt);
    return 'Khata_Report_${safe.isEmpty ? tr('Shop') : safe}_$stamp';
  }
}

/// Builds the report from the signed-in shopkeeper's own, already tenant-scoped
/// data (the repository only ever returns the current tenant's rows). Filters
/// combine; nothing is modified.
KhataReport buildKhataReport({
  required Business business,
  required List<Customer> customers,
  required List<Khata> khatas,
  required ReportFilter filter,
  DateTime? now,
}) {
  final byId = {for (final c in customers) c.id: c};
  final customer = filter.customerId == null ? null : byId[filter.customerId];

  bool inRange(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    if (filter.from != null &&
        day.isBefore(
          DateTime(filter.from!.year, filter.from!.month, filter.from!.day),
        ))
      return false;
    if (filter.to != null &&
        day.isAfter(
          DateTime(filter.to!.year, filter.to!.month, filter.to!.day),
        ))
      return false;
    return true;
  }

  final matching = khatas.where((k) {
    if (filter.customerId != null && k.customerId != filter.customerId)
      return false;
    if (!filter.statuses.contains(paymentStatusOf(k))) return false;
    return inRange(k.date);
  }).toList()..sort((a, b) => a.date.compareTo(b.date));

  final transactions = [
    for (final k in matching)
      ReportTransaction(
        khata: k,
        customerName: byId[k.customerId]?.name ?? k.customerName,
        customerPhone: byId[k.customerId]?.phone ?? '',
      ),
  ];

  // One row per customer in the report, with their totals across the
  // transactions shown.
  final balances = <String, CustomerBalance>{};
  for (final t in transactions) {
    final prev = balances[t.khata.customerId];
    balances[t.khata.customerId] = CustomerBalance(
      customerId: t.khata.customerId,
      name: t.customerName,
      phone: t.customerPhone,
      transactions: (prev?.transactions ?? 0) + 1,
      grandTotal: (prev?.grandTotal ?? 0) + t.grandTotal,
      paid: (prev?.paid ?? 0) + t.paid,
      outstanding: (prev?.outstanding ?? 0) + t.remaining,
    );
  }
  final customerBalances = balances.values.toList()
    ..sort(
      (a, b) => b.outstanding.compareTo(a.outstanding) != 0
          ? b.outstanding.compareTo(a.outstanding)
          : a.name.compareTo(b.name),
    );

  // Transaction history: balances run over each customer's whole history so
  // they stay true, then the entries are narrowed by date and khata status.
  final statusByKhata = {for (final k in khatas) k.id: paymentStatusOf(k)};
  final khatasByCustomer = <String, List<Khata>>{};
  for (final k in khatas) {
    if (filter.customerId != null && k.customerId != filter.customerId)
      continue;
    khatasByCustomer.putIfAbsent(k.customerId, () => []).add(k);
  }
  final ledgers = <CustomerLedger>[];
  for (final e in khatasByCustomer.entries) {
    final entries = buildCustomerLedger(e.value)
        .where(
          (x) =>
              inRange(x.date) &&
              x.khataIds.any(
                (id) => filter.statuses.contains(statusByKhata[id]),
              ),
        )
        .toList();
    if (entries.isEmpty) continue;
    final c = byId[e.key];
    ledgers.add(
      CustomerLedger(
        customerId: e.key,
        name: c?.name ?? e.value.first.customerName,
        phone: c?.phone ?? '',
        entries: entries,
        days: summarizeByDay(entries),
      ),
    );
  }
  ledgers.sort((a, b) => a.name.compareTo(b.name));

  return KhataReport(
    business: business,
    filter: filter,
    generatedAt: now ?? DateTime.now(),
    transactions: transactions,
    customerBalances: customerBalances,
    ledgers: ledgers,
    customer: customer,
  );
}

/// "Rs. 1,234" (fractions only when present). Used by the PDF and the screen.
String rs(num n) {
  final whole = n == n.roundToDouble();
  return 'Rs. ${NumberFormat(whole ? '#,##0' : '#,##0.##').format(n)}';
}

String qtyUnit(KhataLineItem l) => '${formatQuantity(l.quantity)} ${l.unit}';

/// "14 Oct 2026, 3:42 PM" in shop time.
String stampOf(DateTime d) => AppLocale.translator.dateTime(d);
String timeOf(DateTime d) => AppLocale.translator.time(d);

/// "Wed 14 Oct 2026".
String dayLabel(DateTime d) => AppLocale.translator.dayHeading(d);

String entryTitle(LedgerEntry e) => e.isPurchase
    ? tr('Purchase')
    : (e.withPurchase ? tr('Paid with purchase') : tr('Payment'));

/// One line describing an entry's items (purchases) or amount (payments).
String entryDetails(LedgerEntry e) => e.isPurchase
    ? [
        ...e.lines.map(
          (l) =>
              '${l.name} (${qtyUnit(l)} × ${rs(l.price)} = ${rs(l.lineTotal)})',
        ),
        if (e.discount > 0) tr('Discount − ${rs(e.discount)}'),
      ].join('; ')
    : tr('Received ${rs(e.received)}');

/// "1 purchase" / "3 purchases" in the language in force.
String purchasesLabel(int n) => tr(n == 1 ? '1 purchase' : '$n purchases');
String paymentsLabel(int n) => tr(n == 1 ? '1 payment' : '$n payments');

/// "Cash" / "Online" in the language in force, or null when not recorded.
String? methodLabel(String? method) => switch (method) {
  'cash' => tr('Cash'),
  'online' => tr('Online'),
  _ => null,
};
