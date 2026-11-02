import 'dart:math';

import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';

/// The YumSum+ wordmark: "YumSum" with the plus as a small orange badge.
class PlusMark extends StatelessWidget {
  const PlusMark({super.key, this.size = 20});

  /// The text size; the badge follows it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'YumSum+',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'YumSum',
            style: AppTheme.display.copyWith(
              fontSize: size,
              height: 1.1,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: size * 0.2),
          PlusBadge(size: size * 0.95),
        ],
      ),
    );
  }
}

/// A round badge in the icon's orange: a plus, or with [star] the smiling
/// star that stands for YumSum+ (the sparkles already mean an AI estimate).
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key, this.size = 36, this.star = false});

  final double size;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: star
          ? CustomPaint(painter: _SmilingStarPainter(AppColors.onPrimary))
          : Icon(
              Icons.add_rounded,
              size: size * 0.66,
              color: AppColors.onPrimary,
            ),
    );
  }
}

/// A rounded five-pointed star with a smiling face, in outline, like
/// Material Symbols' "family star", which Flutter's icon font lacks.
class _SmilingStarPainter extends CustomPainter {
  const _SmilingStarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.34;
    // A star's middle sits below its box's, under the top point.
    final c = size.center(Offset(0, r * 0.08));
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.17
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final corners = [
      for (var i = 0; i < 10; i++)
        c + Offset.fromDirection(-pi / 2 + i * pi / 5, i.isEven ? r : r * 0.52),
    ];
    final star = Path();
    for (final (i, corner) in corners.indexed) {
      // Points are rounded more than the dips between them.
      final t = i.isEven ? 0.24 : 0.12;
      final from = Offset.lerp(corner, corners[(i + 9) % 10], t)!;
      final to = Offset.lerp(corner, corners[(i + 1) % 10], t)!;
      if (i == 0) {
        star.moveTo(from.dx, from.dy);
      } else {
        star.lineTo(from.dx, from.dy);
      }
      star.quadraticBezierTo(corner.dx, corner.dy, to.dx, to.dy);
    }
    canvas.drawPath(star..close(), line);

    final eye = Paint()..color = color;
    canvas.drawCircle(c + Offset(-r * 0.2, -r * 0.02), r * 0.085, eye);
    canvas.drawCircle(c + Offset(r * 0.2, -r * 0.02), r * 0.085, eye);
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(0, r * 0.04), radius: r * 0.2),
      pi * 0.22,
      pi * 0.56,
      false,
      line..strokeWidth = r * 0.13,
    );
  }

  @override
  bool shouldRepaint(_SmilingStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
