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

/// A round badge in the icon's orange: a plus by default, or [icon].
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key, this.size = 36, this.icon = Icons.add_rounded});

  final double size;
  final IconData icon;

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
      child: Icon(icon, size: size * 0.66, color: AppColors.onPrimary),
    );
  }
}
