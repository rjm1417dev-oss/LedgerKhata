import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'avatar.dart';
import 'cards.dart';

/// Plain divider-separated row: icon tile + item name + price.
class ItemRow extends StatelessWidget {
  final String name;
  final double price;
  final bool showDivider;

  const ItemRow({super.key, required this.name, required this.price, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.divider)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(11)),
            child: const Center(child: AppIcon(AppIconGlyph.item, size: 18, color: AppColors.ink2, strokeWidth: 1.9)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppTypography.text(size: 15, weight: FontWeight.w600))),
          Text(formatMoney(price), style: AppTypography.text(size: 15, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Plain divider-separated row: avatar + customer name + phone.
class CustomerRow extends StatelessWidget {
  final String initials;
  final String name;
  final String phone;
  final bool showDivider;

  const CustomerRow({super.key, required this.initials, required this.name, required this.phone, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.divider)) : null,
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: initials, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: AppTypography.text(size: 15, weight: FontWeight.w600)),
                Text(phone, style: AppTypography.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkbox-style tappable row used in the item search results dropdown.
class SelectableItemRow extends StatelessWidget {
  final String name;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  const SelectableItemRow({super.key, required this.name, required this.price, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F8F4) : AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.brand700 : Colors.white,
                border: Border.all(color: selected ? AppColors.brand700 : AppColors.borderControl, width: 1.5),
                borderRadius: BorderRadius.circular(7),
              ),
              child: selected ? const Center(child: AppIcon(AppIconGlyph.selected, size: 15, color: Colors.white, strokeWidth: 3)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: AppTypography.text(size: 15, weight: FontWeight.w500))),
            Text(formatMoney(price), style: AppTypography.text(size: 14, weight: FontWeight.w600, color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }
}

/// Row in the customer picker dropdown: avatar, name/phone, a check when
/// this is the currently selected customer.
class SelectableCustomerRow extends StatelessWidget {
  final String initials;
  final String name;
  final String phone;
  final bool selected;
  final VoidCallback onTap;

  const SelectableCustomerRow({
    super.key,
    required this.initials,
    required this.name,
    required this.phone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F8F4) : AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            InitialsAvatar(initials: initials, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: AppTypography.text(size: 15, weight: FontWeight.w600)),
                  Text(phone, style: AppTypography.meta),
                ],
              ),
            ),
            if (selected) const AppIcon(AppIconGlyph.selected, size: 20, color: AppColors.brand700, strokeWidth: 2.4),
          ],
        ),
      ),
    );
  }
}

/// Numbered row for the "Selected items" summary list.
class SelectedItemRow extends StatelessWidget {
  final int index;
  final String name;
  final double price;

  const SelectedItemRow({super.key, required this.index, required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(8)),
            child: Text('$index', style: AppTypography.text(size: 12, weight: FontWeight.w700, color: AppColors.ink2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppTypography.text(size: 15, weight: FontWeight.w500))),
          Text(formatMoney(price), style: AppTypography.text(size: 15, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
