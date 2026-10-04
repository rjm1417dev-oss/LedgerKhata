import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../models/customer.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_toast.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/inputs.dart';

/// Clears a customer's outstanding khata in one payment. Pass [customerId]
/// when the customer is already known (Customer Detail); leave it null to
/// pick one first (Dashboard, Khata tab).
Future<void> showClearKhataSheet(BuildContext context, {String? customerId}) {
  return showAppBottomSheet(
    context: context,
    title: 'Clear Khata',
    builder: (_) => _ClearKhataForm(customerId: customerId),
  );
}

class _ClearKhataForm extends StatefulWidget {
  final String? customerId;
  const _ClearKhataForm({this.customerId});

  @override
  State<_ClearKhataForm> createState() => _ClearKhataFormState();
}

class _ClearKhataFormState extends State<_ClearKhataForm> {
  final _amount = TextEditingController();
  String? _customerId;
  bool _tried = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.customerId;
    _prefillAmount();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  AppState get _state => context.read<AppState>();

  double get _outstanding =>
      _customerId == null ? 0 : _state.outstandingForCustomer(_customerId!);

  /// Pre-fills the full outstanding amount so the common case is one tap.
  void _prefillAmount() {
    final owed = _outstanding;
    _amount.text = owed > 0 ? owed.round().toString() : '';
  }

  String? get _customerError => _tried && _customerId == null
      ? 'Select the customer whose khata you are clearing'
      : null;

  String? get _amountError {
    if (!_tried || _customerId == null) return null;
    final v = double.tryParse(_amount.text) ?? 0;
    if (v <= 0) return 'Enter an amount greater than 0';
    if (v > _outstanding) {
      return 'Can’t be more than the outstanding amount (${formatMoney(_outstanding)})';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = double.tryParse(_amount.text) ?? 0;
    final id = _customerId;
    if (id == null || amount <= 0 || amount > _outstanding) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final name =
        state.customers.where((c) => c.id == id).firstOrNull?.name ??
        'Customer';
    final clearing = amount >= _outstanding;
    try {
      await state.recordCustomerPayment(customerId: id, amount: amount);
      if (!mounted) return;
      showAppToast(
        context,
        clearing
            ? 'Khata cleared for $name'
            : '${formatMoney(amount)} received from $name',
      );
      Navigator.of(context).pop();
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final owing = state.customersWithOutstanding;
    final customer = _customerId == null
        ? null
        : state.customers.where((c) => c.id == _customerId).firstOrNull;
    final outstanding = _outstanding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.customerId == null) ...[
          SelectField<String>(
            label: 'Customer',
            hint: owing.isEmpty
                ? 'No customers owe anything'
                : 'Choose a customer',
            value: _customerId,
            error: _customerError,
            items: [
              for (final Customer c in owing)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    '${c.name} · ${formatMoney(state.outstandingForCustomer(c.id))}',
                  ),
                ),
            ],
            onChanged: (id) => setState(() {
              _customerId = id;
              _prefillAmount();
            }),
          ),
          const SizedBox(height: 16),
        ],
        if (customer != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer.name,
                      style: AppTypography.text(
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text('Total outstanding', style: AppTypography.meta),
                  ],
                ),
                Text(
                  formatMoney(outstanding),
                  style: AppTypography.text(
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.due,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MoneyField(
            label: 'Amount received',
            controller: _amount,
            error: _amountError,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
        ],
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
                label: 'Clear Khata',
                onTap: customer == null || outstanding <= 0 ? null : _save,
                loading: _saving,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
