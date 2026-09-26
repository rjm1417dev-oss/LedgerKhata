import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests run with Flutter's placeholder "Ahem" font (google_fonts can't
/// download the real ones), where every glyph is a full-width square, so text
/// looks roughly twice as wide as in the app. Overflow reports are therefore
/// meaningless here; every other framework error still fails the test.
void ignoreFontMetricOverflows() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}
