import 'dart:ui';

import 'package:flutter/material.dart';

import '../screens/customers_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/items_screen.dart';
import '../screens/khata_list_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_icon.dart';
import '../widgets/glass.dart';

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
      backgroundColor: AppColors.paper,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              DashboardScreen(
                onViewAllKhatas: () => setState(() => _index = 1),
              ),
              const KhataListScreen(),
              const ItemsScreen(),
              const CustomersScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            MediaQuery.paddingOf(context).bottom.clamp(14.0, 64.0),
          ),
          child: _Dock(
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final active = i == _index;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.r26),
                    onTap: () => setState(() => _index = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: active ? AppGradients.brand : null,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: AppIcon(
                              tab.icon,
                              size: 22,
                              color: active ? Colors.white : AppColors.muted,
                              strokeWidth: active ? 2.2 : 1.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: AppTypography.text(
                              size: 11,
                              weight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active
                                  ? AppColors.brand700
                                  : AppColors.muted,
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
      ),
    );
  }
}

/// Floating glass dock for the five sections.
class _Dock extends StatelessWidget {
  final Widget child;

  const _Dock({required this.child});

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.r26);
    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const [
          BoxShadow(
            color: Color(0x290E5C45),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            decoration: BoxDecoration(
              color: const Color(0xB8FFFFFF),
              borderRadius: shape,
              border: Border.all(color: const Color(0xD9FFFFFF)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
