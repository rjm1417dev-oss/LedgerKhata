import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../models/customer.dart';
import '../state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/rise_in.dart';
import '../widgets/screen_header.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_toast.dart';
import '../widgets/buttons.dart';
import '../widgets/empty_state.dart';
import '../widgets/inputs.dart';
import '../widgets/list_rows.dart';
import 'customer_detail_screen.dart';
import 'validators.dart';
import '../widgets/glass.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'Add customer',
      builder: (sheetContext) => const CustomerForm(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    final state = context.read<AppState>();
    final count = state.khataCountForCustomer(customer.id);
    if (count > 0) {
      await showAppAlertDialog(
        context: context,
        title: 'Can’t delete ${customer.name}',
        message:
            '${customer.name} has ${count == 1 ? '1 khata' : '$count khatas'} on record. '
            'Delete those khatas first if you still want to remove this customer.',
      );
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete ${customer.name}?',
      message: 'This can’t be undone.',
    );
    if (!confirmed) return;
    try {
      await state.deleteCustomer(customer.id);
      if (context.mounted) showAppToast(context, '${customer.name} deleted');
    } on RepositoryException catch (e) {
      if (context.mounted) showAppToast(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customers = state.customers;
    final business = state.business;

    return AuroraBackground(
      child: Column(
        children: [
          ScreenHeader(
            businessName: business?.name ?? '',
            title: 'Customers',
            trailing: PrimaryButtonSmall(
              label: 'Add',
              icon: AppIconGlyph.add,
              onTap: () => _openAddSheet(context),
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
                      Text(
                        '${customers.length} customer${customers.length == 1 ? '' : 's'}',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(
                          children: [
                            for (var i = 0; i < customers.length; i++)
                              RiseIn(
                                index: i,
                                child: CustomerRow(
                                  initials: customers[i].initials,
                                  name: customers[i].name,
                                  phone: customers[i].phone,
                                  showDivider: i != customers.length - 1,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CustomerDetailScreen(
                                        customerId: customers[i].id,
                                      ),
                                    ),
                                  ),
                                  onDelete: () =>
                                      _confirmDelete(context, customers[i]),
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
    );
  }
}

/// Add/edit form shared with [CustomerDetailScreen]'s "Edit" action.
class CustomerForm extends StatefulWidget {
  final Customer? existing;
  const CustomerForm({super.key, this.existing});

  @override
  State<CustomerForm> createState() => CustomerFormState();
}

class CustomerFormState extends State<CustomerForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _name.text = existing.name;
      _phone.text = existing.phone;
    }
  }

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
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    try {
      final state = context.read<AppState>();
      if (_isEdit) {
        await state.updateCustomer(
          id: widget.existing!.id,
          name: name,
          phone: phone,
        );
        if (mounted) showAppToast(context, '$name updated');
      } else {
        await state.addCustomer(name: name, phone: phone);
        if (mounted) showAppToast(context, '$name added');
      }
      if (mounted) Navigator.of(context).pop();
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
                label: _isEdit ? 'Save changes' : 'Save customer',
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
