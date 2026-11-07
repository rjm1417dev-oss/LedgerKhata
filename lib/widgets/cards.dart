import '../l10n/translator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/item.dart';
import '../models/khata.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'avatar.dart';
import 'badges.dart';
import 'buttons.dart';
import 'app_icon.dart';
import 'glass.dart';

String formatMoney(num n) => 'Rs ${NumberFormat('#,###').format(n.round())}';
String formatSignedMoney(num n) =>
    n < 0 ? '−${formatMoney(-n)}' : formatMoney(n);
String formatDate(DateTime d) => AppLocale.translator.date(d);

/// Time of day (already shop time, see shop_time.dart), e.g. "3:42 PM".
String formatTime(DateTime d) => AppLocale.translator.time(d);
String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatTime(d)}';

/// Khata summary card. Settled khatas collapse to a compact header row;
/// khatas with a balance due show the item summary and total/discount/paid
/// breakdown on the right. The dashboard uses [compact] for header-only rows.
class KhataCard extends StatelessWidget {
  final Khata khata;
  final VoidCallback? onTap;

  /// Header row only (avatar, name, date, badge), as on the dashboard.
  final bool compact;

  /// Shows the "Rs X due" badge on unsettled khatas.
  final bool showDueBadge;

  const KhataCard({
    super.key,
    required this.khata,
    this.onTap,
    this.compact = false,
    this.showDueBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final settled = khata.isSettled;
    final showDetails = !settled && !compact;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: GlassCard(
        radius: AppRadius.r18,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InitialsAvatar(initials: khata.customerInitials, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    khata.customerName,
                    style: AppTypography.text(
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(
                      khata.items.length == 1
                          ? '${formatDate(khata.date)} · 1 item'
                          : '${formatDate(khata.date)} · ${khata.items.length} items',
                    ),
                    style: AppTypography.meta,
                  ),
                  if (showDetails) ...[
                    const SizedBox(height: 4),
                    Text(
                      khata.itemsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.meta,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (showDetails)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _totalLine(context, 'Total', formatMoney(khata.total)),
                  _totalLine(context, 'Discount', formatMoney(khata.discount)),
                  _totalLine(context, 'Paid', formatMoney(khata.paid)),
                ],
              )
            else if (settled)
              const SettledBadge()
            else if (showDueBadge)
              DueBadge('${formatMoney(khata.remaining)} due'),
          ],
        ),
      ),
    );
  }

  Widget _totalLine(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(label),
              style: AppTypography.text(size: 12, color: AppColors.muted),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: AppTypography.text(
                size: 14,
                weight: FontWeight.w600,
                tabular: true,
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Shared ledger-entry helpers (used by KhataCycleCard)
// ---------------------------------------------------------------------------

class _LedgerEntry {
  final DateTime date;
  final String label;
  final double amount;
  const _LedgerEntry({
    required this.date,
    required this.label,
    required this.amount,
  });
}

List<_LedgerEntry> _entriesFor(Khata k) {
  final entries = [
    for (final i in k.items)
      _LedgerEntry(
        date: i.date,
        label: '${i.name} · ${formatQuantity(i.quantity)} ${i.unit}',
        amount: i.lineTotal,
      ),
  ];
  entries.sort((a, b) => a.date.compareTo(b.date));
  return entries;
}

/// A full khata cycle card — identical to the card shown on the Customer
/// Detail screen. Optionally shows the customer's name & avatar in the header
/// (set [customerName] when used on a list screen where the customer is not
/// already implied by context). Provide [onTap] to make the card tappable.
class KhataCycleCard extends StatelessWidget {
  final Khata khata;

  /// When non-null, a leading avatar + name row is shown above the date.
  final String? customerName;

  final VoidCallback? onTap;

  /// Shows the "Pending" badge on unsettled khatas.
  final bool showPendingBadge;

  /// When set, shows a WhatsApp action that sends this khata to the customer.
  final VoidCallback? onSendWhatsApp;

  const KhataCycleCard({
    super.key,
    required this.khata,
    this.customerName,
    this.onTap,
    this.showPendingBadge = true,
    this.onSendWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final settled = khata.isSettled;
    final entries = _entriesFor(khata);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r18),
      child: GlassCard(
        radius: AppRadius.r18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── optional customer row ─────────────────────────────────────
            if (customerName != null) ...[
              Row(
                children: [
                  InitialsAvatar(
                    initials: customerName!.isNotEmpty
                        ? customerName![0].toUpperCase()
                        : '?',
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    customerName!,
                    style: AppTypography.text(
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            // ── header row: date + settled / pending badge ───────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Opened ${formatDateTime(khata.date)}'),
                    style: AppTypography.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (settled)
                  const SettledBadge()
                else if (showPendingBadge)
                  const PendingBadge(),
                if (onSendWhatsApp != null) ...[
                  const SizedBox(width: 6),
                  IconButtonGhost(
                    icon: AppIconGlyph.send,
                    onTap: onSendWhatsApp,
                    semanticLabel:
                        'Send ${khata.customerName} this khata on WhatsApp',
                    color: AppColors.brand700,
                    backgroundColor: AppColors.brand100,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // ── item entries list ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _entryRow(entries[i], i != entries.length - 1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Total / Discount / Paid footer ────────────────────────────
            Row(
              children: [
                _totalCell(context, 'Total', formatMoney(khata.total)),
                _totalCell(context, 'Discount', formatMoney(khata.discount)),
                _totalCell(context, 'Paid', formatMoney(khata.paid)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryRow(_LedgerEntry e, bool showDivider) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(bottom: BorderSide(color: AppColors.divider))
          : null,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.label,
                style: AppTypography.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.ink2,
                ),
              ),
              Text(
                formatDateTime(e.date),
                style: AppTypography.text(size: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Text(
          formatMoney(e.amount),
          style: AppTypography.text(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );

  Widget _totalCell(BuildContext context, String label, String value) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(label),
              style: AppTypography.text(size: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.text(
                size: 14,
                weight: FontWeight.w600,
                tabular: true,
              ),
            ),
          ],
        ),
      );
}

/// Dashboard's remaining-balance hero card with the faint ruled-paper motif.
class BalanceHero extends StatelessWidget {
  final double totalRemaining;
  final int pendingCount;
  final int totalKhatas;
  final double totalBilled;
  final double totalDiscount;
  final double totalReceived;

  /// Heading above the amount.
  final String title;

  const BalanceHero({
    super.key,
    this.title = 'Total remaining',
    required this.totalRemaining,
    required this.pendingCount,
    required this.totalKhatas,
    required this.totalBilled,
    required this.totalDiscount,
    required this.totalReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.r28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D0E5C45),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RuledPagePainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(title),
                style: AppTypography.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.onBrand,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalRemaining),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  formatMoney(value),
                  style: AppTypography.display(
                    size: 42,
                    weight: FontWeight.w700,
                    letterSpacing: -0.02,
                    height: 1.1,
                    color: AppColors.paper,
                    tabular: true,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('Pending on $pendingCount of $totalKhatas khatas'),
                style: AppTypography.text(
                  size: 13,
                  color: const Color(0xFFD5EAE1),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0x33F6F4EE), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    _stat(context, 'Total billed', formatMoney(totalBilled)),
                    _stat(context, 'Discount', formatMoney(totalDiscount)),
                    _stat(context, 'Received', formatMoney(totalReceived)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(label),
          style: AppTypography.text(size: 12, color: AppColors.onBrand),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.text(
            size: 15,
            weight: FontWeight.w700,
            color: AppColors.paper,
            tabular: true,
          ),
        ),
      ],
    ),
  );
}

class _RuledPagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x0FF6F4EE)
      ..strokeWidth = 1;
    // repeating-linear-gradient(0deg, line 0 1px, transparent 1px 30px): the
    // rules are anchored to the bottom edge and repeat every 30px upwards.
    for (double y = size.height - 0.5; y > 0; y -= 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small dashboard stat tile (icon, big number, label).
class StatTile extends StatelessWidget {
  final AppIconGlyph icon;
  final String value;
  final String label;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.r18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Center(
              child: AppIcon(
                icon,
                size: 18,
                color: AppColors.ink2,
                strokeWidth: 1.9,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.display(
              size: 26,
              weight: FontWeight.w700,
              height: 1.1,
              tabular: true,
            ),
          ),
          Text(context.tr(label), style: AppTypography.meta),
        ],
      ),
    );
  }
}
