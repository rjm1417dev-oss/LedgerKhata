import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'pressable.dart';

class DueBadge extends StatelessWidget {
  final String text;
  const DueBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.dueSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTypography.text(
          size: 13,
          weight: FontWeight.w700,
          color: AppColors.due,
          tabular: true,
        ),
      ),
    );
  }
}

class SettledBadge extends StatelessWidget {
  const SettledBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            AppIconGlyph.selected,
            size: 14,
            color: AppColors.brand700,
            strokeWidth: 2.4,
          ),
          const SizedBox(width: 4),
          Text(
            'Settled',
            style: AppTypography.text(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.brand700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable pill used for the month filter row — brand-700 fill when
/// active, outlined otherwise, matching the chip/badge pill token.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand700 : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.brand700 : AppColors.borderInput,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTypography.text(
            size: 13,
            weight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

/// Horizontally-scrolling row of month chips ("All time" + one per month
/// that has activity), newest first.
class MonthFilterBar extends StatelessWidget {
  final List<DateTime> months;
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const MonthFilterBar({
    super.key,
    required this.months,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (months.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length + 1,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return AppFilterChip(
              label: 'All time',
              selected: selected == null,
              onTap: () => onChanged(null),
            );
          }
          final month = months[i - 1];
          return AppFilterChip(
            label: _monthLabel(month),
            selected:
                selected != null &&
                selected!.year == month.year &&
                selected!.month == month.month,
            onTap: () => onChanged(month),
          );
        },
      ),
    );
  }

  static const _names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec', //
  ];

  String _monthLabel(DateTime month) =>
      '${_names[month.month - 1]} ${month.year}';
}

class CountChip extends StatelessWidget {
  final String text;
  const CountChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTypography.text(
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}
