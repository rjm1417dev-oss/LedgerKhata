import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

class _ErrorLine extends StatelessWidget {
  final String? error;
  const _ErrorLine(this.error);

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIconGlyph.error, size: 16, color: AppColors.error, strokeWidth: 2),
          const SizedBox(width: 6),
          Flexible(
            child: Text(error!, style: AppTypography.text(size: 13, weight: FontWeight.w500, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      borderSide: BorderSide(color: color, width: 1.5),
    );

/// A labelled text field matching the "White means writable" input spec.
class AppTextField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String? error;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? autofillHint;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.error,
    this.keyboardType,
    this.autofillHint,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    final borderColor = hasError ? AppColors.error : AppColors.borderInput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        SizedBox(
          height: AppSpacing.fieldHeight,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            onChanged: onChanged,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: placeholder,
              enabledBorder: _border(borderColor),
              border: _border(borderColor),
              focusedBorder: _border(hasError ? AppColors.error : AppColors.brand700),
            ),
          ),
        ),
        _ErrorLine(error),
      ],
    );
  }
}

/// Money field: "Rs" prefix, right-aligned tabular numerals, digits only.
class MoneyField extends StatelessWidget {
  final String label;
  final String? error;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const MoneyField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    final borderColor = hasError ? AppColors.error : AppColors.borderInput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        Container(
          height: AppSpacing.fieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              Text('Rs', style: AppTypography.text(size: 15, weight: FontWeight.w600, color: AppColors.muted)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onChanged,
                  textAlign: TextAlign.right,
                  style: AppTypography.text(size: 16, weight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        _ErrorLine(error),
      ],
    );
  }
}

/// Search field with a leading search icon.
class AppSearchField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFocus;
  final String? error;

  const AppSearchField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.onChanged,
    this.onFocus,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    final borderColor = hasError ? AppColors.error : AppColors.borderInput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 8),
        Container(
          height: AppSpacing.fieldHeight,
          padding: const EdgeInsets.only(left: 14, right: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              const AppIcon(AppIconGlyph.search, size: 20, color: AppColors.muted, strokeWidth: 2),
              const SizedBox(width: 10),
              Expanded(
                child: Focus(
                  onFocusChange: (has) {
                    if (has) onFocus?.call();
                  },
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onTap: onFocus,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _ErrorLine(error),
      ],
    );
  }
}

/// Sunken, dashed, locked field for computed values (e.g. Remaining amount).
class ComputedField extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String helper;

  const ComputedField({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.readonly,
            border: Border.all(color: AppColors.borderDashed, width: 1.5, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.display(size: 28, weight: FontWeight.w700, letterSpacing: -0.01, color: valueColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.remainingChipBg, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(AppIconGlyph.readonly, size: 14, color: AppColors.mutedStrong, strokeWidth: 2.2),
                    const SizedBox(width: 6),
                    Text('Read only', style: AppTypography.text(size: 12, weight: FontWeight.w700, color: AppColors.mutedStrong)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(helper, style: AppTypography.meta),
      ],
    );
  }
}
