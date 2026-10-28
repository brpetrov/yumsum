import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/repositories/day_edit_repository.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/widgets/bowl_note.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/meal_row.dart';

/// Opens one day's meals so they can be added to, edited or deleted.
Future<void> showDayMealsSheet(BuildContext context, DateTime date) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DayMealsSheet(date: date),
  );
}

class DayMealsSheet extends ConsumerStatefulWidget {
  const DayMealsSheet({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<DayMealsSheet> createState() => _DayMealsSheetState();
}

class _DayMealsSheetState extends ConsumerState<DayMealsSheet> {
  String? _error;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(widget.date);

  Future<void> _delete(Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('Remove ${meal.name ?? 'this meal'} from this day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(logMealControllerProvider.notifier).delete(meal);
    if (!mounted) return;
    final result = ref.read(logMealControllerProvider);
    setState(
      () => _error = !result.hasError
          ? null
          : result.error is EditLimitExceededException
          ? 'No past-day changes left this month.'
          : 'Could not delete the meal. Try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsForDateProvider(_dateKey)).valueOrNull;
    final summary = ref
        .watch(dailySummaryForDateProvider(_dateKey))
        .valueOrNull;
    // From the meals rather than the summary, so days logged before protein
    // existed still show it once any meal has a value.
    final proteinMeals = meals?.where((meal) => meal.proteinGrams != null);
    final protein = proteinMeals == null || proteinMeals.isEmpty
        ? null
        : proteinMeals
              .fold<double>(0, (sum, meal) => sum + meal.proteinGrams!)
              .round();
    final pastDay = isPastDay(_dateKey, DateTime.now());
    final changesLeft = pastDay
        ? DayEditRepository.monthlyLimit -
              (ref.watch(dayEditsThisMonthProvider).valueOrNull ?? 0)
        : null;
    final canChange = changesLeft == null || changesLeft > 0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        // useSafeArea only guards the top of a sheet; clear the navigation
        // bar here.
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          12,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM').format(widget.date),
                          style: AppTheme.display.copyWith(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary == null
                              ? 'Nothing logged'
                              : '${summary.totalCalories} of '
                                    '${summary.targetCalories} kcal'
                                    '${protein == null ? '' : ' · $protein g protein'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary != null)
                    StatusPill(
                      label: summary.dayOff ? 'Day off' : summary.status.label,
                      color: summary.dayOff
                          ? AppColors.primary
                          : dayStatusColor(summary.status),
                    ),
                ],
              ),
            ),
            if (changesLeft != null) ...[
              const SizedBox(height: 6),
              Text(
                '${changesLeft.clamp(0, DayEditRepository.monthlyLimit)} of '
                '${DayEditRepository.monthlyLimit} past-day changes left this month',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            if (meals == null)
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (meals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: BowlNote('No meals logged on this day.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: meals.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return MealRow(
                      meal: meal,
                      onEdit: canChange
                          ? () => showLogMealSheet(context, existingMeal: meal)
                          : () => setState(
                              () => _error =
                                  'No past-day changes left this month.',
                            ),
                      onDelete: () => _delete(meal),
                    );
                  },
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: canChange
                    ? () => showLogMealSheet(context, date: _dateKey)
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add meal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
