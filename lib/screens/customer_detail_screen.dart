import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/khata.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/badges.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/empty_state.dart';
import 'add_khata_screen.dart';
import 'customers_screen.dart';
import 'clear_khata_sheet.dart';
import '../widgets/glass.dart';

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
    showAppBottomSheet(
      context: context,
      title: 'Edit customer',
      builder: (_) => CustomerForm(existing: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customer = state.customers
        .where((c) => c.id == widget.customerId)
        .firstOrNull;

    if (customer == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: AuroraBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 10),
              child: Row(
                children: [
                  IconButtonGhost(
                    icon: AppIconGlyph.back,
                    onTap: () => Navigator.of(context).pop(),
                    semanticLabel: 'Back to Customers',
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Customer not found',
                    style: AppTypography.text(
                      size: 16,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final business = state.business;
    final allKhatas = state.khatasForCustomer(customer.id);
    final months = monthsIn(allKhatas);
    final khatas = allKhatas.where((k) => k.inMonth(_month)).toList();

    final totalRemaining = allKhatas.fold(
      0.0,
      (a, k) => a + (k.remaining > 0 ? k.remaining : 0),
    );
    final pendingCount = allKhatas.where((k) => !k.isSettled).length;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
                child: Row(
                children: [
                  IconButtonGhost(
                    icon: AppIconGlyph.back,
                    onTap: () => Navigator.of(context).pop(),
                    semanticLabel: 'Back to Customers',
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          business?.name ?? '',
                          style: AppTypography.text(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          customer.name,
                          style: AppTypography.display(
                            size: 24,
                            weight: FontWeight.w700,
                            letterSpacing: -0.02,
                          ),
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
                  Text(
                    customer.phone,
                    style: AppTypography.text(size: 14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  BalanceHero(
                    totalRemaining: totalRemaining,
                    pendingCount: pendingCount,
                    totalKhatas: allKhatas.length,
                    totalBilled: allKhatas.fold(0.0, (a, k) => a + k.total),
                    totalDiscount: allKhatas.fold(
                      0.0,
                      (a, k) => a + k.discount,
                    ),
                    totalReceived: allKhatas.fold(0.0, (a, k) => a + k.paid),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PrimaryButtonSmall(
                      label: 'Clear Khata',
                      icon: AppIconGlyph.selected,
                      onTap: () =>
                          showClearKhataSheet(context, customerId: customer.id),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (months.length > 1) ...[
                    MonthFilterBar(
                      months: months,
                      selected: _month,
                      onChanged: (m) => setState(() => _month = m),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (allKhatas.isEmpty)
                    EmptyState(
                      icon: AppIconGlyph.khata,
                      title: 'No khatas yet',
                      message:
                          'Add a khata for ${customer.name} to start tracking what they owe.',
                      actionLabel: 'New Khata',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddKhataScreen(),
                        ),
                      ),
                    )
                  else if (khatas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(
                            'No activity that month.',
                            style: AppTypography.meta,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          TextLinkButton(
                            label: 'Show all time',
                            onTap: () => setState(() => _month = null),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      '${khatas.length} khata${khatas.length == 1 ? '' : 's'}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),
                    for (final k in khatas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KhataCycleCard(khata: k),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
