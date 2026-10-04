import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Ledger design language — type scale.
/// Display family: Bricolage Grotesque (amounts & titles).
/// Text family: Instrument Sans (everything else).
/// Mono family: JetBrains Mono (labels, meta, eyebrow text).
class AppTypography {
  AppTypography._();

  // The browser's `line-height: normal` for each family (hhea ascent + descent
  // over units-per-em), so text blocks are exactly as tall as in the design.
  static const _instrumentNormalLineHeight = 1.22;
  static const _bricolageNormalLineHeight = 1.2;

  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = -0.02,
    double? height,
    Color color = AppColors.ink,
    bool tabular = false,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: size * letterSpacing,
      height: height ?? _bricolageNormalLineHeight,
      color: color,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color color = AppColors.ink,
    bool tabular = false,
  }) {
    return GoogleFonts.instrumentSans(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height ?? _instrumentNormalLineHeight,
      color: color,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.brand700,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // Named scale from the DS foundations page.
  static TextStyle get displayXl => display(
    size: 44,
    weight: FontWeight.w700,
    letterSpacing: -0.025,
    height: 46 / 44,
  );
  static TextStyle get title =>
      display(size: 30, weight: FontWeight.w700, height: 33 / 30);
  static TextStyle get amountL =>
      display(size: 28, weight: FontWeight.w700, letterSpacing: -0.01);
  static TextStyle get titleS =>
      display(size: 22, weight: FontWeight.w700, letterSpacing: -0.01);
  static TextStyle get heading => text(size: 17, weight: FontWeight.w700);
  static TextStyle get bodyStrong => text(size: 15, weight: FontWeight.w600);
  static TextStyle get body => text(size: 16, weight: FontWeight.w400);
  static TextStyle get label =>
      text(size: 13, weight: FontWeight.w600, color: AppColors.ink2);
  static TextStyle get meta =>
      text(size: 13, weight: FontWeight.w400, color: AppColors.muted);
  static TextStyle get caption =>
      text(size: 12, weight: FontWeight.w700, color: AppColors.muted);
  static TextStyle get tab => text(size: 11, weight: FontWeight.w700);

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: displayXl,
      headlineMedium: title,
      headlineSmall: titleS,
      titleMedium: heading,
      titleSmall: bodyStrong,
      bodyLarge: body,
      bodyMedium: text(size: 15),
      bodySmall: meta,
      labelLarge: label,
      labelSmall: caption,
    );
  }
}
