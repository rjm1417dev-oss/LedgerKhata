import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../models/item.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_toast.dart';
import '../widgets/buttons.dart';
import '../widgets/empty_state.dart';
import '../widgets/inputs.dart';
import '../widgets/list_rows.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'Add item',
      builder: (sheetContext) => const _ItemForm(),
    );
  }

  void _openEditSheet(BuildContext context, Item item) {
    showAppBottomSheet(
      context: context,
      title: 'Edit item',
      builder: (sheetContext) => _ItemForm(existing: item),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Item item) async {
    final state = context.read<AppState>();
    final usage = state.khataUsageCountForItem(item.id);
    final message = usage == 0
        ? 'This can’t be undone.'
        : 'Used in ${usage == 1 ? '1 khata' : '$usage khatas'} — those records keep "${item.name}"\'s name, price and unit. This can’t be undone.';
    final confirmed = await showAppConfirmDialog(context: context, title: 'Delete ${item.name}?', message: message);
    if (!confirmed) return;
    try {
      await state.deleteItem(item.id);
      if (context.mounted) showAppToast(context, '${item.name} deleted');
    } on RepositoryException catch (e) {
      if (context.mounted) showAppToast(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.items;
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
                      Text('Items', style: AppTypography.title),
                    ],
                  ),
                ),
                PrimaryButtonSmall(label: 'Add', icon: AppIconGlyph.add, onTap: () => _openAddSheet(context)),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: AppIconGlyph.item,
                    title: 'No items yet',
                    message: 'Add the items you sell with their price.',
                    actionLabel: 'Add item',
                    onAction: () => _openAddSheet(context),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Text('${items.length} item${items.length == 1 ? '' : 's'}', style: AppTypography.caption),
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
                            for (var i = 0; i < items.length; i++)
                              ItemRow(
                                name: items[i].name,
                                price: items[i].price,
                                unit: items[i].unit,
                                showDivider: i != items.length - 1,
                                onTap: () => _openEditSheet(context, items[i]),
                                onDelete: () => _confirmDelete(context, items[i]),
                              ),
                          ],
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

class _ItemForm extends StatefulWidget {
  final Item? existing;
  const _ItemForm({this.existing});

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  String? _unit;
  bool _tried = false;
  bool _saving = false;

  static const _maxPrice = 999999999;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _name.text = existing.name;
      _price.text = existing.price.toStringAsFixed(0);
      _unit = existing.unit;
    } else {
      _unit = kItemUnits.first;
    }
  }

  String? get _nameError => _tried && _name.text.trim().isEmpty ? 'Enter the item name' : null;
  String? get _priceError {
    if (!_tried) return null;
    final v = double.tryParse(_price.text) ?? 0;
    if (v <= 0) return 'Enter a price greater than 0';
    if (v > _maxPrice) return 'Enter a smaller price';
    return null;
  }

  String? get _unitError => _tried && _unit == null ? 'Select a unit' : null;

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _priceError != null || _unit == null || (double.tryParse(_price.text) ?? 0) <= 0) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final name = _name.text.trim();
    final price = double.parse(_price.text);
    try {
      final state = context.read<AppState>();
      if (_isEdit) {
        await state.updateItem(id: widget.existing!.id, name: name, price: price, unit: _unit!);
      } else {
        await state.addItem(name: name, price: price, unit: _unit!);
      }
      if (!mounted) return;
      showAppToast(context, _isEdit ? '$name updated' : '$name added');
      Navigator.of(context).pop();
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Item name',
          controller: _name,
          placeholder: 'e.g. Sugar',
          error: _nameError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        UnitField(
          label: 'Unit',
          value: _unit,
          options: kItemUnits,
          error: _unitError,
          onChanged: (v) => setState(() => _unit = v),
        ),
        const SizedBox(height: 16),
        MoneyField(
          label: _unit == null ? 'Price' : 'Price per $_unit',
          controller: _price,
          error: _priceError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancel', onTap: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(child: PrimaryButton(label: _isEdit ? 'Save changes' : 'Save item', onTap: _save, loading: _saving)),
          ],
        ),
      ],
    );
  }
}
