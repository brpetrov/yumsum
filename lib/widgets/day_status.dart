import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/daily_summary.dart';

Color dayStatusColor(DailyStatus status) {
  return switch (status) {
    DailyStatus.green => AppColors.veryGood,
    DailyStatus.yellow => AppColors.bad,
    DailyStatus.red => AppColors.veryBad,
  };
}

/// Today isn't over, so being under target isn't a verdict yet: a day only
/// shows its status once it is finished, on track, or over target. A day
/// off never shows one.
bool hasSettledStatus(DailySummary summary) {
  if (summary.dayOff) return false;
  final now = DateTime.now();
  final isToday = summary.date == DateFormat('yyyy-MM-dd').format(now);
  return !isToday ||
      summary.status == DailyStatus.green ||
      summary.calorieDelta > 0;
}

/// A small tinted label, e.g. "On track" or a day count.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
