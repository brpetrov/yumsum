import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/period_review.dart';
import 'package:lean_streak/providers/period_review_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/screens/review/day_meals_sheet.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/bowl_note.dart';
import 'package:lean_streak/widgets/calorie_bars.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// Calendar on top, the period's review underneath. Week and month share one
/// switch; any day up to today opens its meals.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

enum _ReviewMode { week, month }

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _ReviewMode _mode = _ReviewMode.month;
  DateTime _anchor = _dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(reviewPeriodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('History')),
      body: periodsAsync.when(
        data: _buildContent,
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text(
            'Could not load your history.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ReviewPeriods periods) {
    final today = _dateOnly(DateTime.now());
    final start = _periodStart(_anchor, _mode);
    final end = _periodEnd(_anchor, _mode);
    final currentStart = _periodStart(today, _mode);
    final logged = _mode == _ReviewMode.month
        ? periods.monthStarts
        : periods.weekStarts;
    final firstStart = logged.fold<DateTime>(
      currentStart,
      (earliest, period) => period.isBefore(earliest) ? period : earliest,
    );
    // Only finished days are reviewed; today is still going.
    final yesterday = today.subtract(const Duration(days: 1));
    final reviewEnd = end.isAfter(yesterday) ? yesterday : end;
    final summariesByDate =
        ref
            .watch(
              reviewSummariesProvider(
                ReviewRange(startDate: start, endDate: end),
              ),
            )
            .valueOrNull ??
        const <String, DailySummary>{};

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ResponsivePage(
          maxWidth: 720,
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            28 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillToggle<_ReviewMode>(
                options: const [
                  (_ReviewMode.week, 'Week'),
                  (_ReviewMode.month, 'Month'),
                ],
                selected: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              const SizedBox(height: 18),
              _PeriodBar(
                label: _periodLabel(start, _mode),
                onPrevious: start.isAfter(firstStart)
                    ? () => setState(() => _anchor = _shift(start, -1, _mode))
                    : null,
                onNext: start.isBefore(currentStart)
                    ? () => setState(() => _anchor = _shift(start, 1, _mode))
                    : null,
                onToday: start == currentStart
                    ? null
                    : () => setState(() => _anchor = today),
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
                child: _Calendar(
                  start: start,
                  end: end,
                  isMonth: _mode == _ReviewMode.month,
                  summariesByDate: summariesByDate,
                  onOpenDay: (day) => showDayMealsSheet(context, day),
                ),
              ),
              const SizedBox(height: 18),
              if (reviewEnd.isBefore(start))
                const AppCard(
                  child: BowlNote(
                    'Your review starts tomorrow, once today is over.',
                  ),
                )
              else
                _PeriodReviewCard(
                  range: PeriodReviewRange(
                    startDate: start,
                    endDate: reviewEnd,
                  ),
                  days: [
                    for (
                      var day = start;
                      !day.isAfter(reviewEnd);
                      day = DateTime(day.year, day.month, day.day + 1)
                    )
                      day,
                  ],
                  summariesByDate: summariesByDate,
                  isMonth: _mode == _ReviewMode.month,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

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
            TextButton(onPressed: onToday, child: const Text('Today')),
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

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.start,
    required this.end,
    required this.isMonth,
    required this.summariesByDate,
    required this.onOpenDay,
  });

  final DateTime start;
  final DateTime end;
  final bool isMonth;
  final Map<String, DailySummary> summariesByDate;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (
        var day = start;
        !day.isAfter(end);
        day = DateTime(day.year, day.month, day.day + 1)
      )
        day,
    ];
    final leading = isMonth ? start.weekday - 1 : 0;
    final trailing = (7 - (leading + days.length) % 7) % 7;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leading, null),
      ...days,
      ...List<DateTime?>.filled(trailing, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in [
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun',
            ])
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          // Square cells on phones; flatter ones on wide screens so the
          // review below stays in view.
          builder: (context, constraints) => GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 6,
            childAspectRatio: switch ((isMonth, constraints.maxWidth > 520)) {
              (true, true) => 1.6,
              (true, false) => 1,
              (false, true) => 1.2,
              (false, false) => 0.85,
            },
            children: [
              for (final day in cells)
                day == null
                    ? const SizedBox.shrink()
                    : _DayCell(
                        day: day,
                        summary: summariesByDate[_dateKey(day)],
                        onTap: () => onOpenDay(day),
                      ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: [
            _LegendDot(label: 'On track', color: AppColors.veryGood),
            _LegendDot(label: 'Close', color: AppColors.bad),
            _LegendDot(label: 'Off track', color: AppColors.veryBad),
            _LegendDot(label: 'Not logged', color: AppColors.divider),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.summary,
    required this.onTap,
  });

  final DateTime day;
  final DailySummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final summary = this.summary;
    final color = summary == null || !hasSettledStatus(summary)
        ? null
        : dayStatusColor(summary.status);

    // Round bubbles: tinted by the day's status, plain cream when nothing
    // settled, and no bubble at all for days still to come.
    return Material(
      color: isFuture
          ? Colors.transparent
          : color?.withValues(alpha: AppColors.isDark ? 0.24 : 0.2) ??
                AppColors.surfaceVariant,
      shape: StadiumBorder(
        side: isToday
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isFuture ? null : onTap,
        child: Center(
          child: Text(
            '${day.day}',
            style: AppTheme.display.copyWith(
              fontSize: 16,
              color: isFuture
                  ? AppColors.textDisabled
                  : color == null
                  ? AppColors.textSecondary
                  : tintedTextColor(color),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// The period at a glance: share of days on track, how many days were
/// logged, the calorie graph and a few plain-language notes.
class _PeriodReviewCard extends ConsumerWidget {
  const _PeriodReviewCard({
    required this.range,
    required this.days,
    required this.summariesByDate,
    required this.isMonth,
  });

  final PeriodReviewRange range;
  final List<DateTime> days;
  final Map<String, DailySummary> summariesByDate;
  final bool isMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(periodReviewProvider(range)).valueOrNull;
    if (review == null) {
      return AppCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (review.loggedDays == 0)
                const BowlNote('Nothing logged in this period yet.')
              else
                _ReviewHeadline(review: review),
              const SizedBox(height: 20),
              SizedBox(
                height: 88,
                child: CalorieBars(
                  days: days,
                  summariesByDate: summariesByDate,
                  minimumSlots: isMonth ? 12 : 7,
                ),
              ),
              if (review.loggedDays > 0) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: '${review.greenDays} on track',
                      color: AppColors.veryGood,
                    ),
                    StatusPill(
                      label: '${review.yellowDays} close',
                      color: AppColors.bad,
                    ),
                    StatusPill(
                      label: '${review.redDays} off track',
                      color: AppColors.veryBad,
                    ),
                    if (review.daysOff > 0)
                      StatusPill(
                        label:
                            '${review.daysOff} '
                            '${review.daysOff == 1 ? 'day' : 'days'} off',
                        color: AppColors.primary,
                      ),
                  ],
                ),
                for (final note in review.guidance) ...[
                  const SizedBox(height: 14),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewHeadline extends StatelessWidget {
  const _ReviewHeadline({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    final onTrack = (review.calorieConsistencyRate * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$onTrack%',
                style: AppTheme.display.copyWith(
                  fontSize: 44,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of logged days on track',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${review.loggedDays} of ${review.daysInPeriod} days logged',
              style: AppTheme.display.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Average ${review.averageCaloriesPerDay.round()} kcal a day',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime _periodStart(DateTime date, _ReviewMode mode) {
  final day = _dateOnly(date);
  return mode == _ReviewMode.month
      ? DateTime(day.year, day.month, 1)
      : day.subtract(Duration(days: day.weekday - 1));
}

DateTime _periodEnd(DateTime date, _ReviewMode mode) {
  final start = _periodStart(date, mode);
  return mode == _ReviewMode.month
      ? DateTime(start.year, start.month + 1, 0)
      : DateTime(start.year, start.month, start.day + 6);
}

DateTime _shift(DateTime start, int by, _ReviewMode mode) {
  return mode == _ReviewMode.month
      ? DateTime(start.year, start.month + by, 1)
      : DateTime(start.year, start.month, start.day + 7 * by);
}

String _periodLabel(DateTime start, _ReviewMode mode) {
  if (mode == _ReviewMode.month) {
    return DateFormat('MMMM yyyy').format(start);
  }
  final end = _periodEnd(start, mode);
  final startLabel = start.month == end.month
      ? DateFormat('d').format(start)
      : DateFormat('d MMM').format(start);
  return '$startLabel – ${DateFormat('d MMM yyyy').format(end)}';
}
