import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'catalog.dart';

/// Languages the app can be shown in.
enum AppLanguage {
  english('English'),
  romanUrdu('Roman Urdu'),
  urdu('اردو');

  /// How the language names itself in the picker.
  final String nativeName;
  const AppLanguage(this.nativeName);

  bool get isRtl => this == AppLanguage.urdu;

  static AppLanguage fromCode(String? code) =>
      AppLanguage.values.where((l) => l.name == code).firstOrNull ??
      AppLanguage.english;
}

/// The single place where on-screen wording is converted.
///
/// Source text in the code is English and doubles as the lookup key. A string
/// is translated by, in order:
///   1. an exact match in the catalog;
///   2. a template match, for messages with values in them — the catalog key
///      "Khata saved for {name}" also converts the already-built English
///      "Khata saved for Ahmed", leaving the value itself untouched;
///   3. otherwise the English text itself, so a missing translation shows
///      readable English instead of nothing.
/// User-entered data (names, phones, notes) is never passed through here.
class Translator {
  final AppLanguage language;
  const Translator(this.language);

  String call(String text) => tr(text);

  String tr(String text) {
    if (language == AppLanguage.english || text.isEmpty) return text;
    final exact = kCatalog[text];
    if (exact != null) return _pick(exact);
    for (final t in _templates) {
      final m = t.pattern.firstMatch(text);
      if (m == null) continue;
      var out = _pick(t.entry);
      for (var i = 0; i < t.names.length; i++) {
        out = out.replaceAll('{${t.names[i]}}', m.group(i + 1) ?? '');
      }
      return out;
    }
    return text;
  }

  String _pick(Entry e) => language == AppLanguage.romanUrdu ? e.roman : e.urdu;

  static final List<_Template> _templates =
      [
        for (final e in kCatalog.entries)
          if (e.key.contains('{')) _Template.compile(e.key, e.value),
      ]..sort(
        (a, b) => b.literalLength.compareTo(a.literalLength),
      ); // most specific first

  /// Short month for dates, e.g. "Oct" / "Aktoobar" / "اکتوبر".
  String shortMonth(int month) => switch (language) {
    AppLanguage.english => _en[month - 1],
    AppLanguage.romanUrdu => _roman[month - 1].substring(0, 3),
    AppLanguage.urdu => _ur[month - 1],
  };

  String fullMonth(int month) => switch (language) {
    AppLanguage.english => _enFull[month - 1],
    AppLanguage.romanUrdu => _roman[month - 1],
    AppLanguage.urdu => _ur[month - 1],
  };

  String weekday(int weekday) => switch (language) {
    AppLanguage.english => _enDays[weekday - 1],
    AppLanguage.romanUrdu => _romanDays[weekday - 1],
    AppLanguage.urdu => _urDays[weekday - 1],
  };

  /// "30 Sep 2026".
  String date(DateTime d) => '${d.day} ${shortMonth(d.month)} ${d.year}';

  /// "3:42 PM" (digits and AM/PM stay as they are in every language).
  String time(DateTime d) => DateFormat('h:mm a').format(d);

  /// "30 Sep 2026, 3:42 PM".
  String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  /// "Wednesday, 30 September 2026".
  String dayHeading(DateTime d) =>
      '${weekday(d.weekday)}, ${d.day} ${fullMonth(d.month)} ${d.year}';

  static const _en = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _enFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _roman = [
    'Janwari',
    'Farwari',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'Sitambar',
    'Aktoobar',
    'Navambar',
    'Disambar',
  ];
  static const _ur = [
    'جنوری',
    'فروری',
    'مارچ',
    'اپریل',
    'مئی',
    'جون',
    'جولائی',
    'اگست',
    'ستمبر',
    'اکتوبر',
    'نومبر',
    'دسمبر',
  ];
  static const _enDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _romanDays = [
    'Peer',
    'Mangal',
    'Budh',
    'Jumeraat',
    'Jumma',
    'Hafta',
    'Itwaar',
  ];
  static const _urDays = [
    'پیر',
    'منگل',
    'بدھ',
    'جمعرات',
    'جمعہ',
    'ہفتہ',
    'اتوار',
  ];
}

class _Template {
  final RegExp pattern;
  final List<String> names;
  final Entry entry;
  final int literalLength;
  const _Template(this.pattern, this.names, this.entry, this.literalLength);

  factory _Template.compile(String key, Entry entry) {
    final names = <String>[];
    final buffer = StringBuffer('^');
    var literal = 0;
    var i = 0;
    while (i < key.length) {
      if (key[i] == '{') {
        final end = key.indexOf('}', i);
        names.add(key.substring(i + 1, end));
        buffer.write('(.+?)');
        i = end + 1;
      } else {
        buffer.write(RegExp.escape(key[i]));
        literal++;
        i++;
      }
    }
    buffer.write(r'$');
    return _Template(
      RegExp(buffer.toString(), dotAll: true),
      names,
      entry,
      literal,
    );
  }
}

/// The language in force, for code that has no BuildContext (reports,
/// repository messages, date helpers). Widgets should prefer `context.tr`,
/// which also rebuilds them when the language changes.
class AppLocale {
  AppLocale._();
  static AppLanguage language = AppLanguage.english;
  static Translator get translator => Translator(language);
}

/// Converts [text] using the language in force. See [Translator].
String tr(String text) => AppLocale.translator.tr(text);

/// Provides the language to the widget tree. Widgets that read it through
/// `context.tr` are rebuilt automatically when it changes, and the layout
/// flips to right-to-left (with an Urdu-capable font) for Urdu.
class LanguageScope extends InheritedWidget {
  final AppLanguage language;

  const LanguageScope({
    super.key,
    required this.language,
    required super.child,
  });

  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.language ??
      AppLanguage.english;

  @override
  bool updateShouldNotify(LanguageScope old) => old.language != language;
}

extension TranslateContext on BuildContext {
  /// The app's selected language (rebuilds the caller when it changes).
  AppLanguage get language => LanguageScope.of(this);

  Translator get translator => Translator(language);

  /// Converts on-screen wording to the selected language.
  String tr(String text) => translator.tr(text);
}
