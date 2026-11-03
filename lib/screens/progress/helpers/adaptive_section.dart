import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// The Adaptive formula under the weight chart, always on with YumSum Star:
/// what it does for you, then what you burn as it has learnt it and the
/// target that follows, how well it knows you and this week's result.
/// Without YumSum Star, the formula's guess beside a locked real burn, and
/// a tap opens the YumSum Star page. Its info button explains it
/// ([showAdaptiveIntro]).
class AdaptiveSection extends ConsumerWidget {
  const AdaptiveSection({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(plusProvider);
    final progress = plus
        ? ref.watch(adaptiveProgressProvider).valueOrNull
        : null;
    final week = plus ? ref.watch(adaptiveTodayLineProvider) : null;
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
                    onPressed: () => showAdaptiveIntro(context),
                    icon: const Icon(Icons.info_outline_rounded),
                    iconSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (plus) StatusPill(label: 'On', color: AppColors.veryGood),
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
        if (plus) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'You burn',
                  value: '${adaptiveBurn(profile, progress)} kcal',
                  color: AppColors.veryGood,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Your target',
                  value: '${profile.dailyCalorieTarget.round()} kcal',
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            Text(adaptiveStageLine(progress), style: muted),
          ],
          if (week != null) ...[
            const SizedBox(height: 4),
            Text(week, style: muted),
          ],
        ] else ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Formula\'s guess',
                  value: '${adaptiveBurn(profile, null)} kcal',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Your real burn',
                  icon: Icons.lock_rounded,
                  color: AppColors.veryGood,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

    if (plus) return section;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPlusPaywall(context),
      child: section,
    );
  }
}

/// A small label over a big number (or a locked one, as [icon]), like the
/// stats at the top of the page.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, this.value, this.icon, this.color});

  final String label;
  final String? value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        if (value case final value?)
          Text(
            value,
            style: AppTheme.display.copyWith(fontSize: 21, color: color),
          )
        else
          Icon(icon, size: 26, color: color),
      ],
    );
  }
}
