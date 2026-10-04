import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'cards.dart';
import 'pressable.dart';
import 'quantity_stepper.dart';

/// Plain divider-separated row: icon tile + item name + price per unit.
/// Tapping the row edits it; [onDelete], when set, shows a trailing delete
/// action outside the tappable area so the two never fight over a tap.
class ItemRow extends StatelessWidget {
  final String name;
  final double price;
  final String unit;
  final bool showDivider;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ItemRow({
    super.key,
    required this.name,
    required this.price,
    required this.unit,
    this.showDivider = true,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSunken,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: AppIcon(
                          AppIconGlyph.item,
                          size: 18,
                          color: AppColors.ink2,
                          strokeWidth: 1.9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.text(
                          size: 15,
                          weight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatMoney(price)} / $unit',
                      style: AppTypography.text(
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onDelete != null)
            IconButtonGhost(
              icon: AppIconGlyph.delete,
              onTap: onDelete,
              semanticLabel: 'Delete $name',
              sunken: true,
              color: AppColors.error,
              backgroundColor: AppColors.errorSoft,
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Plain divider-separated row: avatar + customer name + phone. Tapping the
/// row opens their detail page; [onDelete], when set, shows a trailing
/// delete action outside the tappable area so the two never fight over a tap.
class CustomerRow extends StatelessWidget {
  final String initials;
  final String name;
  final String phone;
  final bool showDivider;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CustomerRow({
    super.key,
    required this.initials,
    required this.name,
    required this.phone,
    this.showDivider = true,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
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
                          Text(
                            name,
                            style: AppTypography.text(
                              size: 15,
                              weight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(phone, style: AppTypography.meta),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onDelete != null)
            IconButtonGhost(
              icon: AppIconGlyph.delete,
              onTap: onDelete,
              semanticLabel: 'Delete $name',
              sunken: true,
              color: AppColors.error,
              backgroundColor: AppColors.errorSoft,
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Checkbox-style tappable row used in the item search results dropdown.
class SelectableItemRow extends StatelessWidget {
  final String name;
  final double price;
  final String unit;
  final bool selected;
  final VoidCallback onTap;

  const SelectableItemRow({
    super.key,
    required this.name,
    required this.price,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

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
                border: Border.all(
                  color: selected
                      ? AppColors.brand700
                      : AppColors.borderControl,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: selected
                  ? const Center(
                      child: AppIcon(
                        AppIconGlyph.selected,
                        size: 15,
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: AppTypography.text(size: 15, weight: FontWeight.w500),
              ),
            ),
            Text(
              '${formatMoney(price)} / $unit',
              style: AppTypography.text(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
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
                  Text(
                    name,
                    style: AppTypography.text(
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(phone, style: AppTypography.meta),
                ],
              ),
            ),
            if (selected)
              const AppIcon(
                AppIconGlyph.selected,
                size: 20,
                color: AppColors.brand700,
                strokeWidth: 2.4,
              ),
          ],
        ),
      ),
    );
  }
}

/// Numbered row for the "Selected items" summary list: name, a quantity
/// stepper in the item's unit, the line total, and a remove action.
class SelectedItemRow extends StatelessWidget {
  final int index;
  final String name;
  final double price;
  final String unit;
  final TextEditingController quantityController;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  const SelectedItemRow({
    super.key,
    required this.index,
    required this.name,
    required this.price,
    required this.unit,
    required this.quantityController,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: AppTypography.text(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.ink2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.text(size: 15, weight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButtonGhost(
                icon: AppIconGlyph.close,
                onTap: onRemove,
                semanticLabel: 'Remove $name',
                sunken: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Row(
              children: [
                Text(
                  '${formatMoney(price)} / $unit',
                  style: AppTypography.text(size: 12, color: AppColors.muted),
                ),
                const Spacer(),
                QuantityStepper(
                  controller: quantityController,
                  unit: unit,
                  onChanged: onQuantityChanged,
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: quantityController,
                  builder: (context, value, _) {
                    final qty = double.tryParse(value.text) ?? 0;
                    return Text(
                      formatMoney(price * qty),
                      style: AppTypography.text(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
