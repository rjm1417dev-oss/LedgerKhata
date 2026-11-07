import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'data/khata_repository.dart';
import 'data/language_store.dart';
import 'l10n/translator.dart';
import 'data/supabase_khata_repository.dart';
import 'screens/auth_gate.dart';
import 'screens/status_screens.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Env? env;
  try {
    env = await Env.load();
  } on EnvException catch (e) {
    runApp(SetupApp(detail: e.message));
    return;
  }
  if (env == null) {
    runApp(const SetupApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: env.supabaseUrl,
      publishableKey: env.supabaseKey,
    );
  } catch (e) {
    runApp(SetupApp(detail: e.toString()));
    return;
  }

  runApp(
    KhataApp(
      repository: SupabaseKhataRepository(),
      languageStore: PrefsLanguageStore(),
    ),
  );
}

class KhataApp extends StatelessWidget {
  final KhataRepository repository;
  final Duration splashMinimum;
  final LanguageStore? languageStore;

  const KhataApp({
    super.key,
    required this.repository,
    this.languageStore,
    this.splashMinimum = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = AppState(
          repository,
          splashMinimum: splashMinimum,
          languageStore: languageStore,
        );
        unawaited(state.start());
        return state;
      },
      child: MaterialApp(
        title: 'Khata',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Language for the whole app: every screen, dialog and toast sits
        // below this, so changing it updates them all at once and flips the
        // layout to right-to-left for Urdu.
        builder: (context, child) {
          final language = context.select<AppState, AppLanguage>(
            (s) => s.language,
          );
          return LanguageScope(
            language: language,
            child: Directionality(
              textDirection: language.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}

class SetupApp extends StatelessWidget {
  final String? detail;
  const SetupApp({super.key, this.detail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khata',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SetupRequiredScreen(detail: detail),
    );
  }
}
