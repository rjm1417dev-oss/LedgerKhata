import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/empty_state.dart';
import 'add_khata_screen.dart';

class KhataListScreen extends StatelessWidget {
  const KhataListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final khatas = state.khatas;
    final business = state.business;

    return ColoredBox(
      color: AppColors.paper,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(business?.name ?? '', style: AppTypography.text(size: 13, weight: FontWeight.w600, color: AppColors.muted)),
                      Text('Khata', style: AppTypography.title),
                    ],
                  ),
                ),
                PrimaryButtonSmall(
                  label: 'New Khata',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddKhataScreen())),
                ),
              ],
            ),
          ),
          Expanded(
            child: khatas.isEmpty
                ? EmptyState(
                    icon: AppIconGlyph.khata,
                    title: 'No khatas yet',
                    message: 'Create your first khata to record items, discount and payments for a customer.',
                    actionLabel: 'New Khata',
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddKhataScreen())),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Text('${khatas.length} khata${khatas.length == 1 ? '' : 's'}', style: AppTypography.caption),
                      const SizedBox(height: 12),
                      for (final k in khatas)
                        Padding(padding: const EdgeInsets.only(bottom: 12), child: KhataCard(khata: k)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
