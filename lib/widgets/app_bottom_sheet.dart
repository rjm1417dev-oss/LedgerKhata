import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';
import 'app_icon.dart';

/// Bottom sheet chrome matching the DS "Overlays" spec: grabber, title row
/// with a close button, scrim, and rounded top corners.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.r28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              decoration: const BoxDecoration(
                color: AppColors.glassPop,
                border: Border(top: BorderSide(color: AppColors.glassEdge)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.sheetGrabber,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: AppTypography.titleS),
                      IconButtonGhost(
                        icon: AppIconGlyph.close,
                        onTap: () => Navigator.of(context).pop(),
                        semanticLabel: 'Close',
                        sunken: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  builder(context),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
