import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Brand splash screen.
/// Matches the design system and design language in `Updated Khata Management.html`
/// and the brand design assets:
/// - Deep brand gradient with floating aurora atmosphere blobs.
/// - Ruled ledger paper grid lines (32px horizontal, 56px vertical margin).
/// - Glassmorphic squircle icon container with dynamic glow, floating micro-motion,
///   and entrance zoom animation.
/// - High-contrast crisp Khata mark (ink on paper) with subtle light sheen.
/// - Bricolage Grotesque display typography and Instrument Sans subtext.
/// - Glassmorphic pill loading indicator with smooth gradient progress bar.
class SplashScreen extends StatefulWidget {
  final String? message;
  const SplashScreen({super.key, this.message});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Staggered entrance animations
  late final AnimationController _entranceController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _loadingSlide;
  late final Animation<double> _loadingOpacity;

  // Ambient micro-motion loops
  late final AnimationController _floatController;
  late final Animation<double> _floatY;

  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;

  late final AnimationController _driftController;
  late final Animation<double> _driftValue;

  late final AnimationController _sheenController;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (1200ms total sequence)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Icon zoom: 0ms -> 800ms with spring curve cubic(.2, .9, .25, 1.25)
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.67, curve: Cubic(0.2, 0.9, 0.25, 1.25)),
      ),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Text slide up: 350ms -> 950ms with curve cubic(.2, .8, .2, 1)
    _textSlide = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.29, 0.79, curve: Cubic(0.2, 0.8, 0.2, 1.0)),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.29, 0.65, curve: Curves.easeOut),
      ),
    );

    // Loading slide up: 600ms -> 1200ms with curve cubic(.2, .8, .2, 1)
    _loadingSlide = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 1.0, curve: Cubic(0.2, 0.8, 0.2, 1.0)),
      ),
    );
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 0.85, curve: Curves.easeOut),
      ),
    );

    // 2. Ambient floating motion (4.5s ±8px easeInOut)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _floatY = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 3. Ambient glow pulse (3.4s opacity 0.45 ↔ 0.85 easeInOut)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _glowOpacity = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // 4. Ambient aurora drift (16s easeInOut alternate)
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    );
    _driftValue = CurvedAnimation(
      parent: _driftController,
      curve: Curves.easeInOut,
    );

    // 5. Subtle glass sheen sweep (6.0s loop)
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _entranceController.forward();
    _floatController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _driftController.repeat(reverse: true);
    _sheenController.repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _driftController.dispose();
    _sheenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4A38),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Aurora atmosphere background with gentle drift
          RepaintBoundary(
            child: _AuroraBackgroundLayer(drift: _driftValue),
          ),

          // 2. Ruled ledger lines overlay
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _RuledPagePainter()),
            ),
          ),

          // 3. Center branding (Animated glass icon + typography)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedIcon(),
                const SizedBox(height: 28),
                _buildAnimatedText(),
              ],
            ),
          ),

          // 4. Bottom loading section
          Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: _buildAnimatedLoading(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _iconScale,
        _iconOpacity,
        _floatY,
        _glowOpacity,
        _sheenController,
      ]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatY.value),
          child: Transform.scale(
            scale: _iconScale.value,
            child: Opacity(
              opacity: _iconOpacity.value.clamp(0.0, 1.0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Pulsing mint glow halo behind glass
                  Positioned(
                    top: -34,
                    left: -34,
                    right: -34,
                    bottom: -34,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF5CC7A0).withValues(
                                alpha: _glowOpacity.value,
                              ),
                              const Color(0xFF5CC7A0).withValues(
                                alpha: _glowOpacity.value * 0.45,
                              ),
                              const Color(0xFF5CC7A0).withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Glassmorphic squircle container
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D000000), // 30% black
                          blurRadius: 60,
                          offset: Offset(0, 26),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFFFFF), // 12% white
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0x4DFFFFFF), // 30% white
                              width: 1.0,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Subtle top edge highlight rim
                              Positioned(
                                top: 0,
                                left: 16,
                                right: 16,
                                height: 1.0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0x00FFFFFF),
                                        Color(0x66FFFFFF),
                                        Color(0x00FFFFFF),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Inner paper squircle card
                              Container(
                                width: 94,
                                height: 94,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F4EE), // Paper
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x2E000000), // 18% black
                                      blurRadius: 24,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: _KhataMark(
                                    size: 66,
                                    ink: AppColors.brand700,
                                    paper: AppColors.paper,
                                  ),
                                ),
                              ),

                              // Glass diagonal sheen sweep
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _SheenOverlay(
                                    progress: _sheenController.value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlide.value),
          child: Opacity(
            opacity: _textOpacity.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Khata',
            style: AppTypography.display(
              size: 52,
              weight: FontWeight.w800,
              letterSpacing: -0.035,
              height: 1.0,
              color: const Color(0xFFF6F4EE),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khata Management',
            style: AppTypography.text(
              size: 15,
              weight: FontWeight.w500,
              color: const Color(0xFFCFE6DC),
              letterSpacing: 15 * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLoading() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _loadingSlide.value),
          child: Opacity(
            opacity: _loadingOpacity.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LoadingBar(),
          const SizedBox(height: 14),
          Text(
            widget.message ?? 'Loading\u2026',
            style: AppTypography.text(
              size: 13,
              weight: FontWeight.w400,
              color: const Color(0xFFCFE6DC),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Aurora atmospheric background layer with 4 softly drifting glowing blobs
/// and the brand green background gradient.
class _AuroraBackgroundLayer extends StatelessWidget {
  final Animation<double> drift;
  const _AuroraBackgroundLayer({required this.drift});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.6, -1.0), // ~160 deg
          end: Alignment(0.6, 1.0),
          colors: [
            Color(0xFF0F6149),
            Color(0xFF0B4A38),
            Color(0xFF083829),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: drift,
        builder: (context, _) {
          final t = drift.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Blob 1: Mint #2FA57C (top-left)
              Positioned(
                top: -140 + 34 * t,
                left: -120 + 40 * t,
                child: Transform.scale(
                  scale: 1.0 + 0.15 * t,
                  child: _auroraBlob(
                    size: 380,
                    color: const Color(0xFF2FA57C),
                    opacity: 0.55,
                  ),
                ),
              ),

              // Blob 2: Sage/Teal #5CC7A0 (top-right)
              Positioned(
                top: 120 + 40 * t,
                right: -160 - 46 * t,
                child: Transform.scale(
                  scale: 1.08 - 0.14 * t,
                  child: _auroraBlob(
                    size: 340,
                    color: const Color(0xFF5CC7A0),
                    opacity: 0.35,
                  ),
                ),
              ),

              // Blob 3: Warm Amber #F0B577 (bottom-left)
              Positioned(
                bottom: -160 - 44 * t,
                left: -60 + 30 * t,
                child: Transform.scale(
                  scale: 1.0 + 0.12 * t,
                  child: _auroraBlob(
                    size: 380,
                    color: const Color(0xFFF0B577),
                    opacity: 0.22,
                  ),
                ),
              ),

              // Blob 4: Deep Emerald #1C7A5D (bottom-right)
              Positioned(
                bottom: 120 + 40 * t,
                right: -120 - 46 * t,
                child: Transform.scale(
                  scale: 1.08 - 0.14 * t,
                  child: _auroraBlob(
                    size: 260,
                    color: const Color(0xFF1C7A5D),
                    opacity: 0.60,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _auroraBlob({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.65),
                color.withValues(alpha: opacity * 0.2),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle diagonal light sheen that periodically sweeps across the glass card.
class _SheenOverlay extends StatelessWidget {
  final double progress;
  const _SheenOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    // Only sweeps during the first 25% of the 6-second cycle
    if (progress > 0.25) return const SizedBox.shrink();

    final sweepProgress = progress / 0.25;
    // Map 0 -> 1 to -1.4 -> 3.6
    final alignX = -1.4 + sweepProgress * 5.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Align(
        alignment: Alignment(alignX, 0),
        child: FractionallySizedBox(
          widthFactor: 0.45,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.3, -1.0),
                end: Alignment(0.3, 1.0),
                colors: [
                  Color(0x00FFFFFF),
                  Color(0x28FFFFFF), // 16% white glint
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Khata mark (ink on paper book icon).
class _KhataMark extends StatelessWidget {
  final double size;
  final Color ink;
  final Color paper;
  const _KhataMark({
    required this.size,
    required this.ink,
    required this.paper,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _KhataMarkPainter(ink: ink, paper: paper),
    );
  }
}

class _KhataMarkPainter extends CustomPainter {
  final Color ink;
  final Color paper;
  const _KhataMarkPainter({required this.ink, required this.paper});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64.0;

    // Book cover
    final book = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12 * scale, 8 * scale, 40 * scale, 48 * scale),
      Radius.circular(7 * scale),
    );
    canvas.drawRRect(rect, book);

    // Spine groove
    final spine = Paint()
      ..color = paper
      ..strokeWidth = 3 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(22 * scale, 8 * scale),
      Offset(22 * scale, 56 * scale),
      spine,
    );

    // Ledger horizontal entries
    final ruleLine = Paint()
      ..color = paper
      ..strokeWidth = 3 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Line 1
    canvas.drawLine(
      Offset(29 * scale, 22 * scale),
      Offset(44 * scale, 22 * scale),
      ruleLine,
    );
    // Line 2
    canvas.drawLine(
      Offset(29 * scale, 31 * scale),
      Offset(44 * scale, 31 * scale),
      ruleLine,
    );
    // Line 3
    canvas.drawLine(
      Offset(29 * scale, 40 * scale),
      Offset(38 * scale, 40 * scale),
      ruleLine,
    );
  }

  @override
  bool shouldRepaint(covariant _KhataMarkPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.paper != paper;
}

/// Ruled ledger paper grid lines: horizontal lines every 32px and vertical margin at 56px.
class _RuledPagePainter extends CustomPainter {
  const _RuledPagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final horizontalRule = Paint()
      ..color = const Color(0x0FF6F4EE) // rgba(246,244,238, .06)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 32.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horizontalRule);
    }

    final verticalMargin = Paint()
      ..color = const Color(0x1FF6F4EE) // rgba(246,244,238, .12)
      ..strokeWidth = 1.0;

    canvas.drawLine(const Offset(56.0, 0), Offset(56.0, size.height), verticalMargin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Glassmorphic loading pill bar with animated sweeping gradient.
class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const trackWidth = 132.0;
    const trackHeight = 6.0;
    const indicatorWidth = trackWidth * 0.40; // 52.8px

    return Container(
      width: trackWidth,
      height: trackHeight,
      padding: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF), // rgba(255,255,255, 0.12)
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x2EFFFFFF), // rgba(255,255,255, 0.18)
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ).value;

            // Travel from -indicatorWidth to trackWidth + indicatorWidth * 0.5
            final startX = -indicatorWidth;
            final endX = (trackWidth - 2.0) + indicatorWidth * 0.5;
            final currentX = startX + (endX - startX) * t;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: currentX,
                  top: 0,
                  bottom: 0,
                  width: indicatorWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFBFE3D2), // auroraMint #BFE3D2
                          Color(0xFFF6F4EE), // paper #F6F4EE
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
