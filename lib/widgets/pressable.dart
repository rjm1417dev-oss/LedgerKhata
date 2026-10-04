import 'package:flutter/material.dart';

/// Replicates the design system's `.press:active { transform: scale(.98) }`
/// tactile feedback without a Material ripple (the mockups are flat/paper,
/// never inky).
class Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const Pressable({super.key, required this.onTap, required this.child});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setDown(true),
      onTapCancel: () => _setDown(false),
      onTapUp: (_) => _setDown(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}
