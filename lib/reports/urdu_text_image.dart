import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Script ranges that need proper shaping (Urdu / Arabic).
final urduScript = RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');

/// A piece of text drawn to a PNG, with its logical size at the render scale.
class TextImage {
  final Uint8List png;
  final double width;
  final double height;
  const TextImage(this.png, this.width, this.height);
}

/// Font size the images are drawn at; callers scale by `wanted / renderFontSize`.
const renderFontSize = 40.0;

/// Draws [text] with Flutter's text engine, which joins Urdu letters and
/// orders mixed Urdu/English runs correctly — something the PDF library's own
/// text drawing can't do. Used for any PDF text containing Urdu script.
Future<TextImage> renderTextImage(
  String text, {
  required bool bold,
  required int colorValue,
}) async {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'ReportUrdu',
        fontFamilyFallback: const ['ReportSans'],
        fontSize: renderFontSize,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: Color(colorValue),
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();

  const pad = 2.0;
  final w = painter.width + pad * 2;
  final h = painter.height + pad * 2;
  const scale = 2.0; // render at 2x for a crisp print
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  painter.paint(canvas, const Offset(pad, pad));
  final image = await recorder.endRecording().toImage(
    (w * scale).ceil(),
    (h * scale).ceil(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  painter.dispose();
  return TextImage(data!.buffer.asUint8List(), w, h);
}
