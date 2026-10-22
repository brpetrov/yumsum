import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/creatine_offer.dart';
import 'package:lean_streak/screens/dashboard/helpers/day_off_dialog.dart';
import 'package:lean_streak/screens/dashboard/helpers/quick_log_bar.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/calorie_bars.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/meal_row.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  late DateTime _activeDate;
  Timer? _midnightRefreshTimer;

  @override
  void initState() {
    super.initState();
    _activeDate = _normalizeDate(DateTime.now());
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
    // fireImmediately catches an action set before Today mounted (cold start,
    // or while the user was still signing in).
    ref.listenManual(
      launchActionProvider,
      (_, action) => _onLaunchAction(action),
      fireImmediately: true,
    );
    ref.listenManual(userProfileProvider, (_, next) {
      final profile = next.valueOrNull;
      if (profile != null) _maybeOfferCreatine(profile.createdAt);
    }, fireImmediately: true);
  }

  /// Once, in the first week: offer the daily creatine reminder.
  void _maybeOfferCreatine(DateTime signedUp) {
    final reminders = ref.read(reminderSettingsProvider.notifier);
    if (!reminders.shouldOfferCreatine(
      signedUp: signedUp,
      now: DateTime.now(),
    )) {
      return;
    }
    reminders.markCreatineOffered();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) offerCreatineReminder(context, ref);
    });
  }

  void _onLaunchAction(LaunchAction? action) {
    if (action != LaunchAction.logWeight) return;
    // Deferred: on a cold start this runs inside initState, before there is
    // a frame to show a dialog on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(launchActionProvider.notifier).clear();
      _showLogWeightWithFeedback(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshActiveDateIfNeeded();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightRefreshTimer = Timer(delay, _refreshActiveDateIfNeeded);
  }

  void _refreshActiveDateIfNeeded() {
    final nextDate = _normalizeDate(DateTime.now());
    if (!_isSameDate(_activeDate, nextDate)) {
      ref.invalidate(reviewPeriodsProvider);
      setState(() {
        _activeDate = nextDate;
      });
    }
    _scheduleMidnightRefresh();
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final today = _activeDate;
    final dateKey = DateFormat('yyyy-MM-dd').format(today);

    return AppFrame(
      title: 'Today',
      subtitle: DateFormat('EEEE, d MMMM').format(today),
      actions: [_DayOffButton(date: dateKey)],
      bottom: const QuickLogBar(),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Could not load your profile right now.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final mealsAsync = ref.watch(mealsForDateProvider(dateKey));
          final savedSummary = ref
              .watch(dailySummaryForDateProvider(dateKey))
              .valueOrNull;
          final dayOff =
              ref.watch(dayOffProvider(dateKey)).valueOrNull ?? false;

          return mealsAsync.when(
            data: (meals) {
              final summary =
                  savedSummary ??
                  ref
                      .read(dailySummaryServiceProvider)
                      .buildSummary(
                        date: dateKey,
                        meals: meals,
                        dailyCalorieTarget: profile.dailyCalorieTarget,
                        dayOff: dayOff,
                      );

              return _DashboardContent(
                date: today,
                profile: profile,
                meals: meals,
                summary: summary,
                onOpenReview: () => context.push(AppRoutes.review),
                onEditMeal: (meal) =>
                    showLogMealSheet(context, existingMeal: meal),
                onDeleteMeal: (meal) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Delete meal?'),
                        content: Text('Remove this meal from today?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true || !context.mounted) return;

                  try {
                    await ref
                        .read(logMealControllerProvider.notifier)
                        .delete(meal);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not delete meal right now.'),
                      ),
                    );
                  }
                },
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, _) => Center(
              child: Text(
                'Could not load meals right now.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text(
            'Could not load your profile right now.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.date,
    required this.profile,
    required this.meals,
    required this.summary,
    required this.onOpenReview,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  final DateTime date;
  final UserProfile profile;
  final List<Meal> meals;
  final DailySummary summary;
  final VoidCallback onOpenReview;
  final ValueChanged<Meal> onEditMeal;
  final Future<void> Function(Meal meal) onDeleteMeal;

  @override
  Widget build(BuildContext context) {
    final proteinLogged = meals
        .fold<double>(0, (sum, meal) => sum + (meal.proteinGrams ?? 0))
        .round();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ResponsivePage(
          maxWidth: 720,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TodayCard(
                summary: summary,
                proteinLogged: proteinLogged,
                proteinTarget: HealthCalculator.proteinTargetGrams(
                  targetWeightKg: profile.targetWeightKg,
                  trainingFrequency: profile.trainingFrequency,
                ),
                mealsWithoutProtein: meals
                    .where((meal) => meal.proteinGrams == null)
                    .length,
              ),
              const SizedBox(height: 12),
              _MealsCard(
                meals: meals,
                onEditMeal: onEditMeal,
                onDeleteMeal: onDeleteMeal,
              ),
              const SizedBox(height: 12),
              _MonthPreviewCard(date: date, onOpenReview: onOpenReview),
              const SizedBox(height: 12),
              const _WeightCard(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Top right on Today: take the day off, or go back on plan.
class _DayOffButton extends ConsumerWidget {
  const _DayOffButton({required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOff = ref.watch(dayOffProvider(date)).valueOrNull ?? false;
    return IconButton(
      tooltip: isOff ? 'Day off' : 'Take the day off',
      color: isOff ? AppColors.primary : null,
      icon: Icon(
        isOff ? Icons.beach_access_rounded : Icons.beach_access_outlined,
      ),
      onPressed: () async {
        final uid = ref.read(currentUidProvider);
        if (uid == null || !await confirmDayOff(context, isOff: isOff)) {
          return;
        }
        try {
          await ref
              .read(dailySummaryServiceProvider)
              .setDayOff(uid, date, !isOff);
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not change that right now.')),
          );
        }
      },
    );
  }
}

/// Calories left for the day, then daily protein, in one card.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.summary,
    required this.proteinLogged,
    required this.proteinTarget,
    required this.mealsWithoutProtein,
  });

  final DailySummary summary;
  final int proteinLogged;
  final int proteinTarget;
  final int mealsWithoutProtein;

  @override
  Widget build(BuildContext context) {
    final remaining = summary.targetCalories - summary.totalCalories;
    final calorieProgress = summary.targetCalories <= 0
        ? 0.0
        : summary.totalCalories / summary.targetCalories;
    // The day isn't over, so being under target isn't flagged; only "on
    // track" and "over" are worth saying while it is still today.
    final (String? pillLabel, Color barColor) = switch (summary) {
      _ when summary.dayOff => ('Day off', AppColors.primary),
      _ when summary.mealCount == 0 => (null, AppColors.primary),
      _ when summary.status == DailyStatus.green => (
        'On track',
        AppColors.veryGood,
      ),
      _ when summary.calorieDelta > 0 => (
        'Over target',
        dayStatusColor(summary.status),
      ),
      _ => (null, AppColors.primary),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remaining >= 0
                          ? '$remaining kcal left'
                          : '${remaining.abs()} kcal over',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.totalCalories} of ${summary.targetCalories} kcal eaten',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (pillLabel != null)
                StatusPill(label: pillLabel, color: barColor),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressBar(value: calorieProgress, color: barColor),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Daily protein',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$proteinLogged / $proteinTarget g',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            value: proteinTarget <= 0 ? 0 : proteinLogged / proteinTarget,
            color: AppColors.primary,
          ),
          if (mealsWithoutProtein > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$mealsWithoutProtein ${mealsWithoutProtein == 1 ? 'meal' : 'meals'} '
              'not counted (no protein info)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        color: color,
        backgroundColor: AppColors.surfaceVariant,
      ),
    );
  }
}

/// Today's meals as plain rows in one card.
class _MealsCard extends StatelessWidget {
  const _MealsCard({
    required this.meals,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  final List<Meal> meals;
  final ValueChanged<Meal> onEditMeal;
  final Future<void> Function(Meal meal) onDeleteMeal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Today\'s meals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (meals.isNotEmpty)
                  Text(
                    '${meals.length} logged',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (meals.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4, bottom: 10, right: 12),
              child: Text(
                'Nothing logged yet. Type or tap the mic below.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          else
            for (var index = 0; index < meals.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              MealRow(
                meal: meals[index],
                onEdit: () => onEditMeal(meals[index]),
                onDelete: () => onDeleteMeal(meals[index]),
              ),
            ],
        ],
      ),
    );
  }
}

class _MonthPreviewCard extends ConsumerWidget {
  const _MonthPreviewCard({required this.date, required this.onOpenReview});

  final DateTime date;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final today = DateTime(date.year, date.month, date.day);
    final range = ReviewRange(startDate: startOfMonth, endDate: today);
    final summariesAsync = ref.watch(reviewSummariesProvider(range));

    return AppCard(
      onTap: onOpenReview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM').format(date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          summariesAsync.when(
            data: (summariesByDate) {
              final days = List.generate(
                today.day,
                (index) => DateTime(date.year, date.month, index + 1),
              );
              final summaries = days
                  .map(
                    (day) =>
                        summariesByDate[DateFormat('yyyy-MM-dd').format(day)],
                  )
                  .whereType<DailySummary>()
                  .toList();
              int count(DailyStatus status) => summaries
                  .where(
                    (summary) =>
                        summary.status == status && hasSettledStatus(summary),
                  )
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80,
                    child: CalorieBars(
                      days: days,
                      summariesByDate: summariesByDate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          summaries.isEmpty
                              ? 'No logged days yet this month.'
                              : '${summaries.length} days logged',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: '${count(DailyStatus.green)}',
                        color: AppColors.veryGood,
                      ),
                      const SizedBox(width: 6),
                      StatusPill(
                        label: '${count(DailyStatus.yellow)}',
                        color: AppColors.bad,
                      ),
                      const SizedBox(width: 6),
                      StatusPill(
                        label: '${count(DailyStatus.red)}',
                        color: AppColors.veryBad,
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => SizedBox(
              height: 112,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, _) => SizedBox(
              height: 112,
              child: Center(
                child: Text(
                  'Could not load this month.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showLogWeightWithFeedback(BuildContext context) async {
  final result = await showLogWeightDialog(context);
  if (!context.mounted || result == null) return;
  final message = result.targetChanged
      ? 'Weight saved. New target: ${result.newCalorieTarget} kcal.'
      : 'Weight saved.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weightEntriesProvider).valueOrNull ?? const [];
    final latest = entries.lastOrNull;
    final daysAgo = latest == null
        ? 0
        : DateTime.now().difference(latest.date).inDays;

    return AppCard(
      onTap: () => context.push(AppRoutes.progress),
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  latest == null
                      ? 'Log your weight to track progress'
                      : daysAgo > 7
                      ? 'Latest: ${latest.weightKg.toStringAsFixed(1)} kg'
                            ' · $daysAgo days ago'
                      : 'Latest: ${latest.weightKg.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showLogWeightWithFeedback(context),
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}
