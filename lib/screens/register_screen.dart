import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class RegisterScreen extends StatefulWidget {
  final VoidCallback onGoLogin;
  final ValueChanged<String> onNeedsConfirmation;

  const RegisterScreen({
    super.key,
    required this.onGoLogin,
    required this.onNeedsConfirmation,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _biz = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  String? get _bizError =>
      _tried && _biz.text.trim().isEmpty ? 'Enter your business name' : null;
  String? get _ownerError =>
      _tried && _owner.text.trim().isEmpty ? 'Enter the owner name' : null;
  String? get _phoneError => _tried ? phoneError(_phone.text) : null;
  String? get _contactError => _tried && _contact.text.trim().isNotEmpty
      ? phoneError(_contact.text)
      : null;
  String? get _emailError => _tried ? emailError(_email.text) : null;
  String? get _passError => _tried && _pass.text.length < 6
      ? 'Password must be at least 6 characters'
      : null;

  bool get _valid =>
      _biz.text.trim().isNotEmpty &&
      _owner.text.trim().isNotEmpty &&
      phoneError(_phone.text) == null &&
      (_contact.text.trim().isEmpty || phoneError(_contact.text) == null) &&
      emailError(_email.text) == null &&
      _pass.text.length >= 6;

  Future<void> _submit() async {
    if (_saving) return;
    if (!_valid) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final email = _email.text.trim();
      final signedIn = await context.read<AppState>().signUp(
        email: email,
        password: _pass.text,
        businessName: _biz.text.trim(),
        ownerName: _owner.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        contactNumber: _contact.text.trim(),
      );
      if (!signedIn && mounted) widget.onNeedsConfirmation(email);
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _biz.dispose();
    _owner.dispose();
    _phone.dispose();
    _address.dispose();
    _contact.dispose();
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
                        'Register your business',
                        style: AppTypography.display(
                          size: 32,
                          weight: FontWeight.w700,
                          letterSpacing: -0.025,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your khatas, customers and items stay private to your business account.',
                        style: AppTypography.text(
                          size: 15,
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        label: 'Business name',
                        controller: _biz,
                        placeholder: 'e.g. Al-Noor Traders',
                        error: _bizError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Owner name',
                        controller: _owner,
                        placeholder: 'Full name',
                        error: _ownerError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Phone number',
                        controller: _phone,
                        placeholder: '03XX XXXXXXX',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\- ]'),
                          ),
                        ],
                        error: _phoneError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Business address (optional)',
                        controller: _address,
                        placeholder: 'Shop, street, city',
                        keyboardType: TextInputType.streetAddress,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Business contact number (optional)',
                        controller: _contact,
                        placeholder: '03XX XXXXXXX',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\- ]'),
                          ),
                        ],
                        error: _contactError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
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
                        placeholder: 'At least 6 characters',
                        obscureText: true,
                        error: _passError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: AppTypography.meta,
                          ),
                          const SizedBox(width: 6),
                          TextLinkButton(
                            label: 'Sign in',
                            onTap: _saving ? null : widget.onGoLogin,
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
                  label: 'Create account',
                  loadingLabel: 'Creating account…',
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
