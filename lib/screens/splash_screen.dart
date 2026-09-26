import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Brand splash. The auth gate shows it while the saved session and the
/// business data are being restored, so there is nothing to tap or wait on.
class SplashScreen extends StatelessWidget {
  final String? message;
  const SplashScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand700,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RuledPagePainter())),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 20))],
                  ),
                  child: const Center(child: _KhataMark(size: 72, ink: AppColors.brand700, paper: AppColors.paper)),
                ),
                const SizedBox(height: 22),
                Text(
                  'Khata',
                  style: AppTypography.display(size: 48, weight: FontWeight.w800, letterSpacing: -0.03, height: 1, color: AppColors.paper),
                ),
                const SizedBox(height: 6),
                Text(
                  'Khata Management',
                  style: AppTypography.text(size: 15, weight: FontWeight.w500, color: const Color(0xFFCFE6DC), letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: Column(
              children: [
                const _LoadingBar(),
                const SizedBox(height: 14),
                Text(message ?? 'Loading\u2026', style: AppTypography.text(size: 13, color: const Color(0xFFCFE6DC))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KhataMark extends StatelessWidget {
  final double size;
  final Color ink;
  final Color paper;
  const _KhataMark({required this.size, required this.ink, required this.paper});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _KhataMarkPainter(ink: ink, paper: paper));
  }
}

class _KhataMarkPainter extends CustomPainter {
  final Color ink;
  final Color paper;
  const _KhataMarkPainter({required this.ink, required this.paper});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    final book = Paint()..color = ink;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12 * scale, 8 * scale, 40 * scale, 48 * scale),
      Radius.circular(7 * scale),
    );
    canvas.drawRRect(rect, book);

    final spine = Paint()
      ..color = paper
      ..strokeWidth = 3 * scale;
    canvas.drawLine(Offset(22 * scale, 8 * scale), Offset(22 * scale, 56 * scale), spine);

    final ruleLine = Paint()
      ..color = paper
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(29 * scale, 22 * scale), Offset(44 * scale, 22 * scale), ruleLine);
    canvas.drawLine(Offset(29 * scale, 31 * scale), Offset(44 * scale, 31 * scale), ruleLine);
    canvas.drawLine(Offset(29 * scale, 40 * scale), Offset(38 * scale, 40 * scale), ruleLine);
  }

  @override
  bool shouldRepaint(covariant _KhataMarkPainter oldDelegate) => oldDelegate.ink != ink || oldDelegate.paper != paper;
}

class _RuledPagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = const Color(0x12F6F4EE)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
    final margin = Paint()
      ..color = const Color(0x24F6F4EE)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(64, 0), Offset(64, size.height), margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          color: const Color(0x2EF6F4EE),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Align(
                alignment: Alignment(-1 + t * 3.4, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  child: Container(color: AppColors.paper),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
