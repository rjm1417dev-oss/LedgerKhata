import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'buttons.dart';

class EmptyState extends StatelessWidget {
  final AppIconGlyph icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.brand100, borderRadius: BorderRadius.circular(22)),
              child: Center(child: AppIcon(icon, size: 34, color: AppColors.brand700, strokeWidth: 1.7)),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTypography.text(size: 19, weight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.text(size: 14, height: 1.5, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButtonSmall(label: actionLabel, onTap: onAction, icon: AppIconGlyph.add),
          ],
        ),
      ),
    );
  }
}
