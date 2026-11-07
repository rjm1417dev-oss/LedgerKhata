import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ledger.dart';
import '../l10n/translator.dart';
import 'khata_report.dart';
import 'urdu_text_image.dart';

/// Fonts embedded in the PDF for English / Roman Urdu text. Text containing
/// Urdu script is drawn as images instead (see urdu_text_image.dart), because
/// the PDF library doesn't join Arabic-script letters.
class ReportFonts {
  final pw.Font regular;
  final pw.Font bold;

  const ReportFonts({required this.regular, required this.bold});

  static Future<ReportFonts> load() async {
    Future<pw.Font> f(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$name'));
    return ReportFonts(
      regular: await f('NotoSans-Regular.ttf'),
      bold: await f('NotoSans-Bold.ttf'),
    );
  }
}

const _brand = PdfColor.fromInt(0xFF0E5C45);
const _brandSoft = PdfColor.fromInt(0xFFE3F0EA);
const _ink = PdfColor.fromInt(0xFF16181D);
const _muted = PdfColor.fromInt(0xFF4F5562);
const _line = PdfColor.fromInt(0xFFD6D1C4);
const _due = PdfColor.fromInt(0xFF8A3F0B);
const _dueSoft = PdfColor.fromInt(0xFFFBEEDD);

typedef _TextFn =
    pw.Widget Function(
      String s, {
      double size,
      bool bold,
      PdfColor color,
      pw.TextAlign? align,
    });

/// Items longer than this are allowed to split across pages instead of being
/// kept in one piece (a single block taller than a page can't be kept whole).
const _keepTogetherMaxLines = 18;

Future<Uint8List> buildPdfReport(KhataReport report, ReportFonts fonts) async {
  final doc = pw.Document(
    title: report.title,
    author: report.business.name,
    creator: tr('Khata'),
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
  );

  final stamp = stampOf(report.generatedAt);

  // Urdu-script strings are drawn as images; everything else is real text.
  // Pass 1 runs the layout code with a collector to learn which images are
  // needed, they're rendered, then pass 2 builds the real document.
  final needed = <String, ({String text, bool bold, int color})>{};
  final images = <String, (pw.MemoryImage, TextImage)>{};
  String keyOf(String s, bool bold, PdfColor c) =>
      '${bold ? 'b' : 'r'}|${c.toInt()}|$s';

  pw.Widget collecting(
    String source, {
    double size = 9,
    bool bold = false,
    PdfColor color = _ink,
    pw.TextAlign? align,
  }) {
    final s = tr(source); // every PDF text goes through the central translator
    if (urduScript.hasMatch(s))
      needed[keyOf(s, bold, color)] = (
        text: s,
        bold: bold,
        color: color.toInt(),
      );
    return pw.SizedBox();
  }

  pw.Widget real(
    String source, {
    double size = 9,
    bool bold = false,
    PdfColor color = _ink,
    pw.TextAlign? align,
  }) {
    final s = tr(source);
    final img = images[keyOf(s, bold, color)];
    if (img != null) {
      final scale = size / renderFontSize;
      final right = (align ?? pw.TextAlign.right) == pw.TextAlign.right;
      return pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Image(
          img.$1,
          width: img.$2.width * scale,
          height: img.$2.height * scale,
        ),
      );
    }
    return pw.Text(
      s,
      textAlign: align ?? pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    );
  }

  late _TextFn t;

  pw.Widget statCell(String label, String value, {PdfColor? accent}) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: _brandSoft,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              t(label, size: 8, color: _muted),
              pw.SizedBox(height: 2),
              t(value, size: 12, bold: true, color: accent ?? _ink),
            ],
          ),
        ),
      );

  pw.Widget summaryBlock() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      t(tr('Summary'), size: 13, bold: true, color: _brand),
      pw.SizedBox(height: 6),
      pw.Row(
        children: [
          statCell(tr('Khata transactions'), '${report.count}'),
          pw.SizedBox(width: 6),
          statCell(tr('Total sales on credit'), rs(report.totalSales)),
          pw.SizedBox(width: 6),
          statCell(tr('Total discounts'), rs(report.totalDiscount)),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        children: [
          statCell(tr('Total amount paid'), rs(report.totalPaid)),
          pw.SizedBox(width: 6),
          statCell(
            tr('Total outstanding'),
            rs(report.totalOutstanding),
            accent: report.totalOutstanding > 0 ? _due : _brand,
          ),
          pw.SizedBox(width: 6),
          statCell(
            tr('Pending / Partial / Cleared'),
            '${report.pendingCount} / ${report.partialCount} / ${report.clearedCount}',
          ),
        ],
      ),
    ],
  );

  pw.Widget cell(
    pw.Widget child, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) => pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: child,
  );

  pw.Widget headerCell(String s, {bool right = false}) => cell(
    t(
      s,
      size: 8,
      bold: true,
      color: PdfColors.white,
      align: right ? pw.TextAlign.right : pw.TextAlign.left,
    ),
    alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
  );

  pw.Widget statusChip(PaymentStatus s) {
    final cleared = s == PaymentStatus.cleared;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: cleared ? _brandSoft : _dueSoft,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: t(s.label, size: 8, bold: true, color: cleared ? _brand : _due),
    );
  }

  pw.Widget customerBalancesBlock() {
    if (report.customerBalances.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        t(tr('Customer balances'), size: 13, bold: true, color: _brand),
        pw.SizedBox(height: 4),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2.4),
            2: pw.FlexColumnWidth(1.2),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
            5: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _brand),
              children: [
                headerCell(tr('Customer')),
                headerCell(tr('Phone')),
                headerCell(tr('Khatas'), right: true),
                headerCell(tr('Total'), right: true),
                headerCell(tr('Paid'), right: true),
                headerCell(tr('Outstanding'), right: true),
              ],
            ),
            for (final b in report.customerBalances)
              pw.TableRow(
                children: [
                  cell(t(b.name)),
                  cell(t(b.phone)),
                  cell(
                    t('${b.transactions}', align: pw.TextAlign.right),
                    alignment: pw.Alignment.centerRight,
                  ),
                  cell(
                    t(rs(b.grandTotal), align: pw.TextAlign.right),
                    alignment: pw.Alignment.centerRight,
                  ),
                  cell(
                    t(rs(b.paid), align: pw.TextAlign.right),
                    alignment: pw.Alignment.centerRight,
                  ),
                  cell(
                    t(
                      rs(b.outstanding),
                      bold: true,
                      color: b.outstanding > 0 ? _due : _ink,
                      align: pw.TextAlign.right,
                    ),
                    alignment: pw.Alignment.centerRight,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget totalsRow(
    String label,
    String value, {
    bool strong = false,
    PdfColor? color,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 110,
          child: t(label, size: 9, bold: strong, color: _muted),
        ),
        pw.SizedBox(
          width: 90,
          child: t(
            value,
            size: 9,
            bold: strong,
            color: color ?? _ink,
            align: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );

  pw.Widget transactionBlock(ReportTransaction tx) {
    final paymentsText = [
      if (tx.paidWithPurchases > 0)
        'Paid with purchases: ${rs(tx.paidWithPurchases)}',
      for (final p in tx.loggedPayments)
        '${stampOf(p.date)}: ${rs(p.amount)}${methodLabel(p.method) == null ? '' : ' (${methodLabel(p.method)})'}',
    ];
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    t(tx.customerName, size: 11, bold: true),
                    t(tx.customerPhone, size: 9, color: _muted),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  t(
                    '${stampOf(tx.date)} · ${tx.weekday}',
                    size: 9,
                    bold: true,
                    align: pw.TextAlign.right,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      t(tx.id, size: 8, color: _muted),
                      pw.SizedBox(width: 6),
                      statusChip(tx.status),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _line, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1.8),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _brand),
                children: [
                  headerCell(tr('Item')),
                  headerCell(tr('Qty'), right: true),
                  headerCell(tr('Unit price'), right: true),
                  headerCell(tr('Subtotal'), right: true),
                ],
              ),
              for (final l in tx.lines)
                pw.TableRow(
                  children: [
                    cell(t(l.name)),
                    cell(
                      t(qtyUnit(l), align: pw.TextAlign.right),
                      alignment: pw.Alignment.centerRight,
                    ),
                    cell(
                      t(rs(l.price), align: pw.TextAlign.right),
                      alignment: pw.Alignment.centerRight,
                    ),
                    cell(
                      t(rs(l.lineTotal), align: pw.TextAlign.right),
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 4),
          totalsRow(tr('Items subtotal'), rs(tx.subtotal)),
          totalsRow(
            tr('Discount'),
            tx.discount > 0 ? '- ${rs(tx.discount)}' : rs(0),
          ),
          totalsRow(tr('Grand total'), rs(tx.grandTotal), strong: true),
          totalsRow(tr('Amount paid'), rs(tx.paid)),
          totalsRow(
            tr('Remaining'),
            rs(tx.remaining),
            strong: true,
            color: tx.remaining > 0 ? _due : _brand,
          ),
          if (paymentsText.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            t(
              'Payments: ${paymentsText.join('  ·  ')}',
              size: 8,
              color: _muted,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget historyEntryRow(LedgerEntry e) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 50, child: t(timeOf(e.date), size: 8, bold: true)),
        pw.SizedBox(
          width: 70,
          child: t(entryTitle(e), size: 8, color: e.isPurchase ? _ink : _brand),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (e.isPurchase) ...[
                for (final l in e.lines)
                  t(
                    '${l.name} · ${qtyUnit(l)} × ${rs(l.price)} = ${rs(l.lineTotal)}',
                    size: 8,
                  ),
                if (e.discount > 0)
                  t('Discount − ${rs(e.discount)}', size: 8, color: _muted),
              ] else
                t(
                  methodLabel(e.method) == null
                      ? tr('Received')
                      : '${tr('Received')} · ${methodLabel(e.method)}',
                  size: 8,
                  color: _muted,
                ),
            ],
          ),
        ),
        pw.SizedBox(
          width: 62,
          child: t(
            e.isPurchase ? rs(e.net) : '− ${rs(e.received)}',
            size: 8,
            bold: true,
            align: pw.TextAlign.right,
          ),
        ),
        pw.SizedBox(
          width: 70,
          child: t(
            rs(e.balanceAfter),
            size: 8,
            bold: true,
            color: e.balanceAfter > 0 ? _due : _brand,
            align: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );

  pw.Widget historyDay(DaySummary d, List<LedgerEntry> entries) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          color: _brandSoft,
          child: t(
            '${dayLabel(d.day)}  ·  ${purchasesLabel(d.purchaseCount)}, ${paymentsLabel(d.paymentCount)}',
            size: 8,
            bold: true,
            color: _brand,
          ),
        ),
        pw.Row(
          children: [
            pw.SizedBox(
              width: 50,
              child: t(tr('Time'), size: 7, color: _muted),
            ),
            pw.SizedBox(
              width: 70,
              child: t(tr('Type'), size: 7, color: _muted),
            ),
            pw.Expanded(child: t(tr('Items'), size: 7, color: _muted)),
            pw.SizedBox(
              width: 62,
              child: t(
                tr('Amount'),
                size: 7,
                color: _muted,
                align: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(
              width: 70,
              child: t(
                tr('Balance after'),
                size: 7,
                color: _muted,
                align: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        for (final e in entries) historyEntryRow(e),
      ],
    ),
  );

  List<pw.Widget> historyBlock() {
    if (report.ledgers.isEmpty) return const [];
    return [
      pw.SizedBox(height: 10),
      t(tr('Transaction history'), size: 13, bold: true, color: _brand),
      pw.SizedBox(height: 2),
      t(
        tr(
          'Every purchase and payment with its exact time, oldest first. Times are shop time (Pakistan, UTC+5).',
        ),
        size: 8,
        color: _muted,
      ),
      pw.SizedBox(height: 6),
      for (final l in report.ledgers) ...[
        t(
          '${l.name}${l.phone.isEmpty ? '' : '  ·  ${l.phone}'}  —  ${purchasesLabel(l.purchaseCount)}, ${paymentsLabel(l.paymentCount)}',
          size: 10,
          bold: true,
        ),
        pw.SizedBox(height: 4),
        for (final d in l.days)
          historyDay(d, [
            for (final e in l.entries)
              if (dayOf(e.date) == d.day) e,
          ]),
        pw.SizedBox(height: 6),
      ],
    ];
  }

  List<pw.Widget> body() => [
    // ── business + report header ──
    pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          t(report.business.name, size: 18, bold: true, color: PdfColors.white),
          pw.SizedBox(height: 2),
          t(
            'Phone: ${report.business.phone}',
            size: 10,
            color: PdfColors.white,
          ),
          pw.SizedBox(height: 8),
          t(report.title, size: 14, bold: true, color: PdfColors.white),
        ],
      ),
    ),
    pw.SizedBox(height: 8),
    pw.Wrap(
      spacing: 16,
      runSpacing: 2,
      children: [
        for (final line in report.filterLines) t(line, size: 9, color: _muted),
        t('Generated: $stamp', size: 9, color: _muted),
      ],
    ),
    if (report.customer != null) ...[
      pw.SizedBox(height: 6),
      t(
        'Customer: ${report.customer!.name}  ·  ${report.customer!.phone}',
        size: 10,
        bold: true,
      ),
    ],
    pw.SizedBox(height: 12),
    if (report.isEmpty)
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: t(
          tr('No Khata records match the selected filters.'),
          size: 11,
          color: _muted,
        ),
      )
    else ...[
      summaryBlock(),
      pw.SizedBox(height: 12),
      customerBalancesBlock(),
      pw.SizedBox(height: 14),
      t(tr('Khata transactions'), size: 13, bold: true, color: _brand),
      pw.SizedBox(height: 6),
      for (final tx in report.transactions)
        // A block that fits on a page is moved whole to the next page
        // rather than being cut; very long ones may split.
        tx.lines.length <= _keepTogetherMaxLines
            ? pw.Wrap(children: [transactionBlock(tx)])
            : transactionBlock(tx),
      ...historyBlock(),
      pw.SizedBox(height: 6),
      pw.Divider(color: _line),
      t(tr('Final summary'), size: 13, bold: true, color: _brand),
      pw.SizedBox(height: 4),
      t(
        '${report.count} transaction${report.count == 1 ? '' : 's'} exported '
        '(${report.pendingCount} pending, ${report.partialCount} partially paid, ${report.clearedCount} cleared).',
        size: 9,
      ),
      pw.SizedBox(height: 4),
      totalsRow(tr('Total sales on credit'), rs(report.totalSales)),
      totalsRow(tr('Total discounts'), '- ${rs(report.totalDiscount)}'),
      totalsRow(tr('Grand total'), rs(report.totalGrand), strong: true),
      totalsRow(tr('Total amount paid'), rs(report.totalPaid)),
      totalsRow(
        tr('Total outstanding'),
        rs(report.totalOutstanding),
        strong: true,
        color: report.totalOutstanding > 0 ? _due : _brand,
      ),
    ],
  ];

  // Pass 1: collect the Urdu strings; render them; pass 2: build for real.
  t = collecting;
  body();
  for (final e in needed.entries) {
    final img = await renderTextImage(
      e.value.text,
      bold: e.value.bold,
      colorValue: e.value.color,
    );
    images[e.key] = (pw.MemoryImage(img.png), img);
  }
  t = real;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: t(
                '${report.business.name} · ${report.title}',
                size: 8,
                color: _muted,
              ),
            ),
            t(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              size: 8,
              color: _muted,
            ),
          ],
        ),
      ),
      build: (ctx) => body(),
    ),
  );

  return doc.save();
}
