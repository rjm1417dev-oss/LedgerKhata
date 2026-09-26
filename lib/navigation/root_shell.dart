import 'package:flutter/material.dart';

import '../screens/customers_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/items_screen.dart';
import '../screens/khata_list_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_icon.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    (label: 'Dashboard', icon: AppIconGlyph.dashboard),
    (label: 'Khata', icon: AppIconGlyph.khata),
    (label: 'Items', icon: AppIconGlyph.item),
    (label: 'Customers', icon: AppIconGlyph.customers),
    (label: 'Settings', icon: AppIconGlyph.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(onViewAllKhatas: () => setState(() => _index = 1)),
            const KhataListScreen(),
            const ItemsScreen(),
            const CustomersScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      // 22px below the tabs in the design (room for the home indicator); never
      // less than the device's own bottom inset.
      bottomNavigationBar: Builder(
        builder: (context) => Container(
          padding: EdgeInsets.fromLTRB(6, 8, 6, MediaQuery.paddingOf(context).bottom.clamp(22.0, 64.0)),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final active = i == _index;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? AppColors.brand100 : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: AppIcon(
                            tab.icon,
                            size: 22,
                            color: active ? AppColors.brand700 : AppColors.muted,
                            strokeWidth: active ? 2 : 1.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: AppTypography.text(
                            size: 11,
                            weight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? AppColors.brand700 : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
