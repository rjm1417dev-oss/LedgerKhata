import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../models/customer.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_toast.dart';
import '../widgets/avatar.dart';
import '../widgets/buttons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final business = state.business;
    final initials = initialsOf(business?.name ?? '');

    return ColoredBox(
      color: AppColors.paper,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Settings', style: AppTypography.title),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'BUSINESS',
                    style: AppTypography.text(size: 13, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.06 * 13),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                        child: Row(
                          children: [
                            InitialsAvatar(initials: initials, size: 48, solid: true),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    business?.name ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.text(size: 17, weight: FontWeight.w700),
                                  ),
                                  Text('Business account', style: AppTypography.meta),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _row('Business name', business?.name ?? ''),
                      _row('Owner name', business?.ownerName ?? ''),
                      _row('Phone number', business?.phone ?? ''),
                      _row('Email', state.email ?? '', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SecondaryButton(
                  label: 'Sign out',
                  onTap: () async {
                    try {
                      await state.signOut();
                    } on RepositoryException catch (e) {
                      if (context.mounted) showAppToast(context, e.message, isError: true);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.text(size: 14, color: AppColors.muted)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: AppTypography.text(size: 15, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}
