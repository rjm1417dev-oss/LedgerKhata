import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

class DueBadge extends StatelessWidget {
  final String text;
  const DueBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.dueSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(text, style: AppTypography.text(size: 13, weight: FontWeight.w700, color: AppColors.due, tabular: true)),
    );
  }
}

class SettledBadge extends StatelessWidget {
  const SettledBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.brand100, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(AppIconGlyph.selected, size: 14, color: AppColors.brand700, strokeWidth: 2.4),
          const SizedBox(width: 4),
          Text('Settled', style: AppTypography.text(size: 13, weight: FontWeight.w700, color: AppColors.brand700)),
        ],
      ),
    );
  }
}

class CountChip extends StatelessWidget {
  final String text;
  const CountChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(text, style: AppTypography.text(size: 12, weight: FontWeight.w700, color: AppColors.ink2)),
    );
  }
}
