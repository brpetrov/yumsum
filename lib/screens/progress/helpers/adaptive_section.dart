import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/units_provider.dart';
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
    final l10n = context.l10n;
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
              TryButton(label: l10n.adaptiveTitle, onTap: open),
              const SizedBox(height: 12),
              Text(
                l10n.adaptiveTryNote,
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
                      l10n.adaptiveTitle,
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
              tooltip: l10n.adaptiveHowItWorks,
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
          sentence: l10n.adaptiveBurnFact,
          kcal: adaptiveBurn(profile, progress),
          note: learnt ? l10n.adaptiveBurnLearnt : l10n.adaptiveBurnFirst,
        ),
        const SizedBox(height: 12),
        _Fact(
          icon: Icons.flag_rounded,
          color: AppColors.primary,
          sentence: l10n.adaptiveTargetFact,
          kcal: profile.dailyCalorieTarget.round(),
          note: profile.weightLossPace == WeightLossPace.maintain
              ? l10n.adaptiveTargetKeep
              : l10n.adaptiveTargetLose(
                  formatPace(
                    profile.goalPaceKgPerWeek,
                    ref.watch(weightUnitProvider),
                    l10n,
                  ),
                ),
        ),
        if (progress != null) ...[
          if (adaptivePausedLine(progress, l10n) case final paused?) ...[
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
              context.l10n.adaptiveOn,
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
    required this.sentence,
    required this.kcal,
    required this.note,
  });

  final IconData icon;
  final Color color;

  /// The sentence's text with the calories put in.
  final String Function(String kcal) sentence;
  final int kcal;
  final String note;

  /// Stands in for the calories, to find where they go in the sentence.
  static const _slot = '\u0000';

  @override
  Widget build(BuildContext context) {
    final [before, after] = sentence(_slot).split(_slot);
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
                      text: context.l10n.commonKcal(kcal),
                      style: AppTheme.display.copyWith(
                        fontSize: 18,
                        color: tintedTextColor(color),
                      ),
                    ),
                    TextSpan(text: after),
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
