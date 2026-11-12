import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';

class HealthPlanPreviewCard extends StatelessWidget {
  const HealthPlanPreviewCard({
    super.key,
    required this.preview,
    required this.title,
    required this.weightUnit,
  });

  final HealthPlanCalculation preview;
  final String title;
  final WeightUnit weightUnit;

  Color get _color => switch (preview.goalPaceLevel) {
    GoalPaceLevel.safe => AppColors.veryGood,
    GoalPaceLevel.caution => AppColors.bad,
    GoalPaceLevel.warning => AppColors.veryBad,
  };

  String _paceLabel(AppLocalizations l10n) {
    if (preview.isMaintaining) return l10n.planPreviewMaintenance;
    if (preview.calorieTargetClamped) return l10n.planPreviewFloor;
    return switch (preview.goalPaceLevel) {
      GoalPaceLevel.safe => l10n.planPreviewSafe,
      GoalPaceLevel.caution => l10n.planPreviewCaution,
      GoalPaceLevel.warning => l10n.planPreviewWarning,
    };
  }

  String _paceMessage(AppLocalizations l10n) {
    if (preview.isMaintaining) return l10n.planPreviewMaintenanceNote;
    if (preview.calorieTargetClamped) return l10n.planPreviewFloorNote;
    if (preview.isGaining) return l10n.planPreviewGainNote;
    return switch (preview.goalPaceLevel) {
      GoalPaceLevel.safe => l10n.planPreviewSafeNote,
      GoalPaceLevel.caution => l10n.planPreviewCautionNote,
      GoalPaceLevel.warning => l10n.planPreviewWarningNote,
    };
  }

  String _goalDateLabel(AppLocalizations l10n) {
    if (preview.isMaintaining) return l10n.planPreviewMaintain;
    return l10n.shortDayMonthYear(preview.targetDate);
  }

  String _weeklyLossLabel(AppLocalizations l10n) {
    if (preview.isMaintaining) return l10n.planPreviewMaintain;
    return l10n.planPreviewPerWeek(
      formatPace(preview.goalPaceKgPerWeek, weightUnit, l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Maintenance, deficit and the multipliers live in the info dialog.
    final metrics = [
      _PlanMetric(
        label: l10n.planPreviewDailyTarget,
        value: l10n.commonKcal(preview.dailyCalorieTarget.round()),
      ),
      _PlanMetric(
        label: preview.isGaining
            ? l10n.planPreviewWeeklyGain
            : l10n.planPreviewWeeklyLoss,
        value: _weeklyLossLabel(l10n),
      ),
      _PlanMetric(label: l10n.planPreviewGoalBy, value: _goalDateLabel(l10n)),
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
                tooltip: l10n.planPreviewInfoTooltip,
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
                      _paceLabel(l10n),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _paceMessage(l10n),
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
    return (preview.tdee + preview.adaptiveKcal - preview.dailyCalorieTarget)
        .clamp(0, double.infinity)
        .toDouble();
  }

  double get _dailySurplus =>
      preview.dailyCalorieTarget - preview.tdee - preview.adaptiveKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final adaptive = preview.adaptiveKcal.round();
    final sign = adaptive < 0 ? '-' : '+';
    // The Adaptive formula corrects the burn, before the deficit.
    final burn = adaptive == 0
        ? '${preview.tdee.round()}'
        : '${preview.tdee.round()} $sign ${adaptive.abs()}';
    final target = preview.dailyCalorieTarget.round();
    final perDay = l10n.planInfoKcalPerDay(target);
    final targetFormula = preview.isMaintaining
        ? preview.calorieTargetClamped
              ? l10n.planInfoAtMinimum(target)
              : '$burn = $perDay'
        : preview.isGaining
        ? '$burn + ${_dailySurplus.round()} = $perDay'
        : '$burn - ${_dailyDeficit.round()} = $perDay';
    String times(double multiplier) => l10n.decimal(multiplier, 2);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.planInfoTitle,
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
              l10n.planInfoBody,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            _InfoLine(
              label: l10n.planInfoResting,
              value: l10n.planInfoKcalPerDay(preview.bmr.round()),
            ),
            _InfoLine(
              label: l10n.planInfoMovement,
              value: 'x${times(preview.lifestyleMultiplier)}',
            ),
            _InfoLine(
              label: l10n.planInfoTraining,
              value: '+${times(preview.trainingMultiplierBonus)}',
            ),
            _InfoLine(
              label: l10n.planInfoActivity,
              value: 'x${times(preview.activityMultiplier)}',
            ),
            _InfoLine(
              label: l10n.planInfoMaintenance,
              value:
                  '${preview.bmr.round()} x ${times(preview.activityMultiplier)} = ${l10n.planInfoKcalPerDay(preview.tdee.round())}',
            ),
            if (adaptive != 0)
              _InfoLine(
                label: l10n.planInfoAdaptive,
                value: '$sign${l10n.planInfoKcalPerDay(adaptive.abs())}',
              ),
            _InfoLine(label: l10n.planInfoTarget, value: targetFormula),
            if (preview.calorieTargetClamped && !preview.isMaintaining) ...[
              const SizedBox(height: 10),
              Text(
                l10n.planInfoFloorNote,
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
          child: Text(l10n.commonGotIt),
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
