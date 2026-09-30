import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// Full-width primary action. One per screen per the design language.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final String loadingLabel;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.loadingLabel = 'Saving\u2026',
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onTap == null;
    return Pressable(
      onTap: disabled ? null : onTap,
      child: Container(
        height: AppSpacing.primaryActionHeight,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brand700.withValues(alpha: disabled && !loading ? 0.5 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(loadingLabel, style: AppTypography.text(size: 16, weight: FontWeight.w700, color: Colors.white)),
                ],
              )
            : Text(label, style: AppTypography.text(size: 16, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

/// Outlined secondary action (Cancel, etc).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SecondaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderInput, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: AppTypography.text(size: 15, weight: FontWeight.w700)),
      ),
    );
  }
}

/// Full-width destructive action, e.g. the confirm dialog's "Delete" button
/// and any other button that ends a session or removes data outright.
class DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const DestructiveButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: AppTypography.text(size: 15, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

/// Small pill primary button with a leading icon, e.g. "New Khata".
class PrimaryButtonSmall extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppIconGlyph icon;

  const PrimaryButtonSmall({super.key, required this.label, required this.onTap, this.icon = AppIconGlyph.add});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.only(left: 12, right: 16),
        decoration: BoxDecoration(color: AppColors.brand700, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 18, color: Colors.white, strokeWidth: 2.2),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.text(size: 14, weight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Soft-filled icon button (brand-100 bg, brand-700 icon) e.g. the inline
/// "add customer" affordance next to a picker.
class IconButtonSoft extends StatelessWidget {
  final AppIconGlyph icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;

  const IconButtonSoft({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.brand100,
            border: Border.all(color: AppColors.brand200, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: AppIcon(icon, size: 22, color: AppColors.brand700, strokeWidth: 2.4)),
        ),
      ),
    );
  }
}

/// Ghost / sunken icon button, e.g. back and close affordances. [color] and
/// [backgroundColor] override the default ink-on-transparent/sunken look,
/// e.g. for a colored delete or edit affordance.
class IconButtonGhost extends StatelessWidget {
  final AppIconGlyph icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool sunken;
  final Color? color;
  final Color? backgroundColor;

  const IconButtonGhost({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.sunken = false,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor ?? (sunken ? AppColors.surfaceSunken : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: AppIcon(icon, size: sunken ? 20 : 24, color: color ?? AppColors.ink2, strokeWidth: 2)),
        ),
      ),
    );
  }
}

class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const TextLinkButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchMin),
        alignment: Alignment.centerLeft,
        child: Text(label, style: AppTypography.text(size: 14, weight: FontWeight.w700, color: AppColors.brand700)),
      ),
    );
  }
}
