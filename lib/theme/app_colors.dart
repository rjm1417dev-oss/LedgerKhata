import 'package:flutter/material.dart';

/// Khata design language v2.0 ("Glass") — colour tokens.
/// Warm paper under a soft aurora, one deep ledger green, and meaning colours
/// used sparingly. Every pair is checked on glass, not just on white.
class AppColors {
  AppColors._();

  // Brand
  static const brand800 = Color(0xFF0A4533);
  static const brand700 = Color(0xFF0E5C45);
  static const brand600 = Color(0xFF177B5E);
  static const brand200 = Color(0xFFBFDCCF);
  static const brand100 = Color(0xFFE3F0EA);
  static const brand50 = Color(0xFFF1F8F4);
  static const onBrand = Color(0xFFCDE8DC);

  // Surfaces & lines
  static const paper = Color(0xFFF3F1EA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFFAF9F5);

  /// Writable input well: near-opaque glass so typed text always reads.
  static const inputFill = Color(0xE6FFFFFF);
  static const surfaceSunken = Color(0xFFF1EEE6);
  static const readonly = Color(0xFFE8E5DD);
  static const line = Color(0xFFE4E0D6);
  static const divider = Color(0xFFEEEBE3);
  static const borderInput = Color(0xFFD6D1C4);
  static const borderControl = Color(0xFFB9B4A7);
  static const borderDashed = Color(0xFFCFCABD);

  // Text & meaning
  static const ink = Color(0xFF16181D);
  static const ink2 = Color(0xFF2B2F36);
  static const muted = Color(0xFF4F5562);
  static const mutedStrong = Color(0xFF3F4450);
  static const placeholder = Color(0xFF8A8F98);
  static const chevron = Color(0xFF6B717C);
  static const due = Color(0xFF8A3F0B);
  static const dueSoft = Color(0xFFFBEEDD);
  static const error = Color(0xFFB42318);
  static const errorSoft = Color(0xFFFBEAE8);

  /// Scrim behind every bottom sheet: rgba(16,32,26,.34).
  static const scrim = Color(0x5710201A);

  // Atmosphere (aurora blobs, blurred behind glass only)
  static const auroraMint = Color(0xFFBFE3D2);
  static const auroraSage = Color(0xFFCBE7DA);
  static const auroraAmber = Color(0xFFF5DCC0);
  static const auroraMist = Color(0xFFDDEFE5);

  // Glass tints
  static const glassWhite = Color(0x9EFFFFFF); // white 62%
  static const glassEdge = Color(0xC7FFFFFF); // white 78%
  static const glassPop = Color(0xDBFFFFFF); // white 86%
  static const glassShadow = Color(0x140E5C45); // brand green 8%

  // Misc
  static const remainingChipBg = Color(0xFFE2DFD6);
  static const sheetGrabber = Color(0xFFDAD6CB);
  static const successCheck = Color(0xFF6FD3A6);
}

/// Gradients from the design system: the brand gradient is the one thing to
/// press (primary buttons, active tab); the hero uses the same green ramp.
class AppGradients {
  AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand600, AppColors.brand700, AppColors.brand800],
    stops: [0, 0.55, 1],
  );

  static const soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand100, AppColors.auroraMist],
  );
}
