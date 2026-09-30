import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../models/khata.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_toast.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/inputs.dart';

/// Bottom sheet to record a payment against an open khata cycle, moving it
/// toward settled. Shared by the Khata tab and the customer detail page.
Future<void> showRecordPaymentSheet(BuildContext context, Khata khata) {
  return showAppBottomSheet(
    context: context,
    title: 'Record payment',
    builder: (sheetContext) => _RecordPaymentForm(khata: khata),
  );
}

class _RecordPaymentForm extends StatefulWidget {
  final Khata khata;
  const _RecordPaymentForm({required this.khata});

  @override
  State<_RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends State<_RecordPaymentForm> {
  final _amount = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  String? get _amountError {
    if (!_tried) return null;
    final v = double.tryParse(_amount.text) ?? 0;
    if (v <= 0) return 'Enter a payment amount greater than 0';
    if (v > widget.khata.remaining) return 'Can’t be more than the remaining amount (${formatMoney(widget.khata.remaining)})';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0 || amount > widget.khata.remaining) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await context.read<AppState>().recordKhataPayment(khataId: widget.khata.id, amount: amount);
      if (!mounted) return;
      showAppToast(context, '${formatMoney(amount)} recorded for ${widget.khata.customerName}');
      Navigator.of(context).pop();
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final khata = widget.khata;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(khata.customerName, style: AppTypography.text(size: 14, weight: FontWeight.w600)),
                  Text('Remaining', style: AppTypography.meta),
                ],
              ),
              Text(formatMoney(khata.remaining), style: AppTypography.text(size: 20, weight: FontWeight.w700, color: AppColors.due)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MoneyField(label: 'Payment amount', controller: _amount, error: _amountError, onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancel', onTap: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(child: PrimaryButton(label: 'Record payment', onTap: _save, loading: _saving)),
          ],
        ),
      ],
    );
  }
}
