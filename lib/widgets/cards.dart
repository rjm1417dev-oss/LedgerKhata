import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/khata.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'avatar.dart';
import 'badges.dart';
import 'app_icon.dart';
import 'buttons.dart';

String formatMoney(num n) => 'Rs ${NumberFormat('#,###').format(n.round())}';
String formatSignedMoney(num n) => n < 0 ? '−${formatMoney(-n)}' : formatMoney(n);
String formatDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

/// Khata summary card. Settled khatas collapse to a compact header row;
/// khatas with a balance due show the item summary and total/discount/paid
/// breakdown, per the DS "Khata card" spec.
class KhataCard extends StatelessWidget {
  final Khata khata;
  final VoidCallback? onTap;

  /// Header row only (avatar, name, date, badge), as on the dashboard.
  final bool compact;

  /// Shows a "Record payment" action for a due (unsettled) khata.
  final VoidCallback? onRecordPayment;

  const KhataCard({super.key, required this.khata, this.onTap, this.compact = false, this.onRecordPayment});

  @override
  Widget build(BuildContext context) {
    final settled = khata.isSettled;
    final showDetails = !settled && !compact;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        padding: EdgeInsets.all(settled ? 14 : 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InitialsAvatar(initials: khata.customerInitials, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(khata.customerName, style: AppTypography.text(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${formatDate(khata.date)} · ${khata.items.length} item${khata.items.length == 1 ? '' : 's'}',
                        style: AppTypography.meta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                settled ? const SettledBadge() : DueBadge('${formatMoney(khata.remaining)} due'),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 12),
              Text(
                khata.itemsSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.meta,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line, width: 1, style: BorderStyle.solid)),
                ),
                child: Row(
                  children: [
                    _totalCell('Total', formatMoney(khata.total)),
                    _totalCell('Discount', formatMoney(khata.discount)),
                    _totalCell('Paid', formatMoney(khata.paid)),
                  ],
                ),
              ),
              if (onRecordPayment != null) ...[
                const SizedBox(height: 12),
                PrimaryButtonSmall(label: 'Record payment', icon: AppIconGlyph.add, onTap: onRecordPayment),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _totalCell(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.text(size: 12, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.text(size: 14, weight: FontWeight.w600, tabular: true)),
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

  const BalanceHero({
    super.key,
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
      decoration: BoxDecoration(color: AppColors.brand700, borderRadius: BorderRadius.circular(AppRadius.r22)),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RuledPagePainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total remaining', style: AppTypography.text(size: 13, weight: FontWeight.w600, color: AppColors.onBrand)),
              const SizedBox(height: 4),
              Text(
                formatMoney(totalRemaining),
                style: AppTypography.display(size: 42, weight: FontWeight.w700, letterSpacing: -0.02, height: 1.1, color: AppColors.paper, tabular: true),
              ),
              const SizedBox(height: 4),
              Text(
                'Pending on $pendingCount of $totalKhatas khatas',
                style: AppTypography.text(size: 13, color: const Color(0xFFD5EAE1)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x33F6F4EE), width: 1)),
                ),
                child: Row(
                  children: [
                    _stat('Total billed', formatMoney(totalBilled)),
                    _stat('Discount', formatMoney(totalDiscount)),
                    _stat('Received', formatMoney(totalReceived)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.text(size: 12, color: AppColors.onBrand)),
            const SizedBox(height: 3),
            Text(value, style: AppTypography.text(size: 15, weight: FontWeight.w700, color: AppColors.paper, tabular: true)),
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

  const StatTile({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.r10)),
            child: Center(child: AppIcon(icon, size: 18, color: AppColors.ink2, strokeWidth: 1.9)),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.display(size: 26, weight: FontWeight.w700, height: 1.1, tabular: true)),
          Text(label, style: AppTypography.meta),
        ],
      ),
    );
  }
}
