import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_toast.dart';
import '../widgets/avatar.dart';
import '../widgets/badges.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/inputs.dart';
import '../widgets/list_rows.dart';
import '../widgets/pressable.dart';
import 'validators.dart';

class AddKhataScreen extends StatefulWidget {
  const AddKhataScreen({super.key});

  @override
  State<AddKhataScreen> createState() => _AddKhataScreenState();
}

class _AddKhataScreenState extends State<AddKhataScreen> {
  Customer? _customer;
  bool _custOpen = false;

  final _query = TextEditingController();
  bool _searchOpen = false;

  /// Insertion-ordered so the "Selected items" list keeps the order items
  /// were picked in.
  final Map<String, double> _quantities = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  final _discount = TextEditingController();
  final _paid = TextEditingController();

  bool _tried = false;
  bool _saving = false;

  @override
  void dispose() {
    _query.dispose();
    _discount.dispose();
    _paid.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _qtyController(String itemId, double initial) {
    return _qtyControllers.putIfAbsent(itemId, () => TextEditingController(text: formatQuantity(initial)));
  }

  void _pickCustomer(Customer c) => setState(() {
    _customer = c;
    _custOpen = false;
  });

  void _toggleItem(Item item) => setState(() {
    if (_quantities.containsKey(item.id)) {
      _quantities.remove(item.id);
      _qtyControllers.remove(item.id)?.dispose();
    } else {
      _quantities[item.id] = 1;
      _qtyController(item.id, 1);
    }
  });

  void _removeItem(String itemId) => setState(() {
    _quantities.remove(itemId);
    _qtyControllers.remove(itemId)?.dispose();
  });

  void _setQuantity(String itemId, double quantity) => setState(() {
    if (quantity <= 0) return;
    _quantities[itemId] = quantity;
  });

  List<SelectedKhataItem> _selectedItems(AppState state) {
    final result = <SelectedKhataItem>[];
    for (final entry in _quantities.entries) {
      final item = state.items.where((i) => i.id == entry.key).firstOrNull;
      if (item != null) result.add(SelectedKhataItem(item: item, quantity: entry.value));
    }
    return result;
  }

  Future<void> _openNewCustomerSheet() async {
    setState(() => _custOpen = false);
    final created = await showAppBottomSheet<Customer>(
      context: context,
      title: 'Add customer',
      builder: (_) => const _NewCustomerForm(),
    );
    if (created != null && mounted) {
      setState(() => _customer = created);
      showAppToast(context, '${created.name} added and selected');
    }
  }

  Future<void> _save(AppState state) async {
    if (_saving) return;
    final selectedItems = _selectedItems(state);
    final discount = double.tryParse(_discount.text) ?? 0;
    final paid = double.tryParse(_paid.text) ?? 0;
    final total = selectedItems.fold(0.0, (a, i) => a + i.lineTotal);
    final over = (total - discount - paid) < 0;

    if (_customer == null || selectedItems.isEmpty || over) {
      setState(() {
        _tried = true;
        _searchOpen = false;
        _custOpen = false;
      });
      return;
    }

    setState(() {
      _saving = true;
      _searchOpen = false;
      _custOpen = false;
    });

    final savedName = _customer!.name;
    try {
      await state.addKhata(
        customer: _customer!,
        selectedItems: selectedItems,
        discount: discount,
        paid: paid,
      );
      if (!mounted) return;
      setState(() {
        _tried = false;
        _customer = null;
        for (final c in _qtyControllers.values) {
          c.dispose();
        }
        _qtyControllers.clear();
        _quantities.clear();
        _discount.clear();
        _paid.clear();
        _query.clear();
      });
      showAppToast(context, 'Khata saved for $savedName');
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final business = state.business;

    final selectedItems = _selectedItems(state);
    final total = selectedItems.fold(0.0, (a, i) => a + i.lineTotal);
    final discount = double.tryParse(_discount.text) ?? 0;
    final paid = double.tryParse(_paid.text) ?? 0;
    final remaining = total - discount - paid;
    final over = remaining < 0;

    final custErr = _tried && _customer == null
        ? 'Select a customer for this khata'
        : null;
    final itemsErr = _tried && selectedItems.isEmpty
        ? 'Select at least one item'
        : null;
    final payErr = over
        ? "Discount and paid amount can’t be more than the items total (${formatMoney(total)})"
        : null;

    final remColor = over
        ? AppColors.error
        : (remaining > 0 ? AppColors.due : AppColors.brand700);
    final remText = formatSignedMoney(remaining);

    final query = _query.text.trim().toLowerCase();
    final results = state.items
        .where((i) => query.isEmpty || i.name.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 10),
            child: Row(
              children: [
                IconButtonGhost(
                  icon: AppIconGlyph.back,
                  onTap: () => Navigator.of(context).pop(),
                  semanticLabel: 'Back to Khata',
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      business?.name ?? '',
                      style: AppTypography.text(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'New Khata',
                      style: AppTypography.display(
                        size: 24,
                        weight: FontWeight.w700,
                        letterSpacing: -0.02,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                _section(
                  index: 1,
                  title: 'Customer',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select customer', style: AppTypography.label),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Pressable(
                              onTap: () => setState(() {
                                _custOpen = !_custOpen;
                                _searchOpen = false;
                              }),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 54,
                                ),
                                padding: const EdgeInsets.only(
                                  left: 14,
                                  right: 12,
                                  top: 8,
                                  bottom: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: custErr != null
                                        ? AppColors.error
                                        : AppColors.borderInput,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.r12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _customer == null
                                          ? Text(
                                              'Choose a customer',
                                              style: AppTypography.text(
                                                size: 15,
                                                color: AppColors.chevron,
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                InitialsAvatar(
                                                  initials: _customer!.initials,
                                                  size: 32,
                                                ),
                                                const SizedBox(width: 10),
                                                Flexible(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _customer!.name,
                                                        style:
                                                            AppTypography.text(
                                                              size: 15,
                                                              weight: FontWeight
                                                                  .w600,
                                                            ),
                                                      ),
                                                      Text(
                                                        _customer!.phone,
                                                        style:
                                                            AppTypography.meta,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    AnimatedRotation(
                                      turns: _custOpen ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: const AppIcon(
                                        AppIconGlyph.expand,
                                        size: 20,
                                        color: AppColors.muted,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButtonSoft(
                            icon: AppIconGlyph.add,
                            onTap: _openNewCustomerSheet,
                            semanticLabel: 'Add new customer',
                          ),
                        ],
                      ),
                      if (custErr != null) _errorLine(custErr),
                      if (_custOpen) ...[
                        const SizedBox(height: 10),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14161816),
                                blurRadius: 28,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: state.customers.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'No customers yet. Tap + to add one.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.meta,
                                  ),
                                )
                              : ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for (final c in state.customers)
                                      SelectableCustomerRow(
                                        initials: c.initials,
                                        name: c.name,
                                        phone: c.phone,
                                        selected: c.id == _customer?.id,
                                        onTap: () => _pickCustomer(c),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  index: 2,
                  title: 'Items',
                  trailing: CountChip('${selectedItems.length} selected'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSearchField(
                        label: 'Search items',
                        placeholder: 'Search by item name',
                        controller: _query,
                        onFocus: () => setState(() {
                          _searchOpen = true;
                          _custOpen = false;
                        }),
                        onChanged: (_) => setState(() => _searchOpen = true),
                        error: itemsErr,
                      ),
                      if (_searchOpen) ...[
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14161816),
                                blurRadius: 28,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                color: AppColors.surfaceSubtle,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${results.length} item${results.length == 1 ? '' : 's'}',
                                      style: AppTypography.caption,
                                    ),
                                    Text(
                                      'Tap to select multiple',
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 268,
                                ),
                                child: results.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'No items match “${_query.text}”',
                                          textAlign: TextAlign.center,
                                          style: AppTypography.meta,
                                        ),
                                      )
                                    : ListView(
                                        shrinkWrap: true,
                                        children: [
                                          for (final item in results)
                                            SelectableItemRow(
                                              name: item.name,
                                              price: item.price,
                                              unit: item.unit,
                                              selected: _quantities
                                                  .containsKey(item.id),
                                              onTap: () => _toggleItem(item),
                                            ),
                                        ],
                                      ),
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${selectedItems.length} selected · ${formatMoney(total)}',
                                      style: AppTypography.text(
                                        size: 13,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    Pressable(
                                      onTap: () => setState(() {
                                        _searchOpen = false;
                                        _query.clear();
                                      }),
                                      child: Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.brand700,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Done',
                                          style: AppTypography.text(
                                            size: 14,
                                            weight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('Selected items', style: AppTypography.label),
                      const SizedBox(height: 8),
                      if (selectedItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.borderInput,
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const AppIcon(
                                AppIconGlyph.item,
                                size: 26,
                                color: AppColors.placeholder,
                                strokeWidth: 1.7,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No items selected yet',
                                style: AppTypography.text(
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Search above and tap items to add them.',
                                style: AppTypography.meta,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              for (var i = 0; i < selectedItems.length; i++)
                                SelectedItemRow(
                                  index: i + 1,
                                  name: selectedItems[i].item.name,
                                  price: selectedItems[i].item.price,
                                  unit: selectedItems[i].item.unit,
                                  quantityController: _qtyController(
                                    selectedItems[i].item.id,
                                    selectedItems[i].quantity,
                                  ),
                                  onQuantityChanged: (q) =>
                                      _setQuantity(selectedItems[i].item.id, q),
                                  onRemove: () =>
                                      _removeItem(selectedItems[i].item.id),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                color: AppColors.surfaceSubtle,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Items total',
                                      style: AppTypography.text(
                                        size: 14,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      formatMoney(total),
                                      style: AppTypography.text(
                                        size: 16,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  index: 3,
                  title: 'Payment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total items amount',
                              style: AppTypography.text(
                                size: 14,
                                weight: FontWeight.w600,
                                color: AppColors.ink2,
                              ),
                            ),
                            Text(
                              formatMoney(total),
                              style: AppTypography.text(
                                size: 17,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      MoneyField(
                        label: 'Discount',
                        controller: _discount,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      MoneyField(
                        label: 'Paid amount',
                        controller: _paid,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (payErr != null) _errorLine(payErr),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 14),
                      ComputedField(
                        label: 'Remaining amount',
                        value: remText,
                        valueColor: remColor,
                        helper: 'Auto-calculated: Total items amount − Discount − Paid amount',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remaining',
                      style: AppTypography.text(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      remText,
                      style: AppTypography.text(
                        size: 18,
                        weight: FontWeight.w700,
                        color: remColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save Khata',
                    onTap: () => _save(state),
                    loading: _saving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorLine(String message) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIcon(
          AppIconGlyph.error,
          size: 16,
          color: AppColors.error,
          strokeWidth: 2,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: AppTypography.text(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _section({
    required int index,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.brand700,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$index',
                      style: AppTypography.text(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: AppTypography.text(
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _NewCustomerForm extends StatefulWidget {
  const _NewCustomerForm();

  @override
  State<_NewCustomerForm> createState() => _NewCustomerFormState();
}

class _NewCustomerFormState extends State<_NewCustomerForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  String? get _nameError =>
      _tried && _name.text.trim().isEmpty ? 'Enter the customer name' : null;
  String? get _phoneError => _tried ? phoneError(_phone.text) : null;

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || phoneError(_phone.text) != null) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final customer = await context.read<AppState>().addCustomer(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(customer);
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Customer name',
          controller: _name,
          placeholder: 'Full name',
          error: _nameError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Phone number',
          controller: _phone,
          placeholder: '03XX XXXXXXX',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
          ],
          error: _phoneError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Cancel',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Save customer',
                onTap: _save,
                loading: _saving,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
