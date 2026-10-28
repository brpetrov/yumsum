import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';

class HealthPlanPreviewCard extends StatelessWidget {
  const HealthPlanPreviewCard({
    super.key,
    required this.preview,
    required this.title,
  });

  final HealthPlanCalculation preview;
  final String title;

  Color get _color => switch (preview.goalPaceLevel) {
    GoalPaceLevel.safe => AppColors.veryGood,
    GoalPaceLevel.caution => AppColors.bad,
    GoalPaceLevel.warning => AppColors.veryBad,
  };

  String get _paceLabel {
    if (preview.isMaintaining) return 'Maintenance plan';
    if (preview.calorieTargetClamped) return 'Minimum calorie floor';
    return switch (preview.goalPaceLevel) {
      GoalPaceLevel.safe => 'Sustainable pace',
      GoalPaceLevel.caution => 'Faster pace',
      GoalPaceLevel.warning => 'Very aggressive',
    };
  }

  String get _paceMessage {
    if (preview.isMaintaining) {
      return 'No calorie deficit is applied.';
    }
    if (preview.calorieTargetClamped) {
      return 'This pace would go below the minimum, so the goal date moves later.';
    }
    return switch (preview.goalPaceLevel) {
      GoalPaceLevel.safe => 'A moderate deficit from estimated maintenance.',
      GoalPaceLevel.caution =>
        'This needs consistency and may feel restrictive.',
      GoalPaceLevel.warning =>
        'Consider a slower pace if this feels hard to maintain.',
    };
  }

  String get _goalDateLabel {
    if (preview.isMaintaining) return 'Maintain';
    return DateFormat('d MMM yyyy').format(preview.targetDate);
  }

  String get _weeklyLossLabel {
    if (preview.isMaintaining) return 'Maintain';
    return '${preview.goalPaceKgPerWeek.toStringAsFixed(2)} kg/wk';
  }

  @override
  Widget build(BuildContext context) {
    // Maintenance, deficit and the multipliers live in the info dialog.
    final metrics = [
      _PlanMetric(
        label: 'Daily target',
        value: '${preview.dailyCalorieTarget.round()} kcal',
      ),
      _PlanMetric(label: 'Weekly loss', value: _weeklyLossLabel),
      _PlanMetric(label: 'Goal by', value: _goalDateLabel),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: _color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.display.copyWith(fontSize: 16, color: _color),
                ),
              ),
              IconButton(
                tooltip: 'How this is calculated',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                icon: Icon(Icons.info_outline_rounded, color: _color, size: 20),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) =>
                      _CalculationInfoDialog(preview: preview, color: _color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MetricGrid(metrics: metrics),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                preview.goalPaceLevel == GoalPaceLevel.safe
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                color: _color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paceLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _paceMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalculationInfoDialog extends StatelessWidget {
  const _CalculationInfoDialog({required this.preview, required this.color});

  final HealthPlanCalculation preview;
  final Color color;

  double get _dailyDeficit {
    return (preview.tdee - preview.dailyCalorieTarget)
        .clamp(0, double.infinity)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final targetFormula = preview.isMaintaining
        ? '${preview.tdee.round()} = ${preview.dailyCalorieTarget.round()} kcal/day'
        : '${preview.tdee.round()} - ${_dailyDeficit.round()} = ${preview.dailyCalorieTarget.round()} kcal/day';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'How calories are estimated',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'First we estimate your resting burn from weight, height, age, and sex. Then we add your daily movement and training to estimate maintenance.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            _InfoLine(
              label: 'Resting burn',
              value: '${preview.bmr.round()} kcal/day',
            ),
            _InfoLine(
              label: 'Daily movement',
              value: 'x${preview.lifestyleMultiplier.toStringAsFixed(2)}',
            ),
            _InfoLine(
              label: 'Training bonus',
              value: '+${preview.trainingMultiplierBonus.toStringAsFixed(2)}',
            ),
            _InfoLine(
              label: 'Combined activity',
              value: 'x${preview.activityMultiplier.toStringAsFixed(2)}',
            ),
            _InfoLine(
              label: 'Maintenance',
              value:
                  '${preview.bmr.round()} x ${preview.activityMultiplier.toStringAsFixed(2)} = ${preview.tdee.round()} kcal/day',
            ),
            _InfoLine(label: 'Target', value: targetFormula),
            if (preview.calorieTargetClamped) ...[
              const SizedBox(height: 10),
              Text(
                'This pace would go below the minimum, so your target stays at the minimum and the goal date moves later.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_PlanMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 300 ? 2 : 3;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _Metric(label: metric.label, value: metric.value),
              ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.display.copyWith(
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PlanMetric {
  const _PlanMetric({required this.label, required this.value});

  final String label;
  final String value;
}
