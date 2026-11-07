import '../l10n/translator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/khata.dart';
import '../models/khata_filters.dart';
import '../widgets/khata_filters.dart';
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
import 'send_khata_sheet.dart';
import '../widgets/glass.dart';

class KhataListScreen extends StatefulWidget {
  const KhataListScreen({super.key});

  @override
  State<KhataListScreen> createState() => _KhataListScreenState();
}

class _KhataListScreenState extends State<KhataListScreen> {
  KhataFilters _filters = KhataFilters.none;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allKhatas = state.khatas;
    final business = state.business;
    final months = monthsIn(allKhatas);
    final khatas = allKhatas.where(_filters.matchesKhata).toList();

    return AuroraBackground(
      child: Column(
        children: [
          ScreenHeader(businessName: business?.name ?? '', title: 'Khata'),
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
                      KhataFilterPanel(
                        filters: _filters,
                        months: months,
                        onChanged: (f) => setState(() => _filters = f),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        (khatas.length == 1
                            ? '1 khata'
                            : '${khatas.length} khatas'),
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 12),
                      if (khatas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            context.tr('No entries for this filter'),
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
                                onSendWhatsApp: () =>
                                    showSendStatementSheet(context, state, k),
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
