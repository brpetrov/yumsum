import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';

/// The app's card: a cream surface floating on a soft warm shadow, with no
/// edge. A [gradient] card, like Today's main one, glows in the icon's
/// orange instead. Tappable cards get an ink ripple, plus a pointer cursor
/// and hover on web.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  static const _radius = BorderRadius.all(Radius.circular(AppTheme.cardRadius));

  @override
  Widget build(BuildContext context) {
    final glow = gradient != null && !AppColors.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.surface : null,
        gradient: gradient,
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: glow
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.shadow,
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: AppColors.shadow.a * 0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const RoundedRectangleBorder(borderRadius: _radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
