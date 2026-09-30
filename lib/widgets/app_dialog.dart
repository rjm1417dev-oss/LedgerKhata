import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';

Widget _card(Widget child) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.r18)),
      child: child,
    );

/// Destructive-action confirmation, e.g. "Delete Sugar?". Returns true only
/// when the confirm button was tapped.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: _card(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.text(size: 17, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, style: AppTypography.text(size: 14, color: AppColors.muted)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: SecondaryButton(label: cancelLabel, onTap: () => Navigator.of(dialogContext).pop(false))),
                const SizedBox(width: 10),
                Expanded(child: DestructiveButton(label: confirmLabel, onTap: () => Navigator.of(dialogContext).pop(true))),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Single-button informational dialog, e.g. explaining why a delete is blocked.
Future<void> showAppAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String okLabel = 'OK',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: _card(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.text(size: 17, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, style: AppTypography.text(size: 14, color: AppColors.muted)),
            const SizedBox(height: 20),
            PrimaryButton(label: okLabel, onTap: () => Navigator.of(dialogContext).pop()),
          ],
        ),
      ),
    ),
  );
}
