import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/translator.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'buttons.dart';
import 'pressable.dart';

/// Opens the language popup. Choosing a language sets it for the whole app
/// (every screen, dialog, toast and report), saves it on the device, and
/// closes the popup.
Future<void> showLanguageDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (dialogContext) => const _LanguageDialog(),
  );
}

/// The globe button shown at the right of every top bar.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButtonGhost(
      icon: AppIconGlyph.globe,
      onTap: () => showLanguageDialog(context),
      semanticLabel: 'Language',
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context) {
    final selected = context.language;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const AppIcon(
                  AppIconGlyph.globe,
                  size: 22,
                  color: AppColors.brand700,
                  strokeWidth: 2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.tr('Select language'),
                      style: AppTypography.text(
                        size: 17,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final l in AppLanguage.values) ...[
              _LanguageRow(
                language: l,
                selected: l == selected,
                onTap: () {
                  context.read<AppState>().setLanguage(l);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: language.nativeName,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.rowHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand50 : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.brand200 : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brand700
                      : AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: selected
                    ? const Center(
                        child: AppIcon(
                          AppIconGlyph.selected,
                          size: 16,
                          color: Colors.white,
                          strokeWidth: 2.6,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language.nativeName,
                  style: AppTypography.text(
                    size: 16,
                    weight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.brand700 : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
