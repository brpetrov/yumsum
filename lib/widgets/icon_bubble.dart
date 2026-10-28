import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';

/// A soft round bubble behind an icon. Raised ones float on the page like
/// the app bar's buttons; flat ones are tinted, like the card icons.
class IconBubble extends StatelessWidget {
  const IconBubble(
    this.icon, {
    super.key,
    this.size = 40,
    this.raised = false,
    this.color,
    this.background,
  });

  final IconData icon;
  final double size;
  final bool raised;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            background ??
            (raised ? AppColors.surface : AppColors.primaryContainer),
        boxShadow: raised
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: color ?? (raised ? AppColors.textPrimary : AppColors.primary),
      ),
    );
  }
}
