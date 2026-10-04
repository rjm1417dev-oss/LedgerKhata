import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/khata_repository.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/screen_header.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_toast.dart';
import '../widgets/avatar.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';
import 'validators.dart';
import '../widgets/glass.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _uploadingLogo = false;

  void _openEditSheet(BuildContext context, Business business) {
    showAppBottomSheet(
      context: context,
      title: 'Edit business',
      builder: (_) => _BusinessForm(existing: business),
    );
  }

  Future<void> _pickAndUploadLogo() async {
    final appState = context.read<AppState>();
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) {
        showAppToast(context, 'Couldn’t open the photo picker.', isError: true);
      }
      return;
    }
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';

    setState(() => _uploadingLogo = true);
    try {
      await appState.uploadBusinessLogo(bytes: bytes, fileExtension: ext);
      if (mounted) showAppToast(context, 'Logo updated');
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final business = state.business;
    final initials = initialsOf(business?.name ?? '');

    return AuroraBackground(
      child: Column(
        children: [
          ScreenHeader(businessName: business?.name ?? '', title: 'Settings'),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'BUSINESS',
                    style: AppTypography.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.06 * 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            _LogoAvatar(
                              logoUrl: business?.logoUrl,
                              initials: initials,
                              uploading: _uploadingLogo,
                              onTap: business == null
                                  ? null
                                  : _pickAndUploadLogo,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    business?.name ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.text(
                                      size: 17,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Business account',
                                    style: AppTypography.meta,
                                  ),
                                ],
                              ),
                            ),
                            if (business != null)
                              IconButtonGhost(
                                icon: AppIconGlyph.edit,
                                onTap: () => _openEditSheet(context, business),
                                semanticLabel: 'Edit business details',
                                color: AppColors.brand700,
                                backgroundColor: AppColors.brand100,
                              ),
                          ],
                        ),
                      ),
                      _row('Business name', business?.name ?? ''),
                      _row('Owner name', business?.ownerName ?? ''),
                      _row('Phone number', business?.phone ?? ''),
                      _row('Address', business?.address ?? 'Not set'),
                      _row(
                        'Public contact number',
                        business?.contactNumber ?? 'Not set',
                      ),
                      _row('Email', state.email ?? '', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DestructiveButton(
                  label: 'Sign out',
                  onTap: () async {
                    try {
                      await state.signOut();
                    } on RepositoryException catch (e) {
                      if (context.mounted) {
                        showAppToast(context, e.message, isError: true);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.text(size: 14, color: AppColors.muted),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.text(size: 15, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Business logo, tappable to upload a new one. Falls back to the business's
/// initials when no logo has been set yet or the image fails to load.
class _LogoAvatar extends StatelessWidget {
  final String? logoUrl;
  final String initials;
  final bool uploading;
  final VoidCallback? onTap;

  const _LogoAvatar({
    required this.logoUrl,
    required this.initials,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Change business logo',
      button: true,
      child: GestureDetector(
        onTap: uploading ? null : onTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: logoUrl == null
                  ? InitialsAvatar(initials: initials, size: 48, solid: true)
                  : Image.network(
                      logoUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          InitialsAvatar(
                            initials: initials,
                            size: 48,
                            solid: true,
                          ),
                    ),
            ),
            if (uploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BusinessForm extends StatefulWidget {
  final Business existing;
  const _BusinessForm({required this.existing});

  @override
  State<_BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends State<_BusinessForm> {
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _contactNumber = TextEditingController();
  bool _tried = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _name.text = b.name;
    _ownerName.text = b.ownerName;
    _phone.text = b.phone;
    _address.text = b.address ?? '';
    _contactNumber.text = b.contactNumber ?? '';
  }

  String? get _nameError =>
      _tried && _name.text.trim().isEmpty ? 'Enter your business name' : null;
  String? get _ownerNameError =>
      _tried && _ownerName.text.trim().isEmpty ? 'Enter the owner name' : null;
  String? get _phoneError => _tried ? phoneError(_phone.text) : null;
  String? get _contactNumberError =>
      (_tried && _contactNumber.text.trim().isNotEmpty)
      ? phoneError(_contactNumber.text)
      : null;

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty ||
        _ownerName.text.trim().isEmpty ||
        phoneError(_phone.text) != null ||
        _contactNumberError != null) {
      setState(() => _tried = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await context.read<AppState>().updateBusiness(
        name: _name.text.trim(),
        ownerName: _ownerName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        contactNumber: _contactNumber.text.trim().isEmpty
            ? null
            : _contactNumber.text.trim(),
      );
      if (!mounted) return;
      showAppToast(context, 'Business details updated');
      Navigator.of(context).pop();
    } on RepositoryException catch (e) {
      if (mounted) showAppToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _address.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Business name',
          controller: _name,
          placeholder: 'Your shop name',
          error: _nameError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Owner name',
          controller: _ownerName,
          placeholder: 'Full name',
          error: _ownerNameError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Phone number',
          controller: _phone,
          placeholder: '03XX XXXXXXX',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
          ],
          error: _phoneError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Address (optional)',
          controller: _address,
          placeholder: 'Shop address',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Public contact number (optional)',
          controller: _contactNumber,
          placeholder: '03XX XXXXXXX',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
          ],
          error: _contactNumberError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Cancel',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Save changes',
                onTap: _save,
                loading: _saving,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
