import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Frosted surface: one blur per surface, white tint, edge light and a soft
/// green shadow. Used for every card, section and list container.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color tint;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = AppRadius.r22,
    this.padding = EdgeInsets.zero,
    this.tint = AppColors.glassWhite,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tint,
              borderRadius: shape,
              border: Border.all(color: AppColors.glassEdge),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// The paper background with soft aurora blobs at the corners. Static, so
/// screens never sit on a flat colour.
class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.paper),
        Positioned(
          top: -90,
          left: -70,
          child: _blob(260, AppColors.auroraMint),
        ),
        Positioned(
          top: 180,
          right: -110,
          child: _blob(240, AppColors.auroraAmber),
        ),
        Positioned(
          bottom: 40,
          left: -60,
          child: _blob(200, AppColors.auroraSage),
        ),
        child,
      ],
    );
  }

  static Widget _blob(double size, Color color) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
