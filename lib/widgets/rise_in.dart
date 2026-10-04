import 'package:flutter/material.dart';

/// Enters once, when the row first appears: fade plus 16 px rise on the
/// design's curve, staggered 65 ms per row for the first ten. Skipped when the
/// OS asks for reduced motion.
class RiseIn extends StatefulWidget {
  final int index;
  final Widget child;

  const RiseIn({super.key, required this.index, required this.child});

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  static const _curve = Cubic(0.2, 0.8, 0.2, 1);
  static const _duration = 600;
  static const _step = 65;

  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay = widget.index.clamp(0, 9) * _step;
    final total = _duration + delay;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / total, 1, curve: _curve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _progress,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_progress),
        child: widget.child,
      ),
    );
  }
}
