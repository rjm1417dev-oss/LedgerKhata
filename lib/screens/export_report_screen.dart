import '../l10n/translator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../reports/khata_report.dart';
import '../reports/report_exporter.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_toast.dart';
import '../widgets/badges.dart';
import '../widgets/buttons.dart';
import '../widgets/language_selector.dart';
import '../widgets/glass.dart';
import '../widgets/inputs.dart';
import '../widgets/pressable.dart';

/// Export Khata records to PDF or Excel. Opened from the Dashboard for the
/// whole shop (any customer can be picked), or from a Customer Detail page
/// with [customerId] set — then that customer is used automatically and
/// can't be changed.
class ExportReportScreen extends StatefulWidget {
  final String? customerId;

  /// Optional pre-filled date range.
  final DateTime? initialFrom;
  final DateTime? initialTo;
  const ExportReportScreen({
    super.key,
    this.customerId,
    this.initialFrom,
    this.initialTo,
  });

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  static const _allCustomers = '';

  ReportFormat _format = ReportFormat.pdf;
  Set<PaymentStatus> _statuses = {...ReportFilter.allStatuses};
  DateTime? _from;
  DateTime? _to;
  String _customerId = _allCustomers;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.customerId ?? _allCustomers;
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  ReportFilter get _filter => ReportFilter(
    from: _from,
    to: _to,
    statuses: _statuses,
    customerId: _customerId == _allCustomers ? null : _customerId,
  );

  bool _is(Set<PaymentStatus> preset) =>
      _statuses.length == preset.length && _statuses.containsAll(preset);

  void _toggleStatus(PaymentStatus s) => setState(() {
    final next = {..._statuses};
    if (!next.remove(s)) next.add(s);
    if (next.isNotEmpty) _statuses = next; // at least one status stays selected
  });

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = (isFrom ? _from : _to) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: isFrom ? 'Start date' : 'End date',
    );
    if (picked == null || !mounted) return;
    setState(() => isFrom ? _from = picked : _to = picked);
  }

  Future<void> _export(AppState state, KhataReport? report) async {
    if (_exporting) return;
    if (_filter.rangeError != null) {
      showAppToast(context, _filter.rangeError!, isError: true);
      return;
    }
    if (report == null || report.isEmpty) {
      showAppToast(
        context,
        'No Khata records match these filters.',
        isError: true,
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      await exportReport(report, _format);
    } catch (_) {
      if (mounted)
        showAppToast(
          context,
          'Couldn’t create the report. Please try again.',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final business = state.business;
    final lockedCustomer = widget.customerId == null
        ? null
        : state.customers.where((c) => c.id == widget.customerId).firstOrNull;

    final rangeError = _filter.rangeError;
    final report = (business == null || rangeError != null)
        ? null
        : buildKhataReport(
            business: business,
            customers: state.customers,
            khatas: state.khatas,
            filter: _filter,
          );

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 10),
                child: Row(
                  children: [
                    IconButtonGhost(
                      icon: AppIconGlyph.back,
                      onTap: () => Navigator.of(context).pop(),
                      semanticLabel: 'Back',
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lockedCustomer?.name ?? business?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.text(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            widget.customerId == null
                                ? 'Export Reports'
                                : 'Export Report',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.display(
                              size: 24,
                              weight: FontWeight.w700,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const LanguageButton(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    if (widget.customerId == null) ...[
                      _card(
                        title: 'Report type',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppFilterChip(
                              label: 'All Khatas',
                              selected: _is(ReportFilter.allStatuses),
                              onTap: () => setState(
                                () => _statuses = {...ReportFilter.allStatuses},
                              ),
                            ),
                            AppFilterChip(
                              label: 'Pending Khatas',
                              selected: _is(PaymentStatus.outstanding),
                              onTap: () => setState(
                                () =>
                                    _statuses = {...PaymentStatus.outstanding},
                              ),
                            ),
                            AppFilterChip(
                              label: 'Cleared Khatas',
                              selected: _is({PaymentStatus.cleared}),
                              onTap: () => setState(
                                () => _statuses = {PaymentStatus.cleared},
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _card(
                      title: 'File format',
                      child: Row(
                        children: [
                          for (final f in ReportFormat.values) ...[
                            if (f != ReportFormat.values.first)
                              const SizedBox(width: 8),
                            Expanded(
                              child: _FormatTile(
                                label: f.label,
                                hint: f == ReportFormat.pdf
                                    ? 'Print & share'
                                    : 'Sort & analyse',
                                selected: _format == f,
                                onTap: () => setState(() => _format = f),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      title: 'Filters',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.customerId == null)
                            SelectField<String>(
                              label: 'Customer',
                              hint: 'All customers',
                              value: _customerId,
                              items: [
                                DropdownMenuItem(
                                  value: _allCustomers,
                                  child: Text(context.tr('All customers')),
                                ),
                                for (final c in state.customers)
                                  DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(
                                () => _customerId = v ?? _allCustomers,
                              ),
                            )
                          else ...[
                            Text(
                              context.tr('Customer'),
                              style: AppTypography.label,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lockedCustomer == null
                                  ? 'Customer not found'
                                  : '${lockedCustomer.name} · ${lockedCustomer.phone}',
                              style: AppTypography.text(
                                size: 15,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            context.tr('Date range (khata opened)'),
                            style: AppTypography.label,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _DateBox(
                                  label: 'From',
                                  value: _from,
                                  hasError: rangeError != null,
                                  onTap: () => _pickDate(isFrom: true),
                                  onClear: () => setState(() => _from = null),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DateBox(
                                  label: 'To',
                                  value: _to,
                                  hasError: rangeError != null,
                                  onTap: () => _pickDate(isFrom: false),
                                  onClear: () => setState(() => _to = null),
                                ),
                              ),
                            ],
                          ),
                          if (rangeError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              context.tr(rangeError),
                              style: AppTypography.text(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            context.tr('Payment status'),
                            style: AppTypography.label,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in PaymentStatus.values)
                                AppFilterChip(
                                  label: s.label,
                                  selected: _statuses.contains(s),
                                  onTap: () => _toggleStatus(s),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      title: 'Preview',
                      child: _Preview(report: report, rangeError: rangeError),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: PrimaryButton(
                  label: 'Export ${_format.label}',
                  loading: _exporting,
                  loadingLabel: 'Preparing…',
                  onTap: () => _export(state, report),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) => GlassCard(
    radius: AppRadius.r22,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(title),
          style: AppTypography.text(size: 16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _FormatTile extends StatelessWidget {
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;
  const _FormatTile({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand100 : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.brand700 : AppColors.borderInput,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(label),
              style: AppTypography.text(
                size: 15,
                weight: FontWeight.w700,
                color: selected ? AppColors.brand700 : AppColors.ink,
              ),
            ),
            Text(
              context.tr(hint),
              style: AppTypography.text(size: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool hasError;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DateBox({
    required this.label,
    required this.value,
    required this.hasError,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? label
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';
    return Semantics(
      button: true,
      label: value == null ? 'Choose $label date' : '$label date $text',
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: AppSpacing.fieldHeight,
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.borderInput,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(text),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.text(
                    size: 15,
                    weight: value == null ? FontWeight.w400 : FontWeight.w600,
                    color: value == null ? AppColors.chevron : AppColors.ink,
                  ),
                ),
              ),
              if (value != null)
                IconButtonGhost(
                  icon: AppIconGlyph.close,
                  onTap: onClear,
                  semanticLabel: 'Clear $label date',
                  color: AppColors.chevron,
                  backgroundColor: Colors.transparent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final KhataReport? report;
  final String? rangeError;
  const _Preview({required this.report, required this.rangeError});

  @override
  Widget build(BuildContext context) {
    final r = report;
    if (r == null) {
      return Text(
        context.tr('Fix the date range to see a preview.'),
        style: AppTypography.meta,
      );
    }
    if (r.isEmpty) {
      return Text(
        context.tr('No Khata records match these filters.'),
        style: AppTypography.text(
          size: 14,
          weight: FontWeight.w600,
          color: AppColors.due,
        ),
      );
    }

    Widget row(
      String label,
      String value, {
      bool strong = false,
      Color? color,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr(label),
            style: AppTypography.text(size: 14, color: AppColors.muted),
          ),
          Text(
            value,
            style: AppTypography.text(
              size: 14,
              weight: strong ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.ink,
              tabular: true,
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        row('Khata transactions', '${r.count}', strong: true),
        row('Total sales on credit', rs(r.totalSales)),
        row('Total discounts', rs(r.totalDiscount)),
        row('Total paid', rs(r.totalPaid)),
        row(
          'Total outstanding',
          rs(r.totalOutstanding),
          strong: true,
          color: r.totalOutstanding > 0 ? AppColors.due : AppColors.brand700,
        ),
        row(
          'Pending / Partial / Cleared',
          '${r.pendingCount} / ${r.partialCount} / ${r.clearedCount}',
        ),
      ],
    );
  }
}
