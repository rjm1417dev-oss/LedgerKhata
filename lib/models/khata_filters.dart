import 'khata.dart';
import 'ledger.dart';

enum EntryKind { purchase, payment }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// What the shopkeeper narrowed the Khata screens down to. Every filter that
/// is set applies together (AND); a filter left empty means "everything".
class KhataFilters {
  /// Inclusive day range; either end can be left open.
  final DateTime? from;
  final DateTime? to;

  /// Purchases and/or payments. Empty means both.
  final Set<EntryKind> kinds;

  const KhataFilters({this.from, this.to, this.kinds = const {}});

  static const none = KhataFilters();

  /// A start date after the end date. The date range is ignored (not applied
  /// as "nothing matches") until it is fixed.
  bool get hasInvalidRange =>
      from != null && to != null && _day(from!).isAfter(_day(to!));

  bool get hasDate => from != null || to != null;
  bool get isActive => hasDate || kinds.isNotEmpty;

  KhataFilters copyWith({
    DateTime? from,
    DateTime? to,
    Set<EntryKind>? kinds,
    bool clearFrom = false,
    bool clearTo = false,
  }) => KhataFilters(
    from: clearFrom ? null : (from ?? this.from),
    to: clearTo ? null : (to ?? this.to),
    kinds: kinds ?? this.kinds,
  );

  /// Quick pick: the whole of [month].
  KhataFilters forMonth(DateTime month) => copyWith(
    from: DateTime(month.year, month.month, 1),
    to: DateTime(month.year, month.month + 1, 0),
  );

  /// True when the date range is exactly one whole calendar month.
  bool isMonth(DateTime month) =>
      from != null &&
      to != null &&
      _day(from!) == DateTime(month.year, month.month, 1) &&
      _day(to!) == DateTime(month.year, month.month + 1, 0);

  bool matchesDate(DateTime d) {
    if (!hasDate || hasInvalidRange) return true;
    final day = _day(d);
    if (from != null && day.isBefore(_day(from!))) return false;
    if (to != null && day.isAfter(_day(to!))) return false;
    return true;
  }

  /// A purchase or payment in the customer's history.
  bool matchesEntry(LedgerEntry e) {
    if (!matchesDate(e.date)) return false;
    if (kinds.isEmpty) return true;
    return kinds.contains(
      e.isPurchase ? EntryKind.purchase : EntryKind.payment,
    );
  }

  /// A khata cycle: it matches when it was opened, or had any purchase or
  /// payment, inside the date range (the same idea as the old month filter).
  bool matchesKhata(Khata k) {
    if (!hasDate || hasInvalidRange) return true;
    return matchesDate(k.date) ||
        k.items.any((i) => matchesDate(i.date)) ||
        k.payments.any((p) => matchesDate(p.date));
  }
}
