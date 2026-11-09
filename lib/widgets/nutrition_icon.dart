import 'package:flutter/material.dart';

/// Material Symbols' "nutrition" (an apple), drawn here as Flutter's own
/// icons don't have it.
class NutritionIcon extends StatelessWidget {
  const NutritionIcon({super.key, this.size = 24, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _NutritionPainter(color)),
  );
}

class _NutritionPainter extends CustomPainter {
  const _NutritionPainter(this.color);

  final Color color;

  // The symbol's path on its 960 grid.
  static final _path = Path()
    ..moveTo(281.5, 758.5)
    ..quadraticBezierTo(200, 677, 200, 560)
    ..quadraticBezierTo(200, 466, 255.5, 391.5)
    ..quadraticBezierTo(311, 317, 401, 291)
    ..quadraticBezierTo(381, 286, 362, 276.5)
    ..quadraticBezierTo(343, 267, 328, 252)
    ..quadraticBezierTo(295, 219, 285.5, 173.5)
    ..quadraticBezierTo(276, 128, 281, 81)
    ..quadraticBezierTo(328, 76, 373.5, 85.5)
    ..quadraticBezierTo(419, 95, 452, 128)
    ..quadraticBezierTo(475, 151, 485.5, 180)
    ..quadraticBezierTo(496, 209, 499, 241)
    ..quadraticBezierTo(512, 210, 530.5, 182.5)
    ..quadraticBezierTo(549, 155, 572, 132)
    ..quadraticBezierTo(583, 121, 600, 121)
    ..quadraticBezierTo(617, 121, 628, 132)
    ..quadraticBezierTo(639, 143, 639, 160)
    ..quadraticBezierTo(639, 177, 628, 188)
    ..quadraticBezierTo(606, 210, 589, 236.5)
    ..quadraticBezierTo(572, 263, 564, 293)
    ..quadraticBezierTo(652, 321, 706, 394.5)
    ..quadraticBezierTo(760, 468, 760, 560)
    ..quadraticBezierTo(760, 677, 678.5, 758.5)
    ..quadraticBezierTo(597, 840, 480, 840)
    ..quadraticBezierTo(363, 840, 281.5, 758.5)
    ..close()
    ..moveTo(621.5, 701.5)
    ..quadraticBezierTo(680, 643, 680, 560)
    ..quadraticBezierTo(680, 477, 621.5, 418.5)
    ..quadraticBezierTo(563, 360, 480, 360)
    ..quadraticBezierTo(397, 360, 338.5, 418.5)
    ..quadraticBezierTo(280, 477, 280, 560)
    ..quadraticBezierTo(280, 643, 338.5, 701.5)
    ..quadraticBezierTo(397, 760, 480, 760)
    ..quadraticBezierTo(563, 760, 621.5, 701.5)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 960, size.height / 960);
    canvas.drawPath(_path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NutritionPainter old) => old.color != color;
}
