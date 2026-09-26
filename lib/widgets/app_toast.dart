import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Top toast: dark surface, success check, 2.6s per the Feedback spec.
void showAppToast(BuildContext context, String message, {bool isError = false}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ToastWidget(
      message: message,
      isError: isError,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDone;

  const _ToastWidget({required this.message, required this.isError, required this.onDone});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _visible = false);
    });
    Future.delayed(const Duration(milliseconds: 2900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.of(context).padding.top + 16,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.r14),
                boxShadow: const [BoxShadow(color: Color(0x40161816), blurRadius: 32, offset: Offset(0, 12))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    widget.isError ? AppIconGlyph.error : AppIconGlyph.success,
                    size: 20,
                    color: widget.isError ? const Color(0xFFFF8A80) : AppColors.successCheck,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: AppTypography.text(size: 14, weight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
