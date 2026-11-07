import 'package:flutter/material.dart';

import '../l10n/translator.dart';
import '../models/khata_filters.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'app_icon.dart';
import 'badges.dart';
import 'buttons.dart';
import 'cards.dart';
import 'glass.dart';
import 'pressable.dart';

/// The filters of a Khata screen, top to bottom: the date range first (with
/// a quick pick per month), then Type. Every filter that is set applies
/// together; each can be cleared on its own, or all at once.
class KhataFilterPanel extends StatelessWidget {
  final KhataFilters filters;
  final ValueChanged<KhataFilters> onChanged;

  /// Months with activity, newest first, for the quick pick.
  final List<DateTime> months;

  /// Show the Type filter (purchases / payments) — only the history has it.
  final bool showKinds;

  const KhataFilterPanel({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.months,
    this.showKinds = false,
  });

  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final now = DateTime.now();
    final current = isFrom ? filters.from : filters.to;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: context.tr(isFrom ? 'Start date' : 'End date'),
    );
    if (picked == null) return;
    onChanged(
      isFrom ? filters.copyWith(from: picked) : filters.copyWith(to: picked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = months.where(filters.isMonth).firstOrNull;
    return GlassCard(
      radius: AppRadius.r18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Filters'),
                  style: AppTypography.text(size: 16, weight: FontWeight.w700),
                ),
              ),
              if (filters.isActive)
                TextLinkButton(
                  label: 'Clear all filters',
                  onTap: () => onChanged(KhataFilters.none),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _SectionLabel('Date range'),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From',
                  value: filters.from,
                  onTap: () => _pick(context, isFrom: true),
                  onClear: () => onChanged(filters.copyWith(clearFrom: true)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  label: 'To',
                  value: filters.to,
                  onTap: () => _pick(context, isFrom: false),
                  onClear: () => onChanged(filters.copyWith(clearTo: true)),
                ),
              ),
            ],
          ),
          if (filters.hasInvalidRange)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.tr('The start date can’t be after the end date'),
                style: AppTypography.text(size: 13, color: AppColors.error),
              ),
            ),
          if (months.length > 1) ...[
            const SizedBox(height: 10),
            MonthFilterBar(
              months: months,
              selected: selectedMonth,
              allTimeSelected: !filters.hasDate,
              onChanged: (m) => onChanged(
                m == null
                    ? filters.copyWith(clearFrom: true, clearTo: true)
                    : filters.forMonth(m),
              ),
            ),
          ],
          if (showKinds) ...[
            const SizedBox(height: 14),
            _SectionLabel('Type'),
            MultiSelectField<EntryKind>(
              label: 'Type',
              options: const [
                (EntryKind.purchase, 'Purchases'),
                (EntryKind.payment, 'Payments'),
              ],
              selected: filters.kinds,
              onChanged: (k) => onChanged(filters.copyWith(kinds: k)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      context.tr(text),
      style: AppTypography.text(
        size: 13,
        weight: FontWeight.w700,
        color: AppColors.muted,
      ),
    ),
  );
}

/// A tappable date box with its own clear button.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final set = value != null;
    return Container(
      height: AppSpacing.touchMin,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        border: Border.all(color: AppColors.borderInput, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label:
                  '${context.tr(label)}: ${set ? formatDate(value!) : context.tr('Select date')}',
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.r14),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      set
                          ? '${context.tr(label)}: ${formatDate(value!)}'
                          : '${context.tr(label)}…',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.text(
                        size: 14,
                        weight: set ? FontWeight.w600 : FontWeight.w400,
                        color: set ? AppColors.ink : AppColors.chevron,
                        tabular: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (set)
            Semantics(
              button: true,
              label: context.tr(
                'Clear {label} date'.replaceFirst('{label}', context.tr(label)),
              ),
              excludeSemantics: true,
              child: InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(AppRadius.r14),
                child: const SizedBox(
                  width: AppSpacing.touchMin,
                  height: AppSpacing.touchMin,
                  child: Center(
                    child: AppIcon(
                      AppIconGlyph.close,
                      size: 16,
                      color: AppColors.muted,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// A dropdown that lets several options be ticked in one go: the list stays
/// open while options are ticked and closes with Done. Nothing ticked means
/// "everything" (shown as All).
class MultiSelectField<T> extends StatelessWidget {
  final String label;
  final List<(T, String)> options;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;

  const MultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  String _summary(BuildContext context) {
    final picked = [
      for (final (v, text) in options)
        if (selected.contains(v)) context.tr(text),
    ];
    if (picked.isEmpty) return context.tr('All');
    if (picked.length <= 2) return picked.join(', ');
    return context.tr('${picked.length} selected');
  }

  Future<void> _open(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      title: label,
      builder: (_) => _MultiSelectSheet<T>(
        options: options,
        initial: selected,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final any = selected.isNotEmpty;
    return Container(
      height: AppSpacing.touchMin,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        border: Border.all(color: AppColors.borderInput, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '${context.tr(label)}: ${_summary(context)}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => _open(context),
                borderRadius: BorderRadius.circular(AppRadius.r14),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 14, end: 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _summary(context),
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.text(
                        size: 15,
                        weight: any ? FontWeight.w600 : FontWeight.w400,
                        color: any ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (any)
            Semantics(
              button: true,
              label: context.tr(
                'Clear {label}'.replaceFirst('{label}', context.tr(label)),
              ),
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onChanged(<T>{}),
                borderRadius: BorderRadius.circular(AppRadius.r14),
                child: const SizedBox(
                  width: AppSpacing.touchMin,
                  height: AppSpacing.touchMin,
                  child: Center(
                    child: AppIcon(
                      AppIconGlyph.close,
                      size: 16,
                      color: AppColors.muted,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: AppIcon(
              AppIconGlyph.expand,
              size: 18,
              color: AppColors.muted,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectSheet<T> extends StatefulWidget {
  final List<(T, String)> options;
  final Set<T> initial;
  final ValueChanged<Set<T>> onChanged;
  const _MultiSelectSheet({
    required this.options,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late Set<T> _picked = {...widget.initial};

  void _set(Set<T> next) {
    setState(() => _picked = next);
    widget.onChanged({
      ...next,
    }); // the screen behind updates as options are ticked
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (value, text) in widget.options)
          Semantics(
            button: true,
            checked: _picked.contains(value),
            label: context.tr(text),
            excludeSemantics: true,
            child: Pressable(
              onTap: () => _set(
                _picked.contains(value)
                    ? ({..._picked}..remove(value))
                    : ({..._picked, value}),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.rowHeight,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _picked.contains(value)
                            ? AppColors.brand700
                            : AppColors.surface,
                        border: Border.all(
                          color: _picked.contains(value)
                              ? AppColors.brand700
                              : AppColors.borderControl,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.r8),
                      ),
                      child: _picked.contains(value)
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
                        context.tr(text),
                        style: AppTypography.text(
                          size: 16,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Clear',
                onTap: _picked.isEmpty ? () {} : () => _set(<T>{}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Done',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
