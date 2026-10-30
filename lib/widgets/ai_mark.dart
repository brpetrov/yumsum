import 'package:flutter/material.dart';

import 'package:lean_streak/core/theme/app_theme.dart';

/// The AI's symbol: the letters AI with a sparkle at the corner, drawn from
/// the display font and an icon so it scales and takes the colour an icon
/// would (a button's foreground, greyed when disabled).
class AiMark extends StatelessWidget {
  const AiMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(
              'AI',
              style: AppTheme.display.copyWith(
                fontSize: size * 0.68,
                height: 1,
                letterSpacing: -size * 0.02,
                color: color,
              ),
            ),
          ),
          Positioned(
            right: -size * 0.06,
            top: -size * 0.06,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: size * 0.42,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
