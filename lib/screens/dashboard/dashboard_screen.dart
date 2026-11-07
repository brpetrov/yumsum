import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/units_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/screens/dashboard/helpers/creatine_offer.dart';
import 'package:lean_streak/screens/dashboard/helpers/day_off_dialog.dart';
import 'package:lean_streak/screens/dashboard/helpers/plus_prompt_card.dart';
import 'package:lean_streak/screens/dashboard/helpers/quick_log_bar.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/bowl_note.dart';
import 'package:lean_streak/widgets/calorie_bars.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/macro_guide.dart';
import 'package:lean_streak/widgets/macro_rings.dart';
import 'package:lean_streak/widgets/meal_row.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
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
    ref.listenManual(plusProvider, (_, plus) {
      if (plus) _maybeShowAdaptiveIntro();
    }, fireImmediately: true);
    ref.listenManual(adaptiveLapseProvider, (_, back) {
      if (back != null) _maybeShowAdaptiveLapse(back);
    }, fireImmediately: true);
  }

  /// Once, after subscribing: how the Adaptive formula works.
  void _maybeShowAdaptiveIntro() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(adaptiveIntroShownKey) == true) return;
    prefs.setBool(adaptiveIntroShownKey, true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showAdaptiveIntro(context);
    });
  }

  /// Once per end of YumSum Star: when the target goes back to the plan.
  void _maybeShowAdaptiveLapse(DateTime back) {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = DateFormat('yyyy-MM-dd').format(back);
    if (prefs.getString(adaptiveLapseNoticeKey) == key) return;
    prefs.setString(adaptiveLapseNoticeKey, key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showAdaptiveLapse(context, back);
    });
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
      logWeightWithFeedback(context);
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
      ref.invalidate(firstLoggedDayProvider);
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
    // The first name only, so the Star badge still fits beside it on a phone.
    final firstName = profileAsync.valueOrNull?.name.split(' ').first;

    return AppFrame(
      title: firstName ?? 'Home',
      titleBadge: StarBadge(onTap: () => showPlusPaywall(context)),
      subtitle: DateFormat('EEEE, d MMMM').format(today),
      actions: [_DayOffButton(date: dateKey)],
      bottom: const QuickLogBar(),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Could not load your profile.',
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
                showMacros: ref.watch(showMacrosProvider),
                adaptiveLine: ref.watch(adaptiveTodayLineProvider),
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
                        content: Text('Could not delete the meal. Try again.'),
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
                'Could not load your meals.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text(
            'Could not load your profile.',
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
    required this.showMacros,
    required this.adaptiveLine,
    required this.onOpenReview,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  final DateTime date;
  final UserProfile profile;
  final List<Meal> meals;
  final DailySummary summary;
  final bool showMacros;
  final String? adaptiveLine;
  final VoidCallback onOpenReview;
  final ValueChanged<Meal> onEditMeal;
  final Future<void> Function(Meal meal) onDeleteMeal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      // Scrolling the page lets go of the quick-log bar's box too.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        ResponsivePage(
          maxWidth: 720,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TodayCard(
                summary: summary,
                meals: meals,
                trackProtein: profile.trackProtein,
                proteinTarget: HealthCalculator.proteinTargetGrams(
                  targetWeightKg: profile.targetWeightKg,
                  trainingFrequency: profile.trainingFrequency,
                ),
                showMacros: showMacros,
                adaptiveLine: adaptiveLine,
              ),
              const SizedBox(height: 18),
              _MealsCard(
                meals: meals,
                showProtein: profile.trackProtein,
                showMacros: showMacros,
                onEditMeal: onEditMeal,
                onDeleteMeal: onDeleteMeal,
              ),
              const SizedBox(height: 18),
              _MonthPreviewCard(date: date, onOpenReview: onOpenReview),
              const SizedBox(height: 18),
              const PlusPromptCard(),
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
      icon: IconBubble(
        isOff ? Icons.beach_access_rounded : Icons.beach_access_outlined,
        raised: true,
        color: isOff ? AppColors.primary : null,
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
            const SnackBar(
              content: Text('Could not change your day off. Try again.'),
            ),
          );
        }
      },
    );
  }
}

/// Calories left for the day, then the protein and macro rings, in one
/// card.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.summary,
    required this.meals,
    required this.trackProtein,
    required this.proteinTarget,
    required this.showMacros,
    required this.adaptiveLine,
  });

  final DailySummary summary;
  final List<Meal> meals;
  final bool trackProtein;
  final int proteinTarget;

  /// YumSum Star: every ring. Otherwise protein, and the rest dimmed.
  final bool showMacros;

  /// This week's Adaptive formula result, if there is one to show.
  final String? adaptiveLine;

  @override
  Widget build(BuildContext context) {
    final remaining = summary.targetCalories - summary.totalCalories;
    final calorieProgress = summary.targetCalories <= 0
        ? 0.0
        : summary.totalCalories / summary.targetCalories;
    // The day isn't over, so being under target isn't flagged; only "on
    // track" and "over" are worth saying while it is still today.
    final (String? pillLabel, Color barColor) = switch (summary) {
      _ when summary.dayOff => ('Day off', AppColors.veryGood),
      _ when summary.mealCount == 0 => (null, AppColors.veryGood),
      _ when summary.status == DailyStatus.green => (
        'On track',
        AppColors.veryGood,
      ),
      _ when summary.calorieDelta > 0 => (
        'Over target',
        dayStatusColor(summary.status),
      ),
      _ => (null, AppColors.veryGood),
    };

    // The number big and its unit smaller, like a scoreboard.
    final number = AppTheme.display.copyWith(
      fontSize: 42,
      height: 1.1,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
    );

    // Warm like the icon's tile, fading into the bowl's cream.
    return AppCard(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.heroStart, AppColors.heroEnd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${remaining.abs()}'),
                          TextSpan(
                            text: remaining >= 0 ? ' kcal left' : ' kcal over',
                            style: number.copyWith(
                              fontSize: 22,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      style: number,
                    ),
                  ),
                  if (pillLabel != null)
                    StatusPill(label: pillLabel, color: barColor),
                  // Room for the info button.
                  const SizedBox(width: 26),
                ],
              ),
              // The icon's right edge in line with the end of the calorie
              // bar, level with the status pill; the tap area is the usual
              // 48.
              Positioned(
                top: -10,
                right: -15,
                child: IconButton(
                  tooltip: 'About your targets',
                  onPressed: () => showMacroGuide(
                    context,
                    withProtein: trackProtein,
                    withCalories: true,
                  ),
                  icon: const Icon(Icons.info_outline_rounded),
                  iconSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Below the pill and the button, so it has the card's width.
          Text(
            '${summary.totalCalories} of ${summary.targetCalories} kcal eaten',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _ProgressBar(value: calorieProgress, color: barColor, height: 14),
          if (adaptiveLine case final line?) ...[
            const SizedBox(height: 10),
            Text(
              line,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          MacroRings(
            meals: meals,
            calorieTarget: summary.targetCalories,
            proteinTarget: proteinTarget,
            trackProtein: trackProtein,
            full: showMacros,
            onUnlock: () => showPlusPaywall(context),
          ),
        ],
      ),
    );
  }
}

/// A thick, fully rounded bar on a cream track, its fill a little lighter
/// at the start, like the icon's arc.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    this.height = 12,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.lerp(color, Colors.white, 0.3)!, color],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

/// Today's meals as plain rows in one card.
class _MealsCard extends StatelessWidget {
  const _MealsCard({
    required this.meals,
    required this.showProtein,
    required this.showMacros,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  final List<Meal> meals;
  final bool showProtein;
  final bool showMacros;
  final ValueChanged<Meal> onEditMeal;
  final Future<void> Function(Meal meal) onDeleteMeal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Today\'s meals',
                    style: AppTheme.display.copyWith(
                      fontSize: 19,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (meals.isNotEmpty)
                  StatusPill(
                    label: '${meals.length} logged',
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
          if (meals.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12, right: 14),
              child: BowlNote('Nothing logged yet. Type or tap the mic below.'),
            )
          else
            for (var index = 0; index < meals.length; index++) ...[
              if (index > 0) const Divider(height: 1, endIndent: 14),
              MealRow(
                meal: meals[index],
                showProtein: showProtein,
                showMacros: showMacros,
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
                  style: AppTheme.display.copyWith(
                    fontSize: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'History',
                      style: AppTheme.display.copyWith(
                        fontSize: 14,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                    height: 88,
                    child: CalorieBars(
                      days: days,
                      summariesByDate: summariesByDate,
                      showProtein: ref.watch(trackProteinProvider),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          summaries.isEmpty
                              ? 'No logged days yet this month.'
                              : '${summaries.length} days logged',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: '${count(DailyStatus.green)}',
                        color: AppColors.veryGood,
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        label: '${count(DailyStatus.yellow)}',
                        color: AppColors.bad,
                      ),
                      const SizedBox(width: 8),
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

class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestWeightEntryProvider).valueOrNull;
    final unit = ref.watch(weightUnitProvider);
    final daysAgo = latest == null
        ? 0
        : DateTime.now().difference(latest.date).inDays;

    return AppCard(
      onTap: () => context.push(AppRoutes.progress),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        children: [
          const IconBubble(Icons.monitor_weight_outlined, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight',
                  style: AppTheme.display.copyWith(
                    fontSize: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  latest == null
                      ? 'Log your weight to track progress'
                      : daysAgo > 7
                      ? 'Latest: ${formatWeight(latest.weightKg, unit)}'
                            ' · $daysAgo days ago'
                      : 'Latest: ${formatWeight(latest.weightKg, unit)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => logWeightWithFeedback(context),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}
