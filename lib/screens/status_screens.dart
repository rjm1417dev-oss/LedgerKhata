import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';

class _StatusLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;

  const _StatusLayout({required this.title, required this.body, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.dueSoft, borderRadius: BorderRadius.circular(18)),
                    child: const Center(child: AppIcon(AppIconGlyph.error, size: 28, color: AppColors.due, strokeWidth: 1.9)),
                  ),
                  const SizedBox(height: 18),
                  Text(title, style: AppTypography.display(size: 26, weight: FontWeight.w700, letterSpacing: -0.02, height: 1.15)),
                  const SizedBox(height: 10),
                  body,
                  const SizedBox(height: 24),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String text;
  const _Step(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTypography.text(size: 14, height: 1.5, color: AppColors.mutedStrong)),
      );
}

/// Shown instead of the app when `.env` has no usable Supabase credentials.
class SetupRequiredScreen extends StatelessWidget {
  final String? detail;
  const SetupRequiredScreen({super.key, this.detail});

  @override
  Widget build(BuildContext context) {
    return _StatusLayout(
      title: 'Connect Supabase',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The app couldn’t find your Supabase project details.',
            style: AppTypography.text(size: 15, height: 1.5, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          const _Step('1. Open the .env file in the project root.'),
          const _Step('2. Add SUPABASE_URL=https://<your-project>.supabase.co'),
          const _Step('3. Add SUPABASE_ANON_KEY=<your publishable / anon key>'),
          const _Step('4. Save it and restart the app (a full restart, not hot reload).'),
          const _Step('Never put the service_role or secret key here: this file is bundled into the app.'),
          if (detail != null) ...[
            const SizedBox(height: 10),
            Text(detail!, style: AppTypography.text(size: 12, color: AppColors.error)),
          ],
        ],
      ),
      actions: const [],
    );
  }
}

/// Shown when the saved session is valid but loading the data failed
/// (offline, missing tables, ...).
class LoadErrorScreen extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;

  const LoadErrorScreen({super.key, required this.message, required this.onRetry, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return _StatusLayout(
      title: 'Couldn’t load your data',
      body: Text(message, style: AppTypography.text(size: 15, height: 1.5, color: AppColors.muted)),
      actions: [
        PrimaryButton(label: 'Try again', onTap: onRetry),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Sign out', onTap: onSignOut),
      ],
    );
  }
}
