import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/translator.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/khata.dart';

/// Country code assumed for local numbers saved without one (e.g. `0300…`).
/// Numbers entered with a leading `+` or `00` always keep their own code.
const defaultCountryCode = '92';

/// Turns a phone number as the shopkeeper typed it into the digits-only
/// international form wa.me expects, or null when it can't be a real number.
String? whatsAppNumber(String phone) {
  final hasPlus = phone.trim().startsWith('+');
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  if (hasPlus) {
    // already international
  } else if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0')) {
    digits = defaultCountryCode + digits.substring(1);
  } else if (digits.length <= 10) {
    digits = defaultCountryCode + digits;
  }
  return digits.length >= 10 && digits.length <= 15 ? digits : null;
}

/// The wa.me link that opens a chat with [phone] with [message] prefilled,
/// or null when [phone] isn't usable.
Uri? whatsAppUri(String phone, String message) {
  final number = whatsAppNumber(phone);
  if (number == null) return null;
  return Uri.https('wa.me', '/$number', {'text': message});
}

/// What the shopkeeper just added to a customer's khata: the lines, discount
/// and payment from this one save, and the khata cycle they landed on (which
/// may hold earlier purchases too).
class KhataEntry {
  final Customer customer;
  final Khata khata;
  final List<KhataLineItem> lines;
  final double discount;
  final double paid;
  final DateTime date;

  const KhataEntry({
    required this.customer,
    required this.khata,
    required this.lines,
    required this.discount,
    required this.paid,
    required this.date,
  });

  double get total => lines.fold(0.0, (a, l) => a + l.lineTotal);
}

String _money(num n) => 'Rs ${NumberFormat('#,###').format(n.round())}';
String _dateTime(DateTime d) => AppLocale.translator.dateTime(d);

String _lineText(int n, KhataLineItem l) =>
    '$n. ${l.name} — ${formatQuantity(l.quantity)} ${l.unit} × ${_money(l.price)} = *${_money(l.lineTotal)}*';

String _footer(Business? business) {
  final contact = business?.contactNumber?.trim().isNotEmpty == true
      ? business!.contactNumber!
      : business?.phone;
  return [
    tr('Thank you!'),
    if (business != null) '_${business.name}_',
    if (contact != null && contact.trim().isNotEmpty) contact.trim(),
  ].join('\n');
}

/// Text-only WhatsApp message for one saved entry: its items, discount and
/// payment, then what the customer owes on the khata afterwards.
String khataEntryMessage(KhataEntry e, Business? business) {
  final due = e.total - e.discount - e.paid;
  return [
    '*${business?.name ?? 'Khata'}* — ${tr('Khata entry')}',
    '',
    tr('Dear ${e.customer.name},'),
    tr('Here is your khata entry of ${_dateTime(e.date)}:'),
    '',
    for (final (i, l) in e.lines.indexed) _lineText(i + 1, l),
    '',
    tr('Items total: ${_money(e.total)}'),
    if (e.discount > 0) tr('Discount: −${_money(e.discount)}'),
    if (e.paid > 0) tr('Paid: ${_money(e.paid)}'),
    tr('This entry: *${_money(due)}*'),
    '',
    e.khata.remaining > 0
        ? tr('*Total balance due on your khata: ${_money(e.khata.remaining)}*')
        : tr('*Your khata is fully settled.*'),
    '',
    _footer(business),
  ].join('\n');
}

/// Text-only WhatsApp message for a whole khata cycle (every purchase and
/// payment so far), for re-sending a record from the khata cards.
String khataStatementMessage(Khata k, Business? business) {
  final settled = k.remaining <= 0;
  return [
    '*${business?.name ?? 'Khata'}* — ${tr('Khata statement')}',
    '',
    tr('Dear ${k.customerName},'),
    tr('Your khata opened on ${_dateTime(k.date)}:'),
    '',
    for (final (i, l) in k.items.indexed)
      '${_lineText(i + 1, l)} (${_dateTime(l.date)})',
    '',
    tr('Items total: ${_money(k.total)}'),
    if (k.discount > 0) tr('Discount: −${_money(k.discount)}'),
    tr('Paid: ${_money(k.paid)}'),
    for (final p in k.effectivePayments)
      '  • ${_dateTime(p.date)} — ${_money(p.amount)}',
    '',
    settled
        ? tr('*Your khata is fully settled.*')
        : tr('*Balance due: ${_money(k.remaining)}*'),
    '',
    _footer(business),
  ].join('\n');
}

/// Opens [uri] in WhatsApp (or the browser fallback); false if nothing could
/// handle it. Swappable so tests never try to leave the app.
typedef UriLauncher = Future<bool> Function(Uri uri);
UriLauncher whatsAppLauncher = (uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
};

enum WhatsAppResult { opened, badNumber, unavailable }

/// Opens a WhatsApp chat with [customer] with [message] ready to send.
Future<WhatsAppResult> sendWhatsApp(Customer customer, String message) async {
  final uri = whatsAppUri(customer.phone, message);
  if (uri == null) return WhatsAppResult.badNumber;
  return await whatsAppLauncher(uri)
      ? WhatsAppResult.opened
      : WhatsAppResult.unavailable;
}
