import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/widgets/clickable.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';

// The form pieces onboarding and Plan Settings share: section labels, the
// gender buttons and the cards for pace, daily movement and training.

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 14),
      child: Text(
        text,
        style: AppTheme.display.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class GenderButton extends StatelessWidget {
  const GenderButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Clickable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.display.copyWith(
              fontSize: 15.5,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  static String _title(ActivityLevel level) => switch (level) {
    ActivityLevel.sedentary => 'Mostly sitting',
    ActivityLevel.lightlyActive => 'Light daily movement',
    ActivityLevel.moderatelyActive => 'On feet often',
    ActivityLevel.veryActive => 'Physical job or high movement',
  };

  static String _description(ActivityLevel level) => switch (level) {
    ActivityLevel.sedentary => 'Desk day, low steps, little standing.',
    ActivityLevel.lightlyActive => 'Some walking, errands, or light chores.',
    ActivityLevel.moderatelyActive =>
      'Standing or walking for much of the day.',
    ActivityLevel.veryActive => 'Manual work, high steps, or very active days.',
  };

  static IconData _icon(ActivityLevel level) => switch (level) {
    ActivityLevel.sedentary => Icons.weekend_outlined,
    ActivityLevel.lightlyActive => Icons.directions_walk_outlined,
    ActivityLevel.moderatelyActive => Icons.directions_run_outlined,
    ActivityLevel.veryActive => Icons.fitness_center_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: _title(level),
      description: _description(level),
      icon: _icon(level),
      selected: selected,
      onTap: onTap,
    );
  }
}

class TrainingCard extends StatelessWidget {
  const TrainingCard({
    super.key,
    required this.frequency,
    required this.selected,
    required this.onTap,
  });

  final TrainingFrequency frequency;
  final bool selected;
  final VoidCallback onTap;

  static String _title(TrainingFrequency frequency) => switch (frequency) {
    TrainingFrequency.none => 'No regular training',
    TrainingFrequency.oneToTwo => '1 to 2 sessions/week',
    TrainingFrequency.threeToFour => '3 to 4 sessions/week',
    TrainingFrequency.fivePlus => '5+ sessions/week',
  };

  static String _description(TrainingFrequency frequency) =>
      switch (frequency) {
        TrainingFrequency.none => 'No planned workouts most weeks.',
        TrainingFrequency.oneToTwo =>
          'A couple of lifting, cardio, or sport days.',
        TrainingFrequency.threeToFour => 'Regular training most weeks.',
        TrainingFrequency.fivePlus => 'Frequent structured workouts.',
      };

  static IconData _icon(TrainingFrequency frequency) => switch (frequency) {
    TrainingFrequency.none => Icons.block_rounded,
    TrainingFrequency.oneToTwo => Icons.fitness_center_outlined,
    TrainingFrequency.threeToFour => Icons.directions_run_outlined,
    TrainingFrequency.fivePlus => Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: _title(frequency),
      description: _description(frequency),
      icon: _icon(frequency),
      selected: selected,
      onTap: onTap,
    );
  }
}

class PaceCard extends StatelessWidget {
  const PaceCard({
    super.key,
    required this.pace,
    required this.selected,
    required this.onTap,
  });

  final WeightLossPace pace;
  final bool selected;
  final VoidCallback onTap;

  static String _title(WeightLossPace pace) => switch (pace) {
    WeightLossPace.slow => 'Slow - 0.25 kg/week',
    WeightLossPace.moderate => 'Moderate - 0.5 kg/week',
    WeightLossPace.fast => 'Fast - 0.75 kg/week',
    WeightLossPace.maintain => 'Maintain weight',
  };

  static String _description(WeightLossPace pace) => switch (pace) {
    WeightLossPace.slow =>
      'Gentle and easier to maintain over a longer period.',
    WeightLossPace.moderate =>
      'Steady progress with a moderate calorie deficit.',
    WeightLossPace.fast =>
      'Faster results, but more restrictive for most people.',
    WeightLossPace.maintain =>
      'Keeps your calories around maintenance instead of creating a deficit.',
  };

  static IconData _icon(WeightLossPace pace) => switch (pace) {
    WeightLossPace.slow => Icons.hourglass_bottom_rounded,
    WeightLossPace.moderate => Icons.trending_down_rounded,
    WeightLossPace.fast => Icons.bolt_rounded,
    WeightLossPace.maintain => Icons.horizontal_rule_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: _title(pace),
      description: _description(pace),
      icon: _icon(pace),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconBubble(
              icon,
              size: 40,
              background: selected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceVariant,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
