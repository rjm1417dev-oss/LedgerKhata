import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// A +/- stepper with an editable quantity field in the middle, used when
/// picking how many units of an item go into a khata line.
class QuantityStepper extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final ValueChanged<double> onChanged;

  const QuantityStepper({super.key, required this.controller, required this.unit, required this.onChanged});

  void _step(double delta) {
    final current = double.tryParse(controller.text) ?? 0;
    final next = (current + delta).clamp(0.001, 999999.0);
    final text = next == next.roundToDouble() ? next.toStringAsFixed(0) : next.toString();
    controller.text = text;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepButton(AppIconGlyph.remove, () => _step(-1)),
        const SizedBox(width: 6),
        SizedBox(
          width: 56,
          height: 36,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            style: AppTypography.text(size: 14, weight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r10), borderSide: const BorderSide(color: AppColors.borderInput)),
            ),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
          ),
        ),
        const SizedBox(width: 6),
        Text(unit, style: AppTypography.text(size: 13, weight: FontWeight.w600, color: AppColors.muted)),
        const SizedBox(width: 6),
        _stepButton(AppIconGlyph.add, () => _step(1)),
      ],
    );
  }

  Widget _stepButton(AppIconGlyph icon, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.r10)),
          child: Center(child: AppIcon(icon, size: 14, color: AppColors.ink2, strokeWidth: 2.4)),
        ),
      );
}
