import 'package:flutter/material.dart';

import '../l10n/translator.dart';
import '../models/item.dart';
import '../models/khata_filters.dart';
import '../models/ledger.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'badges.dart';
import 'buttons.dart';
import '../reports/khata_report.dart' show methodLabel;
import 'cards.dart';
import 'glass.dart';

/// Purchases and payments grouped by day (newest day first). Inside a day the
/// oldest entry comes first, so the "balance now" figures read top to bottom
/// as a running balance. Days load in pages.
class TransactionHistory extends StatefulWidget {
  /// Oldest-first ledger entries already narrowed by date. Balances cover the
  /// full history, and each day's summary counts all of that day's entries,
  /// so the type filter below never makes a day's totals wrong.
  final List<LedgerEntry> entries;

  /// Show only these kinds of entries; empty shows both.
  final Set<EntryKind> kinds;

  /// Days shown at first and each time "show older days" is tapped.
  final int pageDays;

  const TransactionHistory({
    super.key,
    required this.entries,
    this.kinds = const {},
    this.pageDays = 14,
  });

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  int _shownDays = 0;

  int get _page => widget.pageDays;

  bool _wanted(LedgerEntry e) =>
      widget.kinds.isEmpty ||
      widget.kinds.contains(
        e.isPurchase ? EntryKind.purchase : EntryKind.payment,
      );

  @override
  Widget build(BuildContext context) {
    final days = summarizeByDay(widget.entries).reversed.toList();
    final byDay = <DateTime, List<LedgerEntry>>{};
    for (final e in widget.entries) {
      byDay.putIfAbsent(dayOf(e.date), () => []).add(e);
    }
    final visibleDays = [
      for (final d in days)
        if (byDay[d.day]!.any(_wanted)) d,
    ];
    final limit = _shownDays == 0 ? _page : _shownDays;
    final shown = visibleDays.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                context.tr(
                  widget.entries.isEmpty
                      ? 'No entries yet'
                      : 'No entries for this filter',
                ),
                style: AppTypography.meta,
              ),
            ),
          ),
        for (final d in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DayCard(
              summary: d,
              entries: byDay[d.day]!.where(_wanted).toList(),
            ),
          ),
        if (visibleDays.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SecondaryButton(
              label: context.tr('Show older days'),
              onTap: () => setState(() => _shownDays = limit + _page),
            ),
          ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final DaySummary summary;

  /// Oldest first.
  final List<LedgerEntry> entries;
  const _DayCard({required this.summary, required this.entries});

  @override
  Widget build(BuildContext context) {
    final counts = [
      if (summary.purchaseCount > 0)
        context.tr(
          summary.purchaseCount == 1
              ? '1 purchase'
              : '${summary.purchaseCount} purchases',
        ),
      if (summary.paymentCount > 0)
        context.tr(
          summary.paymentCount == 1
              ? '1 payment'
              : '${summary.paymentCount} payments',
        ),
    ].join(' · ');
    final closing = summary.closingBalance > 0
        ? formatMoney(summary.closingBalance)
        : context.tr('Clear');
    return GlassCard(
      radius: AppRadius.r18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              context.translator.dayHeading(summary.day),
              style: AppTypography.text(size: 16, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            counts,
            style: AppTypography.text(size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                if (summary.purchaseCount > 0)
                  _mini(
                    context.tr('Bought'),
                    formatMoney(summary.purchased),
                    AppColors.due,
                  ),
                if (summary.paymentCount > 0)
                  _mini(
                    context.tr('Paid'),
                    formatMoney(summary.received),
                    AppColors.brand700,
                  ),
                _mini(
                  context.tr('End of day'),
                  closing,
                  summary.closingBalance > 0
                      ? AppColors.ink
                      : AppColors.brand700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            entries[i].isPurchase
                ? PurchaseTile(entry: entries[i])
                : PaymentTile(entry: entries[i]),
          ],
        ],
      ),
    );
  }

  Widget _mini(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppTypography.text(size: 12, color: AppColors.muted)),
      Text(
        value,
        style: AppTypography.text(
          size: 14,
          weight: FontWeight.w700,
          color: color,
          tabular: true,
        ),
      ),
    ],
  );
}

/// Shared frame of a transaction: icon + title + time on one side, the
/// amount on the other, then the balance now.
class _TileFrame extends StatelessWidget {
  final AppIconGlyph icon;
  final Color accent;
  final Color accentSoft;
  final String title;
  final String time;
  final String amount;
  final Color amountColor;
  final List<Widget> body;

  const _TileFrame({
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.time,
    required this.amount,
    required this.amountColor,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MergeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: accentSoft,
                              borderRadius: BorderRadius.circular(
                                AppRadius.r12,
                              ),
                            ),
                            child: Center(
                              child: AppIcon(icon, size: 20, color: accent),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTypography.text(
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  time,
                                  style: AppTypography.text(
                                    size: 13,
                                    color: AppColors.muted,
                                    tabular: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            amount,
                            style: AppTypography.text(
                              size: 18,
                              weight: FontWeight.w700,
                              color: amountColor,
                              tabular: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...body,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A money-received entry: compact, no item details.
class PaymentTile extends StatelessWidget {
  final LedgerEntry entry;
  const PaymentTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      icon: AppIconGlyph.wallet,
      accent: AppColors.brand700,
      accentSoft: AppColors.brand100,
      title: context.tr(
        entry.withPurchase ? 'Paid with purchase' : 'Payment received',
      ),
      time: formatTime(entry.date),
      amount: '+ ${formatMoney(entry.received)}',
      amountColor: AppColors.brand700,
      body: [
        if (entry.method != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Payment method'),
                  style: AppTypography.text(size: 13, color: AppColors.muted),
                ),
              ),
              Text(
                methodLabel(entry.method)!,
                style: AppTypography.text(size: 13, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A purchase: total, then each item with quantity, unit, price and line
/// total. Purchases with many items start collapsed.
class PurchaseTile extends StatefulWidget {
  final LedgerEntry entry;

  /// Items shown before the rest are folded away.
  static const collapsedItems = 3;

  const PurchaseTile({super.key, required this.entry});

  @override
  State<PurchaseTile> createState() => _PurchaseTileState();
}

class _PurchaseTileState extends State<PurchaseTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final folded = e.lines.length > PurchaseTile.collapsedItems;
    final lines = folded && !_expanded
        ? e.lines.take(PurchaseTile.collapsedItems).toList()
        : e.lines;
    return _TileFrame(
      icon: AppIconGlyph.bag,
      accent: AppColors.due,
      accentSoft: AppColors.dueSoft,
      title: context.tr('Purchase'),
      time: formatTime(e.date),
      amount: formatMoney(e.net),
      amountColor: AppColors.ink,
      body: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < lines.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: AppColors.divider),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lines[i].name,
                              style: AppTypography.text(
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${formatQuantity(lines[i].quantity)} ${lines[i].unit} × ${formatMoney(lines[i].price)} ${context.tr('each')}',
                              style: AppTypography.text(
                                size: 13,
                                color: AppColors.muted,
                                tabular: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoney(lines[i].lineTotal),
                        style: AppTypography.text(
                          size: 14,
                          weight: FontWeight.w600,
                          tabular: true,
                        ),
                      ),
                    ],
                  ),
                ),
              if (folded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextLinkButton(
                      label: _expanded
                          ? context.tr('Show fewer')
                          : context.tr('Show all ${e.lines.length} items'),
                      onTap: () => setState(() => _expanded = !_expanded),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (e.discount > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Discount'),
                  style: AppTypography.text(size: 13, color: AppColors.muted),
                ),
              ),
              Text(
                '− ${formatMoney(e.discount)}',
                style: AppTypography.text(
                  size: 13,
                  weight: FontWeight.w600,
                  tabular: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
