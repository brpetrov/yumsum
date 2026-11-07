import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/widgets/app_card.dart';

/// A week from its Monday: "26 Oct – 1 Nov 2026", or "2 – 8 Nov 2026"
/// within one month; without the [year], "26 Oct – 1 Nov". In [l10n]'s
/// language.
String weekLabel(AppLocalizations l10n, DateTime monday, {bool year = true}) {
  final end = DateTime(monday.year, monday.month, monday.day + 6);
  final start = monday.month == end.month
      ? l10n.date(monday, 'd')
      : l10n.shortDayMonth(monday);
  return '$start – ${year ? l10n.shortDayMonthYear(end) : l10n.shortDayMonth(end)}';
}

/// Previous and Next round a period's name, with a button back to the
/// current one ([todayLabel], or Today) while [onToday] is given. History pages
/// through weeks and months with it, AI Coach through weeks.
class PeriodBar extends StatelessWidget {
  const PeriodBar({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    this.todayLabel,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final String? todayLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.historyPrevious,
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
            TextButton(
              onPressed: onToday,
              child: Text(todayLabel ?? l10n.historyToday),
            ),
          IconButton(
            tooltip: l10n.historyNext,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
