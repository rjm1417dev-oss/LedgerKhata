import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/l10n/catalog.dart';
import 'package:my_first_app/l10n/translator.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/reports/excel_report.dart';
import 'package:my_first_app/reports/khata_report.dart';
import 'package:my_first_app/screens/validators.dart';
import 'package:my_first_app/state/app_state.dart';
import 'package:my_first_app/widgets/buttons.dart';
import 'package:my_first_app/widgets/language_selector.dart';

import 'support/fake_repository.dart';
import 'support/test_setup.dart';

const _business = Business(name: 'Al-Noor Traders', ownerName: 'Bilal Ahmed', phone: '0300 1122334');

class _MemoryStore implements LanguageStore {
  AppLanguage saved;
  _MemoryStore([this.saved = AppLanguage.english]);
  @override
  Future<AppLanguage> load() async => saved;
  @override
  Future<void> save(AppLanguage language) async => saved = language;
}

Set<String> _placeholders(String s) => RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

/// Opens the language popup from the globe in the top bar and picks [target].
Future<void> _pickLanguage(WidgetTester tester, String current, String target) async {
  await tester.tap(find.byType(LanguageButton).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(target).last);
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(WidgetTester tester, KhataRepository repo, {LanguageStore? store}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ignoreFontMetricOverflows();
  await tester.pumpWidget(KhataApp(repository: repo, splashMinimum: Duration.zero, languageStore: store));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AppLocale.language = AppLanguage.english);
  tearDown(() => AppLocale.language = AppLanguage.english);

  group('catalog', () {
    test('every phrase has Roman Urdu and Urdu, with the same placeholders', () {
      for (final e in kCatalog.entries) {
        expect(e.value.roman.trim(), isNotEmpty, reason: e.key);
        expect(e.value.urdu.trim(), isNotEmpty, reason: e.key);
        expect(_placeholders(e.value.roman), _placeholders(e.key), reason: 'Roman Urdu: ${e.key}');
        expect(_placeholders(e.value.urdu), _placeholders(e.key), reason: 'Urdu: ${e.key}');
      }
    });

    test('exact phrases, templates and the English fallback', () {
      const roman = Translator(AppLanguage.romanUrdu);
      const urdu = Translator(AppLanguage.urdu);
      expect(roman.tr('Sign in'), 'Sign In');
      expect(roman.tr('Wrong email or password.'), 'Email ya password ghalat hai.');
      expect(urdu.tr('Wrong email or password.'), 'ای میل یا پاس ورڈ غلط ہے۔');
      // Templates keep the values (names, amounts) untouched.
      expect(roman.tr('Khata saved for Ahmed Raza'), 'Ahmed Raza ka khata save ho gaya');
      expect(urdu.tr('Rs 500 received from Sana'), 'Sana سے Rs 500 جمع ہوئے');
      expect(roman.tr('That payment is more than the outstanding amount (530)'),
          'Yeh raqam baqi raqam se zyada hai (530)');
      // Missing translation: readable English, never blank or a key.
      expect(roman.tr('A brand new sentence'), 'A brand new sentence');
      // English is never altered, and user data passes through.
      expect(const Translator(AppLanguage.english).tr('Sign in'), 'Sign in');
      expect(roman.tr('Muhammad Aslam'), 'Muhammad Aslam');
    });

    test('dates and weekdays follow the language', () {
      final d = DateTime(2026, 9, 30);
      expect(const Translator(AppLanguage.english).dayHeading(d), 'Wednesday, 30 September 2026');
      expect(const Translator(AppLanguage.romanUrdu).dayHeading(d), 'Budh, 30 Sitambar 2026');
      expect(const Translator(AppLanguage.urdu).date(d), '30 ستمبر 2026');
    });

    test('validation messages are all in the catalog', () {
      final messages = [
        phoneError(''), phoneError('1'), emailError(''), emailError('x'), passwordError(''), passwordError('abc'),
      ];
      for (final m in messages) {
        expect(kCatalog.containsKey(m), isTrue, reason: m);
      }
    });
  });

  // Every wording in the source must be in the catalog, so nothing is left in
  // English by accident. New text added without a catalog entry fails here.
  test('every user-facing string in the code has a catalog entry', () {
    final lit = r"""(?:'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)")""";
    final patterns = [
      RegExp(r'\bText\(\s*context\.tr\(\s*' + lit),
      RegExp(r'\bcontext\.tr\(\s*' + lit),
      RegExp(r'\btr\(\s*' + lit),
      RegExp(r'\b(?:label|title|message|hint|hintText|error|confirmLabel|cancelLabel|okLabel|actionLabel|loadingLabel|semanticLabel|placeholder|helper)\s*:\s*' + lit),
      RegExp(r'showApp(?:Toast|AlertDialog|ConfirmDialog)\(\s*(?:context\s*,\s*)?' + lit),
      RegExp(r'RepositoryException\(\s*' + lit),
      RegExp(r'\b_row\(\s*(?:context\s*,\s*)?' + lit),
      RegExp(r'\breturn\s+' + lit + r'\s*;'),
    ];
    final templates = [
      for (final k in kCatalog.keys)
        if (k.contains('{'))
          RegExp('^${k.splitMapJoin(RegExp(r'\{\w+\}'), onMatch: (_) => '\u0000', onNonMatch: RegExp.escape).replaceAll('\u0000', '(.+?)')}\$', dotAll: true),
    ];
    // Not wording: identifiers, number formats and similar.
    const notWording = {'.env', 'Rs', 'Khata Management', 'Khata'};
    bool isWording(String s) {
      if (s.contains('padLeft') || s.contains('context.tr(')) return false;
      final bare = s.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
      return RegExp(r'[A-Za-z]{2}').hasMatch(bare) && !notWording.contains(s) && !RegExp(r'^[a-z_]+$').hasMatch(s) && !s.startsWith(RegExp(r'[<#]|assets/|http|package:'));
    }

    final missing = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final path = f.path;
      if (path.contains('l10n/') || path.contains('/theme/') || path.contains('urdu_text_image') || path.contains('app_icon') || path.contains('/models/') || path.contains('/config/')) continue;
      final src = f.readAsStringSync();
      for (final p in patterns) {
        for (final m in p.allMatches(src)) {
          final raw = (m.group(1) ?? m.group(2))!.replaceAll(r"\'", "'");
          if (!isWording(raw)) continue;
          // Values that are only an interpolation of an already-translated
          // helper, or whose text is built at run time, are covered by the
          // templates; everything else needs an exact entry.
          if (kCatalog.containsKey(raw) || templates.any((t) => t.hasMatch(raw))) continue;
          missing.add('$path: $raw');
        }
      }
    }
    expect(missing.toSet().toList()..sort(), isEmpty, reason: 'Add these to lib/l10n/catalog.dart');
  });

  group('whole app', () {
    testWidgets('registration and login are translated, and the choice applies at once', (tester) async {
      await _pumpApp(tester, FakeRepository());
      // A fresh install opens on Register.
      expect(find.text('Register your business'), findsWidgets);

      await _pickLanguage(tester, 'English', 'Roman Urdu');
      expect(find.text('Apna Karobar Register Karein'), findsWidgets);
      expect(find.text('Register your business'), findsNothing);
      expect(find.text('Karobar Ka Naam'), findsOneWidget);
      expect(find.text('Pehle se account hai?'), findsOneWidget);

      await _pickLanguage(tester, 'Roman Urdu', 'اردو');
      expect(find.text('اپنا کاروبار رجسٹر کریں'), findsWidgets);
      expect(Directionality.of(tester.element(find.text('کاروبار کا نام'))), TextDirection.rtl);

      // Switch to the sign-in screen: it follows the same language.
      await tester.ensureVisible(find.text('سائن اِن').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('سائن اِن').last);
      await tester.pumpAndSettle();
      expect(find.text('خوش آمدید'), findsOneWidget);

      await _pickLanguage(tester, 'اردو', 'English');
      expect(find.text('Welcome back'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('Welcome back'))), TextDirection.ltr);
    });

    testWidgets('validation messages appear in the chosen language, restored from storage', (tester) async {
      await _pumpApp(tester, FakeRepository(), store: _MemoryStore(AppLanguage.romanUrdu));
      expect(find.text('Apna Karobar Register Karein'), findsWidgets);

      await tester.tap(find.text('Account Banayein'));
      await tester.pumpAndSettle();
      expect(find.text('Karobar ka naam likhein'), findsOneWidget);
      expect(find.text('Malik ka naam likhein'), findsOneWidget);
      expect(find.text('Enter your business name'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('after signing in every tab shows the chosen language and Settings can change it', (tester) async {
      final repo = FakeRepository(signedIn: true, business: _business);
      await _pumpApp(tester, repo);
      expect(find.text('No khatas yet'), findsWidgets);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Language'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('English'), findsOneWidget); // the row shows the current language
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      expect(find.text('Select language'), findsOneWidget);
      await tester.tap(find.text('Roman Urdu').last);
      await tester.pumpAndSettle();
      expect(find.text('Select language'), findsNothing); // popup closed
      await tester.scrollUntilVisible(find.text('Zubaan'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Zubaan'), findsOneWidget);
      expect(find.text('Roman Urdu'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Karobar Ka Naam'), -200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Karobar Ka Naam'), findsOneWidget);

      for (final (tab, expected) in [
        ('Dashboard', 'Abhi Koi Khata Nahi'),
        ('Items', 'Abhi Koi Item Nahi'),
        ('Customers', 'Abhi Koi Customer Nahi'),
        ('Khata', 'Abhi Koi Khata Nahi'),
      ]) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(find.text(expected), findsWidgets, reason: tab);
      }
      // The business name is data, not wording.
      expect(find.text('Al-Noor Traders'), findsWidgets);
    });

    testWidgets('toasts and dialogs are translated', (tester) async {
      final repo = FakeRepository(signedIn: true, business: _business);
      await _pumpApp(tester, repo, store: _MemoryStore(AppLanguage.romanUrdu));
      await tester.tap(find.text('Customers').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CircleActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer Save Karein').last);
      await tester.pumpAndSettle();
      expect(find.text('Customer ka naam likhein'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('persistence', () {
    test('the choice is saved and restored on the next start', () async {
      final store = _MemoryStore();
      final first = AppState(FakeRepository(), splashMinimum: Duration.zero, languageStore: store);
      await first.start();
      expect(first.language, AppLanguage.english);
      await first.setLanguage(AppLanguage.urdu);
      expect(store.saved, AppLanguage.urdu);
      expect(AppLocale.language, AppLanguage.urdu);

      AppLocale.language = AppLanguage.english;
      final second = AppState(FakeRepository(), splashMinimum: Duration.zero, languageStore: store);
      await second.start();
      expect(second.language, AppLanguage.urdu);
      expect(AppLocale.language, AppLanguage.urdu); // available outside widgets, e.g. for reports
    });

    test('an unknown stored value falls back to English', () {
      expect(AppLanguage.fromCode('klingon'), AppLanguage.english);
      expect(AppLanguage.fromCode(null), AppLanguage.english);
      expect(AppLanguage.fromCode('romanUrdu'), AppLanguage.romanUrdu);
    });
  });

  group('reports', () {
    test('the Excel export is written in the chosen language', () async {
      final repo = FakeRepository(signedIn: true, business: _business);
      final state = AppState(repo, splashMinimum: Duration.zero);
      await state.start();
      final report = buildKhataReport(
        business: _business,
        customers: state.customers,
        khatas: state.khatas,
        filter: const ReportFilter(),
      );
      String sheetNames(List<int> bytes) =>
          String.fromCharCodes(ZipDecoder().decodeBytes(bytes).findFile('xl/workbook.xml')!.content as List<int>);

      expect(sheetNames(buildExcelReport(report)), contains('Daily Summary'));
      AppLocale.language = AppLanguage.romanUrdu;
      final roman = sheetNames(buildExcelReport(report));
      expect(roman, contains('Roz Ka Hisab'));
      expect(roman, isNot(contains('Daily Summary')));
      expect(report.filter.title, 'Khata Report'.isEmpty ? '' : report.filter.title);
      expect(report.filterLines.first, startsWith('Tareekh:'));
    });
  });
}
