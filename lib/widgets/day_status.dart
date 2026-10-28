import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
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

/// Text on a tint of [color]: in light mode a deeper shade of it, so even
/// the amber reads clearly; dark mode's lifted accents read as they are.
Color tintedTextColor(Color color) =>
    AppColors.isDark ? color : Color.lerp(color, AppColors.textPrimary, 0.42)!;

/// A small candy-like bubble, e.g. "On track" or a day count.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? 0.2 : 0.17),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTheme.display.copyWith(
          color: tintedTextColor(color),
          fontSize: 14,
          height: 1.2,
        ),
      ),
    );
  }
}
