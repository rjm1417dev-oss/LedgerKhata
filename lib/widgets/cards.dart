import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/khata.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'avatar.dart';
import 'badges.dart';
import 'app_icon.dart';
import 'glass.dart';

String formatMoney(num n) => 'Rs ${NumberFormat('#,###').format(n.round())}';
String formatSignedMoney(num n) =>
    n < 0 ? '−${formatMoney(-n)}' : formatMoney(n);
String formatDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

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
                    '${formatDate(khata.date)} · ${khata.items.length} item${khata.items.length == 1 ? '' : 's'}',
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
                  _totalLine('Total', formatMoney(khata.total)),
                  _totalLine('Discount', formatMoney(khata.discount)),
                  _totalLine('Paid', formatMoney(khata.paid)),
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

  Widget _totalLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
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
                'Total remaining',
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
                'Pending on $pendingCount of $totalKhatas khatas',
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
        Text(
          label,
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
          Text(label, style: AppTypography.meta),
        ],
      ),
    );
  }
}
