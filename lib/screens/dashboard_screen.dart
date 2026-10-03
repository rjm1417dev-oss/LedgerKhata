import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_icon.dart';
import '../widgets/avatar.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/empty_state.dart';
import 'add_khata_screen.dart';
import 'clear_khata_sheet.dart';

/// Dashboard: header, remaining-balance hero, three count tiles and the three
/// most recent khatas. Layout, spacing and type follow the "03 Dashboard"
/// board of the Khata design file.
class DashboardScreen extends StatelessWidget {
  /// Opens the Khata tab ("View all").
  final VoidCallback onViewAllKhatas;

  const DashboardScreen({super.key, required this.onViewAllKhatas});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final business = state.business;
    final khatas = state.khatas;

    return ColoredBox(
      color: AppColors.paper,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        business?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.text(size: 13, weight: FontWeight.w600, color: AppColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text('Dashboard', style: AppTypography.title),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InitialsAvatar(initials: initialsOf(business?.name ?? ''), size: 44, solid: true),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                BalanceHero(
                  totalRemaining: state.totalRemaining,
                  pendingCount: state.pendingKhataCount,
                  totalKhatas: khatas.length,
                  totalBilled: state.totalBilled,
                  totalDiscount: state.totalDiscount,
                  totalReceived: state.totalReceived,
                ),
                const SizedBox(height: 12),
                Row(
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
                        fullWidth: true,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddKhataScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: StatTile(icon: AppIconGlyph.khata, value: '${khatas.length}', label: 'Khatas')),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(icon: AppIconGlyph.customers, value: '${state.customers.length}', label: 'Customers')),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(icon: AppIconGlyph.item, value: '${state.items.length}', label: 'Items')),
                  ],
                ),
                const SizedBox(height: 16),
                if (khatas.isEmpty)
                  EmptyState(
                    icon: AppIconGlyph.khata,
                    title: 'No khatas yet',
                    message: 'Create your first khata to record items, discount and payments for a customer.',
                    actionLabel: 'New Khata',
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddKhataScreen())),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent khatas', style: AppTypography.heading),
                      TextLinkButton(label: 'View all', onTap: onViewAllKhatas),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < state.recentKhatas.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    KhataCard(khata: state.recentKhatas[i], compact: true),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
