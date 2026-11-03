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
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// The Adaptive formula on Weight & Progress: for YumSum Star, the sum it
/// makes, how well it knows you and this week's result; without it, dimmed,
/// what it would do, and a tap opens the YumSum Star page. Its info button
/// explains it ([showAdaptiveIntro]).
class AdaptiveCard extends ConsumerWidget {
  const AdaptiveCard({super.key, required this.profile});

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

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adaptive formula',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(switch ((plus, on)) {
          (false, _) =>
            'Learns what you really burn from your weigh-ins and adjusts '
                'your target each Monday.',
          (true, false) => 'Off. Switch it on in Plan Settings.',
          (true, true) => adaptiveSumLine(
            AdaptiveFormula.planOf(profile, now: DateTime.now()),
          ),
        }, style: muted),
        if (progress != null) ...[
          const SizedBox(height: 4),
          Text(adaptiveStageLine(progress), style: muted),
        ],
        if (week != null) ...[
          const SizedBox(height: 4),
          Text(week, style: muted),
        ],
      ],
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      onTap: switch ((plus, on)) {
        (false, _) => () => showPlusPaywall(context),
        // Pages swap, so Back still lands on Home.
        (true, false) => () => context.pushReplacement(AppRoutes.planSettings),
        (true, true) => null,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dimmed without YumSum Star: there to see, not to use.
              Opacity(
                opacity: plus ? 1 : 0.5,
                child: const IconBubble(Icons.tune_rounded, size: 38),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Opacity(opacity: plus ? 1 : 0.6, child: details),
              ),
              IconButton(
                tooltip: 'How it works',
                onPressed: () => showAdaptiveIntro(context, ref),
                icon: const Icon(Icons.info_outline_rounded),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (!plus)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const PlusStar(size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Become a Star to switch it on',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
