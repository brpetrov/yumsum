import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/shine.dart';

/// The Adaptive formula under the weight chart. With YumSum Star it's always
/// on: a shining "On" chip, what you burn as it has learnt it, the target
/// that follows, how well it knows you and this week's result, and an info
/// button ([showAdaptiveIntro]). Without it, an inviting button that opens
/// the same dialog, offering to enable it.
class AdaptiveSection extends ConsumerWidget {
  const AdaptiveSection({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(plusProvider)) {
      void open() => showAdaptiveIntro(context, plus: false);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TryButton(label: 'Adaptive formula', onTap: open),
              const SizedBox(height: 12),
              Text(
                'A customised formula tailored just for you. Adapting with '
                'time and your weigh-ins.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progress = ref.watch(adaptiveProgressProvider).valueOrNull;
    final week = ref.watch(adaptiveTodayLineProvider);
    final learnt =
        (progress != null && progress.hold == null) ||
        profile.adaptiveKcal != 0;
    final muted = TextStyle(
      fontSize: 13,
      height: 1.35,
      color: AppColors.textSecondary,
    );

    return Column(
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
                  const SizedBox(width: 8),
                  const _OnChip(),
                ],
              ),
            ),
            IconButton(
              tooltip: 'How it works',
              onPressed: () => showAdaptiveIntro(context),
              icon: const Icon(Icons.info_outline_rounded),
              iconSize: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _Fact(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.veryGood,
          before: 'You burn ',
          kcal: adaptiveBurn(profile, progress),
          note: learnt
              ? 'Learnt from your weigh-ins and meals.'
              : 'A first estimate. It learns as you weigh in.',
        ),
        const SizedBox(height: 12),
        _Fact(
          icon: Icons.flag_rounded,
          color: AppColors.primary,
          before: 'Your target is ',
          kcal: profile.dailyCalorieTarget.round(),
          note: profile.weightLossPace == WeightLossPace.maintain
              ? 'To keep your weight steady.'
              : 'To lose '
                    '${NumberFormat('0.0#').format(profile.goalPaceKgPerWeek)}'
                    ' kg a week.',
        ),
        if (progress != null) ...[
          if (adaptivePausedLine(progress) case final paused?) ...[
            const SizedBox(height: 12),
            Text(paused, style: muted),
          ],
        ],
        if (week != null) ...[
          const SizedBox(height: 4),
          Text(week, style: muted),
        ],
      ],
    );
  }
}

/// The green "On" chip, with a [Shine] across it when it appears.
class _OnChip extends StatelessWidget {
  const _OnChip();

  @override
  Widget build(BuildContext context) {
    // Solid green, so the white glint shows.
    return Shine(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.veryGood,
              Color.lerp(AppColors.veryGood, Colors.white, 0.22)!,
            ],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              'On',
              style: AppTheme.display.copyWith(
                fontSize: 14,
                height: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One plain sentence with its number big, an icon beside it and a short
/// note under it: "You burn 2440 kcal a day".
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.color,
    required this.before,
    required this.kcal,
    required this.note,
  });

  final IconData icon;
  final Color color;
  final String before;
  final int kcal;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBubble(
          icon,
          size: 36,
          color: color,
          background: color.withValues(alpha: 0.14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: before),
                    TextSpan(
                      text: '$kcal kcal',
                      style: AppTheme.display.copyWith(
                        fontSize: 18,
                        color: tintedTextColor(color),
                      ),
                    ),
                    const TextSpan(text: ' a day'),
                  ],
                ),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                note,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
