import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/khata.dart';
import '../services/whatsapp.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_toast.dart';
import '../widgets/buttons.dart';

/// Offers to WhatsApp [message] to [customer] with a preview of exactly what
/// will be sent (formatted text only — no image or attachment).
Future<void> showSendKhataSheet(
  BuildContext context, {
  required Customer customer,
  required String message,
  String title = 'Send on WhatsApp',
  String? intro,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: title,
    builder: (_) =>
        _SendKhataForm(customer: customer, message: message, intro: intro),
  );
}

class _SendKhataForm extends StatefulWidget {
  final Customer customer;
  final String message;
  final String? intro;
  const _SendKhataForm({
    required this.customer,
    required this.message,
    this.intro,
  });

  @override
  State<_SendKhataForm> createState() => _SendKhataFormState();
}

class _SendKhataFormState extends State<_SendKhataForm> {
  bool _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final result = await sendWhatsApp(widget.customer, widget.message);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case WhatsAppResult.opened:
        Navigator.of(context).pop();
      case WhatsAppResult.badNumber:
        showAppToast(
          context,
          '${widget.customer.name}’s phone number isn’t valid for WhatsApp. Edit the customer and try again.',
          isError: true,
        );
      case WhatsAppResult.unavailable:
        showAppToast(
          context,
          'Couldn’t open WhatsApp on this device.',
          isError: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.intro ??
              'Send this to ${widget.customer.name} (${widget.customer.phone}).',
          style: AppTypography.text(size: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: SingleChildScrollView(
              child: Text(
                widget.message,
                style: AppTypography.text(size: 13, color: AppColors.ink2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Send on WhatsApp',
          loading: _sending,
          loadingLabel: 'Opening…',
          onTap: _send,
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'Not now',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Opens the send sheet for a whole khata cycle (the card's WhatsApp action).
Future<void> showSendStatementSheet(
  BuildContext context,
  AppState state,
  Khata khata,
) async {
  final customer = state.customers
      .where((c) => c.id == khata.customerId)
      .firstOrNull;
  if (customer == null) return;
  await showSendKhataSheet(
    context,
    customer: customer,
    message: khataStatementMessage(khata, state.business),
    title: 'Send khata statement',
  );
}
