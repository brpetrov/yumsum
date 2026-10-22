import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/repositories/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(FirebaseFirestore.instance);
});

/// The user's recent meals for one-tap re-logging: each name once (case
/// insensitive, keeping the latest entry), unnamed meals skipped, at most
/// 50. Refreshed by [LogMealController] after every change.
final recentMealsProvider = FutureProvider.autoDispose<List<Meal>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];
  final meals = await ref.watch(mealRepositoryProvider).fetchRecentMeals(uid);
  return distinctRecentMeals(meals);
});

/// [meals] newest first, reduced to the latest meal per name.
List<Meal> distinctRecentMeals(List<Meal> meals, {int max = 50}) {
  final seen = <String>{};
  return [
    for (final meal in meals)
      if (meal.name != null && seen.add(meal.name!.trim().toLowerCase())) meal,
  ].take(max).toList();
}

/// Streams meals for the current user on [date] (yyyy-MM-dd).
final mealsForDateProvider = StreamProvider.autoDispose
    .family<List<Meal>, String>((ref, date) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return const Stream.empty();
      return ref.watch(mealRepositoryProvider).watchMealsForDate(uid, date);
    });
