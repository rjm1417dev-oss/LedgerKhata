import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_toast.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';
import 'validators.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onGoRegister;
  final String? notice;

  const LoginScreen({super.key, required this.onGoRegister, this.notice});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  String? get _emailError => _tried ? emailError(_email.text) : null;
  String? get _passError =>
      _tried && _pass.text.isEmpty ? 'Enter your password' : null;

  Future<void> _submit() async {
    if (_saving) return;
    if (emailError(_email.text) != null || _pass.text.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await context.read<AppState>().signIn(
        email: _email.text.trim(),
        password: _pass.text,
      );
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.brand700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: AppIcon(
                                AppIconGlyph.khata,
                                size: 24,
                                color: AppColors.paper,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Khata',
                            style: AppTypography.display(
                              size: 22,
                              weight: FontWeight.w800,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Welcome back',
                        style: AppTypography.display(
                          size: 32,
                          weight: FontWeight.w700,
                          letterSpacing: -0.025,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to see your khatas, customers and items.',
                        style: AppTypography.text(
                          size: 15,
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                      if (widget.notice != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.brand50,
                            border: Border.all(color: AppColors.brand200),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            widget.notice!,
                            style: AppTypography.text(
                              size: 14,
                              height: 1.5,
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      AppTextField(
                        label: 'Email',
                        controller: _email,
                        placeholder: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        error: _emailError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        controller: _pass,
                        placeholder: 'Your password',
                        obscureText: true,
                        error: _passError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('New here?', style: AppTypography.meta),
                          const SizedBox(width: 6),
                          TextLinkButton(
                            label: 'Register your business',
                            onTap: _saving ? null : widget.onGoRegister,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: PrimaryButton(
                  label: 'Sign in',
                  loadingLabel: 'Signing in…',
                  onTap: _submit,
                  loading: _saving,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
