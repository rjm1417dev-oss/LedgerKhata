import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/translator.dart';
import '../state/app_state.dart';

/// Keeps the chosen language on the device. Storage problems never block the
/// app — it just falls back to English.
class PrefsLanguageStore implements LanguageStore {
  static const _key = 'ledger_language';

  @override
  Future<AppLanguage> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppLanguage.fromCode(prefs.getString(_key));
    } catch (_) {
      return AppLanguage.english;
    }
  }

  @override
  Future<void> save(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, language.name);
    } catch (_) {}
  }
}
