import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/khata.dart';
import '../state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/rise_in.dart';
import '../widgets/screen_header.dart';
import '../widgets/app_icon.dart';
import '../widgets/badges.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/empty_state.dart';
import 'add_khata_screen.dart';
import 'clear_khata_sheet.dart';
import 'customer_detail_screen.dart';
import '../widgets/glass.dart';

class KhataListScreen extends StatefulWidget {
  const KhataListScreen({super.key});

  @override
  State<KhataListScreen> createState() => _KhataListScreenState();
}

class _KhataListScreenState extends State<KhataListScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allKhatas = state.khatas;
    final business = state.business;
    final months = monthsIn(allKhatas);
    final khatas = allKhatas.where((k) => k.inMonth(_month)).toList();

    return AuroraBackground(
      child: Column(
        children: [
          ScreenHeader(
            businessName: business?.name ?? '',
            title: 'Khata',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButtonSmall(
                    label: 'Clear Khata',
                    icon: AppIconGlyph.selected,
                    fullWidth: true,
                    onTap: () => showClearKhataSheet(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButtonSmall(
                    label: 'New Khata',
                    icon: AppIconGlyph.add,
                    fullWidth: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddKhataScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: allKhatas.isEmpty
                ? EmptyState(
                    icon: AppIconGlyph.khata,
                    title: 'No khatas yet',
                    message:
                        'Create your first khata to record items, discount and payments for a customer.',
                    actionLabel: 'New Khata',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddKhataScreen()),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      if (months.length > 1) ...[
                        MonthFilterBar(
                          months: months,
                          selected: _month,
                          onChanged: (m) => setState(() => _month = m),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        '${khatas.length} khata${khatas.length == 1 ? '' : 's'}',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 12),
                      if (khatas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No khatas that month.',
                            style: AppTypography.meta,
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        for (final (i, k) in khatas.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RiseIn(
                              index: i,
                              child: KhataCycleCard(
                                khata: k,
                                customerName: k.customerName,
                                showPendingBadge: true,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(
                                      customerId: k.customerId,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
