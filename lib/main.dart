import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'data/khata_repository.dart';
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
    await Supabase.initialize(url: env.supabaseUrl, publishableKey: env.supabaseKey);
  } catch (e) {
    runApp(SetupApp(detail: e.toString()));
    return;
  }

  runApp(KhataApp(repository: SupabaseKhataRepository()));
}

class KhataApp extends StatelessWidget {
  final KhataRepository repository;
  final Duration splashMinimum;

  const KhataApp({
    super.key,
    required this.repository,
    this.splashMinimum = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = AppState(repository, splashMinimum: splashMinimum);
        unawaited(state.start());
        return state;
      },
      child: MaterialApp(
        title: 'Khata',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
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
