import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'excel_report.dart';
import 'khata_report.dart';
import 'pdf_report.dart';

enum ReportFormat {
  pdf('PDF', 'pdf', 'application/pdf'),
  excel(
    'Excel',
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  final String label;
  final String extension;
  final String mimeType;
  const ReportFormat(this.label, this.extension, this.mimeType);
}

/// A generated report file, ready to hand to the user.
class ReportFile {
  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  const ReportFile(this.fileName, this.bytes, this.mimeType);
}

/// Hands the file to the user (share sheet → save to Files, WhatsApp, email…).
/// Swappable so tests never open a platform sheet.
typedef ReportSaver = Future<void> Function(ReportFile file);

ReportSaver reportSaver = (file) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}${Platform.pathSeparator}${file.fileName}';
  await File(path).writeAsBytes(file.bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: file.mimeType, name: file.fileName)],
      subject: file.fileName,
    ),
  );
};

Future<ReportFile> generateReport(
  KhataReport report,
  ReportFormat format,
) async {
  final bytes = switch (format) {
    ReportFormat.pdf => await buildPdfReport(report, await ReportFonts.load()),
    ReportFormat.excel => buildExcelReport(report),
  };
  return ReportFile(
    '${report.fileStem}.${format.extension}',
    bytes,
    format.mimeType,
  );
}

/// Generates the report and offers it to the user to save or share.
Future<void> exportReport(KhataReport report, ReportFormat format) async {
  await reportSaver(await generateReport(report, format));
}
