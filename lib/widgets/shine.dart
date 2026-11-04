import 'package:flutter/material.dart';

/// A white glint that sweeps across [child] three times when it appears,
/// then rests: enough to catch the eye, never a distraction. It shines again
/// when a page that covered it goes away, since Home stays underneath the
/// menu's pages, but not after a dialog or sheet. It lights only what the
/// child draws, so it follows a chip's or the star's own shape. None when
/// the phone asks for less motion.
class Shine extends StatefulWidget {
  const Shine({super.key, required this.child, this.strength = 0.6});

  final Widget child;

  /// How white the glint is at its brightest, from 0 to 1. Small, light
  /// things like the star need more to show.
  final double strength;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  // Made here rather than on first use: with less motion the build never
  // touches them, and making them in dispose would throw.
  late final AnimationController _controller;
  late final CurvedAnimation _sweep;

  /// The page's secondary animation, which only a page pushed on top moves
  /// (a dialog or sheet leaves it alone).
  Animation<double>? _covered;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(count: 3);
    // The sweep takes the first 60%; the rest is a pause before the next.
    _sweep = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final covered = ModalRoute.of(context)?.secondaryAnimation;
    if (covered == _covered) return;
    _covered?.removeStatusListener(_onCovered);
    _covered = covered?..addStatusListener(_onCovered);
  }

  void _onCovered(AnimationStatus status) {
    // The page on top has gone: back in view, so shine again.
    if (status == AnimationStatus.dismissed) {
      _controller
        ..value = 0
        ..repeat(count: 3);
    }
  }

  @override
  void dispose() {
    _covered?.removeStatusListener(_onCovered);
    _sweep.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: widget.strength),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.3, 0.5, 0.7],
          // From off the left edge to off the right.
          transform: _Slide(_sweep.value * 2 - 1),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Moves a gradient sideways by [share] of the box's width.
class _Slide extends GradientTransform {
  const _Slide(this.share);

  final double share;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * share, 0, 0);
}
