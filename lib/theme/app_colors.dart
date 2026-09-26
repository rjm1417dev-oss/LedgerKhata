import 'package:flutter/material.dart';

/// Ledger design language — color tokens.
/// Source: Khata design system (brand-700 green on warm paper).
class AppColors {
  AppColors._();

  // Brand
  static const brand700 = Color(0xFF0E5C45);
  static const brand800 = Color(0xFF0A4533);
  static const brand200 = Color(0xFFBFDCCF);
  static const brand100 = Color(0xFFE3F0EA);
  static const brand50 = Color(0xFFF1F8F4);
  static const onBrand = Color(0xFFBFE0D2);

  // Surfaces
  static const paper = Color(0xFFF6F4EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFFAF9F5);
  static const surfaceSunken = Color(0xFFF1EEE6);
  static const readonly = Color(0xFFEFEDE7);

  // Lines
  static const line = Color(0xFFE4E0D6);
  static const divider = Color(0xFFEEEBE3);
  static const borderInput = Color(0xFFD6D1C4);
  static const borderControl = Color(0xFFB9B4A7);
  static const borderDashed = Color(0xFFCFCABD);

  // Text
  static const ink = Color(0xFF16181D);
  static const ink2 = Color(0xFF2B2F36);
  static const muted = Color(0xFF5E6470);
  static const mutedStrong = Color(0xFF4A4F58);
  static const placeholder = Color(0xFF8A8F98);
  static const chevron = Color(0xFF6B717C);

  // Meaning
  static const due = Color(0xFF8A3F0B);
  static const dueSoft = Color(0xFFFBEEDD);
  static const error = Color(0xFFB42318);
  static const scrim = Color(0x7A121614); // rgba(18,22,20,.48)

  // Misc
  static const remainingChipBg = Color(0xFFE2DFD6);
  static const sheetGrabber = Color(0xFFDAD6CB);
  static const successCheck = Color(0xFF6FD3A6);
}
