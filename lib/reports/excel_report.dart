import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

import '../l10n/translator.dart';
import 'khata_report.dart';

String get _sheetSummary => tr('Report Summary');
String get _sheetTransactions => tr('Khata Transactions');
String get _sheetItems => tr('Item Details');
String get _sheetCustomers => tr('Customer Balances');
String get _sheetPayments => tr('Payments');
String get _sheetHistory => tr('Transaction History');
String get _sheetDaily => tr('Daily Summary');

final _money = CustomNumericNumFormat(formatCode: '"Rs. "#,##0.00');
final _qty = CustomNumericNumFormat(formatCode: '#,##0.###');
final _dateFmt = CustomDateTimeNumFormat(formatCode: 'dd mmm yyyy');
final _dateTimeFmt = CustomDateTimeNumFormat(
  formatCode: 'dd mmm yyyy hh:mm AM/PM',
);

CellStyle get _header => CellStyle(
  bold: true,
  fontColorHex: ExcelColor.white,
  backgroundColorHex: ExcelColor.fromHexString('#0E5C45'),
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
  textWrapping: TextWrapping.WrapText,
);

DateCellValue _date(DateTime d) =>
    DateCellValue(year: d.year, month: d.month, day: d.day);

/// Exact local date and time (the device timezone) as a real Excel date-time.
DateTimeCellValue _dateTime(DateTime d) {
  final l = d;
  return DateTimeCellValue(
    year: l.year,
    month: l.month,
    day: l.day,
    hour: l.hour,
    minute: l.minute,
    second: l.second,
  );
}

/// Builds a formatted .xlsx workbook. Amounts and dates are real numeric /
/// date cells so they can be sorted, filtered and summed in Excel; phone
/// numbers are text so leading zeros survive.
Uint8List buildExcelReport(KhataReport report) {
  final book = Excel.createExcel();
  book.rename(book.getDefaultSheet()!, _sheetSummary);

  _summarySheet(book[_sheetSummary], report);
  final tx = _transactionsSheet(book[_sheetTransactions], report);
  final items = _itemsSheet(book[_sheetItems], report);
  final customers = _customersSheet(book[_sheetCustomers], report);
  final payments = _paymentsSheet(book[_sheetPayments], report);
  final history = _historySheet(book[_sheetHistory], report);
  final daily = _dailySheet(book[_sheetDaily], report);

  final bytes = book.encode();
  if (bytes == null) throw StateError('Could not generate the Excel file');
  return _addFiltersAndFreeze(Uint8List.fromList(bytes), {
    _sheetTransactions: tx,
    _sheetItems: items,
    _sheetCustomers: customers,
    _sheetPayments: payments,
    _sheetHistory: history,
    _sheetDaily: daily,
  });
}

void _put(
  Sheet s,
  int col,
  int row,
  CellValue? v, {
  CellStyle? style,
  NumFormat? format,
}) {
  final cell = s.cell(
    CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
  );
  cell.value = v;
  var st = style ?? CellStyle();
  if (format != null) st = st.copyWith(numberFormat: format);
  cell.cellStyle = st;
}

TextCellValue _t(String s) => TextCellValue(s);
DoubleCellValue _n(num v) => DoubleCellValue(v.toDouble());

/// Writes a header row + data rows; returns the sheet's used range for the
/// auto-filter (`A1:M10`).
String _table(
  Sheet s,
  List<String> headers,
  List<List<(CellValue?, NumFormat?)>> rows,
  List<double> widths,
) {
  for (var c = 0; c < headers.length; c++) {
    _put(s, c, 0, _t(headers[c]), style: _header);
    s.setColumnWidth(c, widths[c]);
  }
  s.setRowHeight(0, 30);
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      final (v, f) = rows[r][c];
      _put(s, c, r + 1, v, format: f);
    }
  }
  final lastRow = rows.isEmpty ? 1 : rows.length + 1;
  return 'A1:${_col(headers.length - 1)}$lastRow';
}

String _col(int i) {
  var n = i;
  var s = '';
  do {
    s = String.fromCharCode(65 + n % 26) + s;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return s;
}

void _summarySheet(Sheet s, KhataReport r) {
  s.setColumnWidth(0, 32);
  s.setColumnWidth(1, 44);
  final bold = CellStyle(bold: true);
  final title = CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: ExcelColor.fromHexString('#0E5C45'),
  );
  var row = 0;
  void line(
    String label,
    CellValue? value, {
    NumFormat? format,
    bool strong = false,
  }) {
    _put(s, 0, row, _t(label), style: strong ? bold : null);
    _put(
      s,
      1,
      row,
      value,
      format: format,
      style: strong ? bold : CellStyle(horizontalAlign: HorizontalAlign.Left),
    );
    row++;
  }

  _put(s, 0, row++, _t(r.business.name), style: title);
  _put(s, 0, row++, _t(r.title), style: CellStyle(bold: true, fontSize: 13));
  row++;
  line(tr('Business phone'), _t(r.business.phone));
  line(tr('Report generated'), _t(stampOf(r.generatedAt)));
  line(tr('Date range'), _t(r.filter.rangeLabel));
  line(tr('Payment status filter'), _t(r.filter.statusLabel));
  line(
    tr('Customer'),
    _t(
      r.customer == null
          ? tr('All customers')
          : '${r.customer!.name} (${r.customer!.phone})',
    ),
  );
  row++;
  _put(
    s,
    0,
    row++,
    _t(tr('Totals')),
    style: CellStyle(bold: true, fontSize: 13),
  );
  line(tr('Total transactions'), IntCellValue(r.count));
  line(tr('Total sales on credit'), _n(r.totalSales), format: _money);
  line(tr('Total discounts'), _n(r.totalDiscount), format: _money);
  line(tr('Grand total (after discount)'), _n(r.totalGrand), format: _money);
  line(tr('Total payments recorded'), _n(r.totalPaid), format: _money);
  line(
    tr('Total outstanding balance'),
    _n(r.totalOutstanding),
    format: _money,
    strong: true,
  );
  line(
    tr('Purchase transactions in range'),
    IntCellValue(r.purchaseEventCount),
  );
  line(tr('Payment transactions in range'), IntCellValue(r.paymentEventCount));
  row++;
  line(tr('Pending transactions'), IntCellValue(r.pendingCount));
  line(tr('Partially paid transactions'), IntCellValue(r.partialCount));
  line(tr('Cleared transactions'), IntCellValue(r.clearedCount));
  if (r.isEmpty) {
    row++;
    _put(
      s,
      0,
      row,
      _t(tr('No Khata records match the selected filters.')),
      style: CellStyle(italic: true),
    );
  }
}

String _transactionsSheet(Sheet s, KhataReport r) => _table(
  s,
  [
    tr('Transaction ID'),
    tr('Date'),
    tr('Day'),
    tr('Customer'),
    tr('Phone'),
    tr('Item details'),
    tr('Total quantity'),
    tr('Subtotal'),
    tr('Discount'),
    tr('Grand total'),
    tr('Amount paid'),
    tr('Remaining balance'),
    tr('Payment status'),
  ],
  [
    for (final t in r.transactions)
      [
        (_t(t.id), null),
        (_date(t.date), _dateFmt),
        (_t(t.weekday), null),
        (_t(t.customerName), null),
        (_t(t.customerPhone), null),
        (
          _t(
            t.lines
                .map((l) => '${l.name} (${qtyUnit(l)} × ${rs(l.price)})')
                .join('; '),
          ),
          null,
        ),
        (_n(t.totalQuantity), _qty),
        (_n(t.subtotal), _money),
        (_n(t.discount), _money),
        (_n(t.grandTotal), _money),
        (_n(t.paid), _money),
        (_n(t.remaining), _money),
        (_t(t.status.label), null),
      ],
  ],
  [16, 13, 12, 22, 16, 50, 11, 15, 14, 15, 15, 16, 15],
);

String _itemsSheet(Sheet s, KhataReport r) => _table(
  s,
  [
    tr('Transaction ID'),
    tr('Date & time'),
    tr('Customer'),
    tr('Item name'),
    tr('Quantity'),
    tr('Unit'),
    tr('Unit price'),
    tr('Item subtotal'),
  ],
  [
    for (final t in r.transactions)
      for (final l in t.lines)
        [
          (_t(t.id), null),
          (_dateTime(l.date), _dateTimeFmt),
          (_t(t.customerName), null),
          (_t(l.name), null),
          (_n(l.quantity), _qty),
          (_t(l.unit), null),
          (_n(l.price), _money),
          (_n(l.lineTotal), _money),
        ],
  ],
  [16, 22, 22, 28, 11, 10, 15, 16],
);

String _customersSheet(Sheet s, KhataReport r) => _table(
  s,
  [
    tr('Customer'),
    tr('Phone'),
    tr('Transactions'),
    tr('Grand total'),
    tr('Amount paid'),
    tr('Outstanding balance'),
  ],
  [
    for (final b in r.customerBalances)
      [
        (_t(b.name), null),
        (_t(b.phone), null),
        (IntCellValue(b.transactions), null),
        (_n(b.grandTotal), _money),
        (_n(b.paid), _money),
        (_n(b.outstanding), _money),
      ],
  ],
  [24, 16, 14, 16, 16, 20],
);

String _paymentsSheet(Sheet s, KhataReport r) => _table(
  s,
  [
    tr('Transaction ID'),
    tr('Customer'),
    tr('Payment date & time'),
    tr('Type'),
    tr('Payment method'),
    tr('Amount'),
    tr('Payment ref'),
  ],
  [
    for (final t in r.transactions) ...[
      if (t.paidWithPurchases > 0)
        [
          (_t(t.id), null),
          (_t(t.customerName), null),
          (_dateTime(t.date), _dateTimeFmt),
          (_t(tr('Paid with purchases')), null),
          (_t(''), null),
          (_n(t.paidWithPurchases), _money),
          (_t(''), null),
        ],
      for (final p in t.loggedPayments)
        [
          (_t(t.id), null),
          (_t(t.customerName), null),
          (_dateTime(p.date), _dateTimeFmt),
          (
            _t(p.purchaseId != null ? tr('Paid with purchase') : tr('Payment')),
            null,
          ),
          (_t(methodLabel(p.method) ?? ''), null),
          (_n(p.amount), _money),
          // Allocations of one payment (split across khatas) share a ref.
          (
            _t(
              p.paymentId.length > 8
                  ? p.paymentId.substring(0, 8).toUpperCase()
                  : p.paymentId.toUpperCase(),
            ),
            null,
          ),
        ],
    ],
  ],
  [16, 24, 22, 20, 18, 16, 14],
);

/// Every purchase and payment as its own row, oldest first per customer, with
/// the exact time, the items, and the balance owed right after.
String _historySheet(Sheet s, KhataReport r) => _table(
  s,
  [
    tr('Customer'),
    tr('Phone'),
    tr('Date & time'),
    tr('Date'),
    tr('Time'),
    tr('Type'),
    tr('Payment method'),
    tr('Items (qty unit × price)'),
    tr('Subtotal'),
    tr('Discount'),
    tr('Purchase amount'),
    tr('Payment received'),
    tr('Balance after'),
  ],
  [
    for (final l in r.ledgers)
      for (final e in l.entries)
        [
          (_t(l.name), null),
          (_t(l.phone), null),
          (_dateTime(e.date), _dateTimeFmt),
          (_date(e.date), _dateFmt),
          (_t(timeOf(e.date)), null),
          (_t(entryTitle(e)), null),
          (_t(methodLabel(e.method) ?? ''), null),
          (_t(e.isPurchase ? entryDetails(e) : ''), null),
          (e.isPurchase ? _n(e.subtotal) : null, _money),
          (e.isPurchase ? _n(e.discount) : null, _money),
          (e.isPurchase ? _n(e.net) : null, _money),
          (e.isPayment ? _n(e.received) : null, _money),
          (_n(e.balanceAfter), _money),
        ],
  ],
  [22, 16, 22, 13, 10, 18, 18, 60, 14, 12, 16, 16, 16],
);

/// How many purchases and payments each customer made on each day.
String _dailySheet(Sheet s, KhataReport r) => _table(
  s,
  [
    tr('Customer'),
    tr('Phone'),
    tr('Date'),
    tr('Day'),
    tr('Purchases (count)'),
    tr('Payments (count)'),
    tr('Purchased'),
    tr('Received'),
    tr('Closing balance'),
  ],
  [
    for (final l in r.ledgers)
      for (final d in l.days)
        [
          (_t(l.name), null),
          (_t(l.phone), null),
          (_date(d.day), _dateFmt),
          (_t(AppLocale.translator.weekday(d.day.weekday)), null),
          (IntCellValue(d.purchaseCount), null),
          (IntCellValue(d.paymentCount), null),
          (_n(d.purchased), _money),
          (_n(d.received), _money),
          (_n(d.closingBalance), _money),
        ],
  ],
  [22, 16, 13, 12, 17, 16, 15, 15, 16],
);

/// The `excel` package can't set filters or frozen headers, so patch each
/// listed sheet's XML: freeze the header row and add an auto-filter over the
/// table range.
Uint8List _addFiltersAndFreeze(
  Uint8List xlsx,
  Map<String, String> rangeBySheet,
) {
  final zip = ZipDecoder().decodeBytes(xlsx);
  String? read(String name) {
    final f = zip.findFile(name);
    return f == null ? null : utf8.decode(f.content as List<int>);
  }

  // Map sheet name → worksheet part path via workbook.xml + its rels.
  final workbook = read('xl/workbook.xml');
  final rels = read('xl/_rels/workbook.xml.rels');
  if (workbook == null || rels == null) return xlsx;
  final targetById = {
    for (final m in RegExp(r'<Relationship\b[^>]*>').allMatches(rels))
      _attr(m.group(0)!, 'Id'): _attr(m.group(0)!, 'Target'),
  };

  final patched = <String, String>{};
  for (final m in RegExp(r'<sheet\b[^>]*>').allMatches(workbook)) {
    final tag = m.group(0)!;
    final name = _attr(tag, 'name');
    final range = rangeBySheet[name];
    final target = targetById[_attr(tag, 'r:id')];
    if (range == null || target == null) continue;
    final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
    var xml = read(path);
    if (xml == null) continue;

    // Freeze the header row.
    const pane =
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>';
    if (RegExp(r'<sheetView\b[^>]*/>').hasMatch(xml)) {
      xml = xml.replaceFirstMapped(
        RegExp(r'<sheetView\b([^>]*)/>'),
        (mm) => '<sheetView${mm.group(1)}>$pane</sheetView>',
      );
    } else if (RegExp(r'<sheetView\b[^>]*>').hasMatch(xml) &&
        !xml.contains('<pane ')) {
      xml = xml.replaceFirstMapped(
        RegExp(r'(<sheetView\b[^>]*>)'),
        (mm) => '${mm.group(1)}$pane',
      );
    } else if (!xml.contains('<sheetViews')) {
      xml = xml.replaceFirst(
        '<sheetData',
        '<sheetViews><sheetView workbookViewId="0">$pane</sheetView></sheetViews><sheetData',
      );
    }

    // Auto-filter goes right after <sheetData> (before merges, margins, etc.).
    if (!xml.contains('<autoFilter')) {
      xml = xml.replaceFirst(
        '</sheetData>',
        '</sheetData><autoFilter ref="$range"/>',
      );
    }
    patched[path] = xml;
  }
  if (patched.isEmpty) return xlsx;

  final out = Archive();
  for (final f in zip) {
    final replacement = patched[f.name];
    if (replacement != null) {
      final data = utf8.encode(replacement);
      out.addFile(ArchiveFile(f.name, data.length, data));
    } else {
      out.addFile(f);
    }
  }
  final encoded = ZipEncoder().encode(out);
  return encoded == null ? xlsx : Uint8List.fromList(encoded);
}

String _attr(String tag, String name) {
  final m = RegExp('(?:^|\\s)${RegExp.escape(name)}="([^"]*)"').firstMatch(tag);
  return m?.group(1) ?? '';
}
