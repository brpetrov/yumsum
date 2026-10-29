import 'dart:math' as math;

import 'package:flutter/material.dart';

const _isWebKitBuild = bool.fromEnvironment('LEANSTREAK_WEBKIT_BUILD');

/// The smiling bowl on the icon's orange tile. The WebKit build (Safari and
/// iOS browsers, CPU-only CanvasKit) draws the bowl instead of decoding the
/// PNG, as the old mark did.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    final pixels = (size * 0.72 * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE08A45), Color(0xFFD2402C)],
        ),
      ),
      child: _isWebKitBuild
          ? const RepaintBoundary(child: CustomPaint(painter: _BowlPainter()))
          : Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              // Decoded at the size it is shown: drawing the 512 px image a
              // fraction of its size leaves jagged edges on the web.
              cacheWidth: pixels,
              cacheHeight: pixels,
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}

/// A simplified bowl, in the coordinates of design/icon-artwork.png, whose
/// drawing spans 205 to 819 on both axes.
class _BowlPainter extends CustomPainter {
  const _BowlPainter();

  static const _brown = Color(0xFFA23419);
  static const _cream = Color(0xFFFCF3E2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.shortestSide / 614;
    canvas.translate(
      (size.width - size.shortestSide) / 2,
      (size.height - size.shortestSide) / 2,
    );
    canvas.scale(scale);
    canvas.translate(-205, -205);

    Paint stroke(double width) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    Paint fill(Color color) => Paint()
      ..isAntiAlias = true
      ..color = color;
    Paint gradient(Rect rect, List<Color> colors, Paint paint) => paint
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect);
    double deg(double d) => d * math.pi / 180;

    // The arc: green on the right, cream to peach on the left over it.
    final arc = Rect.fromCircle(center: const Offset(512, 511), radius: 280);
    canvas.drawArc(
      arc,
      deg(270),
      deg(98.7),
      false,
      gradient(arc, const [Color(0xFF7BE8A1), Color(0xFF38CFA3)], stroke(53)),
    );
    canvas.drawArc(
      arc,
      deg(171.3),
      deg(100.7),
      false,
      gradient(arc, const [Color(0xFFFBE9CF), Color(0xFFFBBA88)], stroke(53)),
    );

    // Steam.
    final steam = stroke(22)..color = const Color(0xFFFBE4C5);
    canvas.drawLine(const Offset(512, 345), const Offset(512, 390), steam);
    canvas.drawLine(const Offset(605, 382), const Offset(582, 413), steam);

    // The back of the rim, then leaves and the egg sitting in the bowl.
    const rim = Rect.fromLTRB(282, 548, 742, 592);
    canvas.drawOval(rim, fill(_cream));
    Path leaf(Offset a, Offset b, Offset c1, Offset c2) => Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, b.dx, b.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, a.dx, a.dy)
      ..close();
    canvas.drawPath(
      leaf(
        const Offset(505, 590),
        const Offset(405, 392),
        const Offset(580, 428),
        const Offset(330, 554),
      ),
      fill(const Color(0xFF1B6A32)),
    );
    canvas.drawPath(
      leaf(
        const Offset(520, 590),
        const Offset(548, 455),
        const Offset(602, 537),
        const Offset(466, 508),
      ),
      fill(const Color(0xFF2F7F3F)),
    );
    canvas.drawPath(
      leaf(
        const Offset(480, 590),
        const Offset(312, 468),
        const Offset(461, 440),
        const Offset(331, 618),
      ),
      fill(const Color(0xFF6EB752)),
    );
    canvas.save();
    canvas.translate(618, 520);
    canvas.rotate(deg(35));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 128, height: 186),
      fill(_cream),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(10, 30), width: 86, height: 116),
      fill(const Color(0xFFFCB81A)),
    );
    canvas.restore();

    // The front of the bowl: foot, then the body hanging from the rim.
    canvas.drawRRect(
      RRect.fromLTRBR(404, 765, 620, 817, const Radius.circular(26)),
      fill(const Color(0xFFF8CFA6)),
    );
    final body = Path()
      ..moveTo(282, 570)
      ..arcTo(rim, math.pi, -math.pi, false)
      ..cubicTo(742, 690, 630, 792, 512, 792)
      ..cubicTo(394, 792, 282, 690, 282, 570)
      ..close();
    canvas.drawPath(
      body,
      gradient(body.getBounds(), const [
        Color(0xFFFCEBD3),
        Color(0xFFF9D9B6),
      ], fill(_cream)),
    );
    canvas.drawArc(rim, 0, math.pi, false, stroke(14)..color = _cream);

    // The face.
    final face = stroke(19)..color = _brown;
    for (final x in [418.0, 604.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, 674), radius: 33),
        deg(188),
        deg(164),
        false,
        face,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(511, 666), radius: 51),
      deg(32),
      deg(116),
      false,
      face,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BowlPainter oldDelegate) => false;
}
