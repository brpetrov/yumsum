import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/day_edit_repository.dart';

class LogMealController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Saves a new meal, or [existingMeal] with new values. New meals go on
  /// [date] (yyyy-MM-dd), today by default. Changing a past day uses one of
  /// the month's past-day changes; the state errors with
  /// [EditLimitExceededException] once they are used up.
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
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

      // Only named meals get an AI protein estimate, and only while
      // protein is tracked; calorie-only entries stay uncounted.
      final protein =
          proteinGrams ??
          (mealName == null || !ref.read(trackProteinProvider)
              ? null
              : await _estimateProtein(mealName, calories));

      final meal = Meal(
        id: existingMeal?.id ?? docRef!.id,
        date: mealDate,
        timestamp: existingMeal?.timestamp ?? _timestampFor(mealDate, now),
        name: mealName,
        calories: calories,
        proteinGrams: protein,
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

  Future<double?> _estimateProtein(String name, double calories) async {
    try {
      final grams = await ref
          .read(calorieEstimateServiceProvider)
          .estimateProtein(name, calories.round());
      return grams?.toDouble();
    } catch (_) {
      // Protein is optional; never block saving the meal.
      return null;
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

final logMealControllerProvider =
    AsyncNotifierProvider<LogMealController, void>(LogMealController.new);
