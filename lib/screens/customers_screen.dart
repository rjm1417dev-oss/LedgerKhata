import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'validators.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'Add customer',
      builder: (sheetContext) => const _AddCustomerForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customers = state.customers;
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
                      Text('Customers', style: AppTypography.title),
                    ],
                  ),
                ),
                PrimaryButtonSmall(label: 'Add', icon: AppIconGlyph.add, onTap: () => _openAddSheet(context)),
              ],
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? EmptyState(
                    icon: AppIconGlyph.customers,
                    title: 'No customers yet',
                    message: 'Add customers to start creating khatas for them.',
                    actionLabel: 'Add customer',
                    onAction: () => _openAddSheet(context),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Text('${customers.length} customer${customers.length == 1 ? '' : 's'}', style: AppTypography.caption),
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
                            for (var i = 0; i < customers.length; i++)
                              CustomerRow(
                                initials: customers[i].initials,
                                name: customers[i].name,
                                phone: customers[i].phone,
                                showDivider: i != customers.length - 1,
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

class _AddCustomerForm extends StatefulWidget {
  const _AddCustomerForm();

  @override
  State<_AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<_AddCustomerForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  String? get _nameError => _tried && _name.text.trim().isEmpty ? 'Enter the customer name' : null;
  String? get _phoneError => _tried ? phoneError(_phone.text) : null;

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || phoneError(_phone.text) != null) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final name = _name.text.trim();
    try {
      await context.read<AppState>().addCustomer(name: name, phone: _phone.text.trim());
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
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
          error: _phoneError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancel', onTap: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(child: PrimaryButton(label: 'Save customer', onTap: _save, loading: _saving)),
          ],
        ),
      ],
    );
  }
}
