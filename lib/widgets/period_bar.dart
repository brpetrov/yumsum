import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/widgets/app_card.dart';

/// A week from its Monday: "26 Oct – 1 Nov 2026", or "2 – 8 Nov 2026"
/// within one month; without the [year], "26 Oct – 1 Nov".
String weekLabel(DateTime monday, {bool year = true}) {
  final end = DateTime(monday.year, monday.month, monday.day + 6);
  final start = monday.month == end.month
      ? DateFormat('d').format(monday)
      : DateFormat('d MMM').format(monday);
  return '$start – ${DateFormat(year ? 'd MMM yyyy' : 'd MMM').format(end)}';
}

/// Previous and Next round a period's name, with a button back to the
/// current one ([todayLabel]) while [onToday] is given. History pages
/// through weeks and months with it, AI Coach through weeks.
class PeriodBar extends StatelessWidget {
  const PeriodBar({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    this.todayLabel = 'Today',
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final String todayLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.display.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onToday != null)
            TextButton(onPressed: onToday, child: Text(todayLabel)),
          IconButton(
            tooltip: 'Next',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
