import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Initials avatar. `solid: true` renders the brand-green filled variant
/// used for the business avatar in headers; the default is the soft
/// brand-100 variant used for customers.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool solid;

  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: solid ? AppGradients.brand : AppGradients.soft,
        borderRadius: BorderRadius.circular(
          size >= 40 ? AppRadius.r14 : AppRadius.r10,
        ),
      ),
      child: Text(
        initials,
        style: AppTypography.text(
          size: size >= 40 ? 14 : 12,
          weight: FontWeight.w700,
          color: solid ? AppColors.paper : AppColors.brand700,
        ),
      ),
    );
  }
}
