import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
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
      builder: (sheetContext) => const _AddItemForm(),
    );
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
                              ItemRow(name: items[i].name, price: items[i].price, showDivider: i != items.length - 1),
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

class _AddItemForm extends StatefulWidget {
  const _AddItemForm();

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  static const _maxPrice = 999999999;

  String? get _nameError => _tried && _name.text.trim().isEmpty ? 'Enter the item name' : null;
  String? get _priceError {
    if (!_tried) return null;
    final v = double.tryParse(_price.text) ?? 0;
    if (v <= 0) return 'Enter a price greater than 0';
    if (v > _maxPrice) return 'Enter a smaller price';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _priceError != null || (double.tryParse(_price.text) ?? 0) <= 0) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final name = _name.text.trim();
    try {
      await context.read<AppState>().addItem(name: name, price: double.parse(_price.text));
      if (!mounted) return;
      showAppToast(context, '$name added');
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
          placeholder: 'e.g. Basmati Rice 5kg',
          error: _nameError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        MoneyField(label: 'Price', controller: _price, error: _priceError, onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancel', onTap: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(child: PrimaryButton(label: 'Save item', onTap: _save, loading: _saving)),
          ],
        ),
      ],
    );
  }
}
