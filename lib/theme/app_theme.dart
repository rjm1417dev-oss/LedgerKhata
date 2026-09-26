import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Elevation shadows from the DS foundations page (e0 flat is just a border).
class AppShadows {
  AppShadows._();

  static const raised = [
    BoxShadow(color: Color(0x14161816), blurRadius: 28, offset: Offset(0, 10)),
  ]; // e1 · 0 10 28 / 8%

  static const floating = [
    BoxShadow(color: Color(0x40161816), blurRadius: 32, offset: Offset(0, 12)),
  ]; // e2 · 0 12 32 / 25%

  static const sheet = [
    BoxShadow(color: Color(0x2E161816), blurRadius: 40, offset: Offset(0, -12)),
  ]; // e3 · 0 -12 40 / 18%
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final colorScheme = base.colorScheme.copyWith(
    primary: AppColors.brand700,
    onPrimary: AppColors.surface,
    secondary: AppColors.brand700,
    surface: AppColors.surface,
    error: AppColors.error,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: AppTypography.textTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
    ),
    iconTheme: const IconThemeData(color: AppColors.ink),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand700,
        foregroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(AppSpacing.primaryActionHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        textStyle: AppTypography.text(size: 16, weight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.borderInput, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        textStyle: AppTypography.text(size: 15, weight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      hintStyle: AppTypography.body.copyWith(color: AppColors.placeholder),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.borderInput, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.borderInput, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.brand700, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
  );
}
