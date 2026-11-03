import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// The Adaptive formula under the weight chart: what it does for you, and
/// with YumSum Star, that it's on, the sum it makes, how well it knows you
/// and this week's result. Without YumSum Star a tap opens the YumSum Star
/// page; switched off in Plan Settings, a tap goes there. Its info button
/// explains it ([showAdaptiveIntro]).
class AdaptiveSection extends ConsumerWidget {
  const AdaptiveSection({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(plusProvider);
    final on = plus && profile.adaptiveOn;
    final progress = on
        ? ref.watch(adaptiveProgressProvider).valueOrNull
        : null;
    final week = on ? ref.watch(adaptiveTodayLineProvider) : null;
    final muted = TextStyle(
      fontSize: 13,
      height: 1.35,
      color: AppColors.textSecondary,
    );

    final section = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Adaptive formula',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'How it works',
                    onPressed: () => showAdaptiveIntro(context, ref),
                    icon: const Icon(Icons.info_outline_rounded),
                    iconSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (plus)
              StatusPill(
                label: on ? 'On' : 'Off',
                color: on ? AppColors.veryGood : AppColors.textSecondary,
              ),
          ],
        ),
        Text(
          'Tunes your target to your own body, from your weigh-ins and '
          'meals.',
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: AppColors.textPrimary,
          ),
        ),
        if (on) ...[
          const SizedBox(height: 6),
          Text(
            adaptiveSumLine(
              AdaptiveFormula.planOf(profile, now: DateTime.now()),
            ),
            style: muted,
          ),
          if (progress != null) ...[
            const SizedBox(height: 4),
            Text(adaptiveStageLine(progress), style: muted),
          ],
          if (week != null) ...[
            const SizedBox(height: 4),
            Text(week, style: muted),
          ],
        ] else if (plus) ...[
          const SizedBox(height: 6),
          Text('Off. Switch it on in Plan Settings.', style: muted),
        ] else ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const PlusStar(size: 24),
              const SizedBox(width: 8),
              Text(
                'Become a Star to unlock it',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    final onTap = switch ((plus, on)) {
      (false, _) => () => showPlusPaywall(context),
      // Pages swap, so Back still lands on Home.
      (true, false) => () => context.pushReplacement(AppRoutes.planSettings),
      (true, true) => null,
    };
    if (onTap == null) return section;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: section,
    );
  }
}
