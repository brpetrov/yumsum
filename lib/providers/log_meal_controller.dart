import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/day_edit_repository.dart';

class LogMealController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Saves a new meal, or [existingMeal] with new values. New meals go on
  /// [date] (yyyy-MM-dd), today by default. An edit given no [macros] keeps
  /// the meal's own ([macrosAfterEdit]). Changing a past day uses one of
  /// the month's past-day changes; the state errors with
  /// [EditLimitExceededException] once they are used up.
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
    Nutrients? macros,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final repo = ref.read(mealRepositoryProvider);
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final mealDate = existingMeal?.date ?? date ?? today;
      final pastDay = isPastDay(mealDate, now);
      if (pastDay) await _ensurePastDayChangeLeft(uid);
      final docRef = existingMeal == null ? repo.newMealRef(uid) : null;
      final mealName = (name?.trim().isEmpty ?? true) ? null : name!.trim();

      var protein = proteinGrams;
      var mealMacros =
          macros ??
          (existingMeal == null
              ? null
              : macrosAfterEdit(existingMeal, mealName, calories));
      // Only named meals get the AI's figures: protein while it is tracked,
      // and macros for YumSum Star. Calorie-only entries stay uncounted.
      if (mealName != null &&
          ((protein == null && ref.read(trackProteinProvider)) ||
              (mealMacros == null && ref.read(plusProvider)))) {
        final filled = await _estimateNutrients(mealName, calories);
        // Protein it returns while protein is off is still saved.
        protein ??= filled.protein?.toDouble();
        mealMacros ??= filled.macros;
      }

      final meal = Meal(
        id: existingMeal?.id ?? docRef!.id,
        date: mealDate,
        timestamp: existingMeal?.timestamp ?? _timestampFor(mealDate, now),
        name: mealName,
        calories: calories,
        proteinGrams: protein,
        macros: mealMacros,
        createdAt: existingMeal?.createdAt ?? now,
        updatedAt: now,
      );

      if (existingMeal == null) {
        await repo.addMeal(uid, meal);
      } else {
        await repo.updateMeal(uid, meal);
      }
      if (pastDay) await _countPastDayChange(uid);

      await ref
          .read(dailySummaryServiceProvider)
          .recomputeForDate(uid, mealDate);
      refreshHistory(ref);
      ref.invalidate(recentMealsProvider);
    });
  }

  Future<void> _ensurePastDayChangeLeft(String uid) async {
    if (ref.read(adminProvider)) return;
    final used = await ref
        .read(dayEditRepositoryProvider)
        .fetchCount(uid, currentEditMonthKey());
    if (used >= DayEditRepository.monthlyLimit) {
      throw const EditLimitExceededException();
    }
  }

  Future<void> _countPastDayChange(String uid) {
    return ref
        .read(dayEditRepositoryProvider)
        .increment(uid, currentEditMonthKey());
  }

  /// A meal added to a past day keeps the current time of day, so it sorts
  /// sensibly among that day's meals.
  DateTime _timestampFor(String date, DateTime now) {
    final day = DateTime.parse(date);
    return DateTime(day.year, day.month, day.day, now.hour, now.minute);
  }

  Future<({int? protein, Nutrients? macros})> _estimateNutrients(
    String name,
    double calories,
  ) async {
    try {
      return await ref
          .read(calorieEstimateServiceProvider)
          .estimateNutrients(name, calories.round());
    } catch (_) {
      // Protein and macros are optional; never block saving the meal.
      return (protein: null, macros: null);
    }
  }

  Future<void> delete(Meal meal) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final pastDay = isPastDay(meal.date, DateTime.now());
      if (pastDay) await _ensurePastDayChangeLeft(uid);
      await ref.read(mealRepositoryProvider).deleteMeal(uid, meal.id);
      if (pastDay) await _countPastDayChange(uid);
      await ref
          .read(dailySummaryServiceProvider)
          .recomputeForDate(uid, meal.date);
      refreshHistory(ref);
      ref.invalidate(recentMealsProvider);
    });
  }
}

/// What [meal] keeps of its macros when it is saved as [name] with
/// [calories] and nothing new for them: its own, scaled to the calories,
/// unless it was renamed, since figures for a different food are worse than
/// none.
Nutrients? macrosAfterEdit(Meal meal, String? name, double calories) {
  final macros = meal.macros;
  if (macros == null || name != meal.name?.trim()) return null;
  return meal.calories > 0 ? macros.scaled(calories / meal.calories) : macros;
}

final logMealControllerProvider =
    AsyncNotifierProvider<LogMealController, void>(LogMealController.new);
