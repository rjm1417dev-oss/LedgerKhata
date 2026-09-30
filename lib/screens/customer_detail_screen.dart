import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/badges.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/empty_state.dart';
import 'add_khata_screen.dart';
import 'customers_screen.dart';
import 'record_payment_sheet.dart';

/// A customer's full khata history: every cycle they've had (open and
/// settled), filterable by month, with an action to edit the customer and
/// to record payments against an open cycle. Deleting a customer lives on
/// the Customers list, not here.
class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  DateTime? _month;

  void _openEditSheet(BuildContext context, Customer customer) {
    showAppBottomSheet(context: context, title: 'Edit customer', builder: (_) => CustomerForm(existing: customer));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customer = state.customers.where((c) => c.id == widget.customerId).firstOrNull;

    if (customer == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 10),
            child: Row(
              children: [
                IconButtonGhost(icon: AppIconGlyph.back, onTap: () => Navigator.of(context).pop(), semanticLabel: 'Back to Customers'),
                const SizedBox(width: 6),
                Text('Customer not found', style: AppTypography.text(size: 16, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    final business = state.business;
    final allKhatas = state.khatasForCustomer(customer.id);
    final months = monthsIn(allKhatas);
    final khatas = allKhatas.where((k) => k.inMonth(_month)).toList();

    final totalRemaining = allKhatas.fold(0.0, (a, k) => a + (k.remaining > 0 ? k.remaining : 0));
    final pendingCount = allKhatas.where((k) => !k.isSettled).length;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 10),
            child: Row(
              children: [
                IconButtonGhost(icon: AppIconGlyph.back, onTap: () => Navigator.of(context).pop(), semanticLabel: 'Back to Customers'),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(business?.name ?? '', style: AppTypography.text(size: 12, weight: FontWeight.w600, color: AppColors.muted)),
                      Text(
                        customer.name,
                        style: AppTypography.display(size: 24, weight: FontWeight.w700, letterSpacing: -0.02),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButtonGhost(
                  icon: AppIconGlyph.edit,
                  onTap: () => _openEditSheet(context, customer),
                  semanticLabel: 'Edit ${customer.name}',
                  color: AppColors.brand700,
                  backgroundColor: AppColors.brand100,
                ),
                const SizedBox(width: 4),
                IconButtonGhost(
                  icon: AppIconGlyph.close,
                  onTap: () => Navigator.of(context).pop(),
                  semanticLabel: 'Close',
                  color: AppColors.chevron,
                  backgroundColor: AppColors.surfaceSunken,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(customer.phone, style: AppTypography.text(size: 14, color: AppColors.muted)),
                const SizedBox(height: 16),
                BalanceHero(
                  totalRemaining: totalRemaining,
                  pendingCount: pendingCount,
                  totalKhatas: allKhatas.length,
                  totalBilled: allKhatas.fold(0.0, (a, k) => a + k.total),
                  totalDiscount: allKhatas.fold(0.0, (a, k) => a + k.discount),
                  totalReceived: allKhatas.fold(0.0, (a, k) => a + k.paid),
                ),
                const SizedBox(height: 18),
                if (months.length > 1) ...[
                  MonthFilterBar(months: months, selected: _month, onChanged: (m) => setState(() => _month = m)),
                  const SizedBox(height: 14),
                ],
                if (allKhatas.isEmpty)
                  EmptyState(
                    icon: AppIconGlyph.khata,
                    title: 'No khatas yet',
                    message: 'Add a khata for ${customer.name} to start tracking what they owe.',
                    actionLabel: 'New Khata',
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddKhataScreen())),
                  )
                else if (khatas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text('No activity that month.', style: AppTypography.meta, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        TextLinkButton(label: 'Show all time', onTap: () => setState(() => _month = null)),
                      ],
                    ),
                  )
                else ...[
                  Text('${khatas.length} khata${khatas.length == 1 ? '' : 's'}', style: AppTypography.caption),
                  const SizedBox(height: 10),
                  for (final k in khatas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CycleCard(
                        khata: k,
                        onRecordPayment: k.isSettled ? null : () => showRecordPaymentSheet(context, k),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerEntry {
  final DateTime date;
  final String label;
  final double amount;
  final bool isPayment;

  const _LedgerEntry({required this.date, required this.label, required this.amount, required this.isPayment});
}

List<_LedgerEntry> _entriesFor(Khata k) {
  final entries = <_LedgerEntry>[
    for (final i in k.items)
      _LedgerEntry(date: i.date, label: '${i.name} · ${formatQuantity(i.quantity)} ${i.unit}', amount: i.lineTotal, isPayment: false),
    for (final p in k.payments) _LedgerEntry(date: p.date, label: 'Payment received', amount: p.amount, isPayment: true),
  ];
  entries.sort((a, b) => a.date.compareTo(b.date));
  return entries;
}

/// One khata cycle: every purchase and payment as its own row, in the order
/// they happened, followed by the running total/discount/paid breakdown.
class _CycleCard extends StatelessWidget {
  final Khata khata;
  final VoidCallback? onRecordPayment;

  const _CycleCard({required this.khata, this.onRecordPayment});

  @override
  Widget build(BuildContext context) {
    final settled = khata.isSettled;
    final entries = _entriesFor(khata);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Opened ${formatDate(khata.date)}',
                  style: AppTypography.text(size: 13, weight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
              settled ? const SettledBadge() : DueBadge('${formatMoney(khata.remaining)} due'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [for (var i = 0; i < entries.length; i++) _entryRow(entries[i], i != entries.length - 1)],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _totalCell('Total', formatMoney(khata.total)),
              _totalCell('Discount', formatMoney(khata.discount)),
              _totalCell('Paid', formatMoney(khata.paid)),
            ],
          ),
          if (onRecordPayment != null) ...[
            const SizedBox(height: 12),
            PrimaryButtonSmall(label: 'Record payment', icon: AppIconGlyph.add, onTap: onRecordPayment),
          ],
        ],
      ),
    );
  }

  Widget _entryRow(_LedgerEntry e, bool showDivider) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(border: showDivider ? const Border(bottom: BorderSide(color: AppColors.divider)) : null),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.label,
                style: AppTypography.text(size: 13, weight: FontWeight.w600, color: e.isPayment ? AppColors.brand700 : AppColors.ink2),
              ),
              Text(formatDate(e.date), style: AppTypography.text(size: 11, color: AppColors.muted)),
            ],
          ),
        ),
        Text(
          e.isPayment ? '−${formatMoney(e.amount)}' : formatMoney(e.amount),
          style: AppTypography.text(size: 13, weight: FontWeight.w700, color: e.isPayment ? AppColors.brand700 : AppColors.ink),
        ),
      ],
    ),
  );

  Widget _totalCell(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.text(size: 12, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.text(size: 14, weight: FontWeight.w600, tabular: true)),
      ],
    ),
  );
}
