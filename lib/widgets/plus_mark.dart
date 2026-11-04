import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/widgets/shine.dart';

/// The YumSum Star wordmark, with "Star" in the icon's orange. (The code
/// calls the paid tier "plus", from before it had a name.)
class PlusMark extends StatelessWidget {
  const PlusMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'YumSum ',
        children: [
          TextSpan(
            text: 'Star',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
      style: AppTheme.display.copyWith(
        fontSize: size,
        height: 1.1,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// The smiling star that stands for YumSum Star (the sparkles already mean
/// an AI estimate). Made from the logo in `design/plus-star.png`.
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

/// YumSum Star at a glance, beside the logo in the menu and the name on Home: the
/// star for members, with a [Shine] when it appears, and a "Become a Star"
/// chip for everyone else. Nothing while the account loads, so a member
/// never sees the chip flash.
class StarBadge extends ConsumerWidget {
  const StarBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(entitlementProvider).hasValue) {
      return const SizedBox.shrink();
    }
    if (ref.watch(plusProvider)) {
      return Tooltip(
        message: 'YumSum Star',
        child: InkResponse(
          onTap: onTap,
          radius: 20,
          child: const Shine(strength: 0.9, child: PlusStar(size: 28)),
        ),
      );
    }
    return Material(
      color: AppColors.primaryContainer,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PlusStar(size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Become a Star',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display.copyWith(
                    fontSize: 14,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The logo's smiling bowl with its star (`design/plus-hero.png`), on a soft
/// orange glow that suits light and dark pages alike.
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
