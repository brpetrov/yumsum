import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';

/// A small round badge with a wheat sprig, on the photo of a recipe high in
/// fibre (`Recipe.highFibre`). Material has no such icon, so it is drawn.
/// With [showLabel], a pill that says what it means, for the recipe page.
class FibreBadge extends StatelessWidget {
  const FibreBadge({super.key, this.size = 28, this.showLabel = false});

  static const text = 'Rich in fibre';

  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final sprig = SizedBox.square(
      dimension: size * 0.6,
      child: CustomPaint(painter: _SprigPainter(AppColors.veryGood)),
    );
    final decoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(size / 2),
      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
    );
    if (showLabel) {
      return Container(
        height: size,
        padding: EdgeInsets.fromLTRB(size * 0.2, 0, 12, 0),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sprig,
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.veryGood,
              ),
            ),
          ],
        ),
      );
    }
    return Tooltip(
      message: text,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: decoration,
        child: sprig,
      ),
    );
  }
}

/// A stem with a leaf on top and three pairs down its sides, in a unit box.
class _SprigPainter extends CustomPainter {
  const _SprigPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width, size.height);
    final fill = Paint()..color = color;
    canvas.drawLine(
      const Offset(0.5, 0.96),
      const Offset(0.5, 0.34),
      Paint()
        ..color = color
        ..strokeWidth = 0.07
        ..strokeCap = StrokeCap.round,
    );

    // A pointed leaf from [base] to [tip], [width] at its widest.
    void leaf(Offset base, Offset tip, double width) {
      final along = tip - base;
      final side =
          Offset(-along.dy, along.dx) / along.distance * width; // perpendicular
      final middle = base + along / 2;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            (middle + side).dx,
            (middle + side).dy,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            (middle - side).dx,
            (middle - side).dy,
            base.dx,
            base.dy,
          ),
        fill,
      );
    }

    leaf(const Offset(0.5, 0.32), const Offset(0.5, 0.02), 0.17);
    for (final y in [0.42, 0.59, 0.76]) {
      for (final direction in [-1, 1]) {
        // Just off the stem, so it shows between each pair.
        final base = Offset(0.5 + direction * 0.05, y);
        const angle = math.pi / 3; // up and out from the stem
        leaf(
          base,
          base + Offset(direction * math.sin(angle), -math.cos(angle)) * 0.3,
          0.13,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SprigPainter oldDelegate) => oldDelegate.color != color;
}
