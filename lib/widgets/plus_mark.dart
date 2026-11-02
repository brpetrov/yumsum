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

/// A round orange badge with a plus: the "+" of the wordmark.
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key, this.size = 36});

  final double size;

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
      child: Icon(
        Icons.add_rounded,
        size: size * 0.66,
        color: AppColors.onPrimary,
      ),
    );
  }
}

/// The smiling star that stands for YumSum+ (the sparkles already mean an
/// AI estimate). Made from the logo in `design/plus-star.png`.
class PlusStar extends StatelessWidget {
  const PlusStar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/plus/star.webp',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}

/// The logo's smiling bowl with the YumSum+ star (`design/plus-hero.png`),
/// on a soft orange glow that suits light and dark pages alike.
class PlusHero extends StatelessWidget {
  const PlusHero({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.24),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
      ),
      child: Image.asset('assets/plus/hero.webp', excludeFromSemantics: true),
    );
  }
}
