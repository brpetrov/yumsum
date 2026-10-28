import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/widgets/day_status.dart';

/// One bar per day: height is calories against target, colour is the day's
/// status, and days without a log show as a small stub.
class CalorieBars extends StatelessWidget {
  const CalorieBars({
    super.key,
    required this.days,
    required this.summariesByDate,
    this.minimumSlots = 12,
  });

  static const _maxBarWidth = 12.0;
  static const _slotGutter = 3.0;

  final List<DateTime> days;
  final Map<String, DailySummary> summariesByDate;

  /// Keeps bars from getting very wide when only a few days are shown.
  final int minimumSlots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotCount = math.max(days.length, minimumSlots);
        final slotWidth = constraints.maxWidth / slotCount;
        final barWidth = math.min(
          _maxBarWidth,
          math.max(2.0, slotWidth - _slotGutter),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(slotCount, (index) {
            final day = index < days.length ? days[index] : null;

            return Expanded(
              child: Center(
                child: day == null
                    ? const SizedBox.shrink()
                    : SizedBox(
                        width: barWidth,
                        height: double.infinity,
                        child: _CalorieBar(
                          day: day,
                          summary:
                              summariesByDate[DateFormat(
                                'yyyy-MM-dd',
                              ).format(day)],
                        ),
                      ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CalorieBar extends StatelessWidget {
  const _CalorieBar({required this.day, required this.summary});

  final DateTime day;
  final DailySummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    final color = summary == null
        ? AppColors.divider
        : hasSettledStatus(summary)
        ? dayStatusColor(summary.status)
        : AppColors.veryGood;
    final heightFactor = summary == null
        ? 0.08
        : ((summary.totalCalories / summary.targetCalories.clamp(1, 100000))
                      .clamp(0.15, 1.25) /
                  1.25)
              .toDouble();
    final dayLabel = DateFormat('d MMM').format(day);

    return Tooltip(
      message: summary == null
          ? '$dayLabel: no calories logged'
          : '$dayLabel: ${summary.totalCalories} kcal'
                '${summary.proteinGrams == null ? '' : ' · ${summary.proteinGrams} g protein'}',
      waitDuration: const Duration(milliseconds: 250),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
