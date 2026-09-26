import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/root_shell.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'splash_screen.dart';
import 'status_screens.dart';

/// Routes on the app status: splash while restoring, sign-in/register when
/// signed out, the tab shell when ready.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    switch (state.status) {
      case AppStatus.starting:
        return const SplashScreen();
      case AppStatus.signedOut:
        return const _AuthFlow();
      case AppStatus.loadFailed:
        return LoadErrorScreen(
          message: state.loadError ?? 'Something went wrong. Please try again.',
          onRetry: state.retryLoad,
          onSignOut: state.signOut,
        );
      case AppStatus.ready:
        return const RootShell();
    }
  }
}

class _AuthFlow extends StatefulWidget {
  const _AuthFlow();

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  bool _register = true;
  String? _notice;

  @override
  Widget build(BuildContext context) {
    if (_register) {
      return RegisterScreen(
        onGoLogin: () => setState(() {
          _register = false;
          _notice = null;
        }),
        onNeedsConfirmation: (email) => setState(() {
          _register = false;
          _notice = 'We sent a confirmation link to $email. Open it, then sign in here.';
        }),
      );
    }
    return LoginScreen(
      notice: _notice,
      onGoRegister: () => setState(() {
        _register = true;
        _notice = null;
      }),
    );
  }
}
