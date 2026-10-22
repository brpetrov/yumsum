import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/repositories/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(FirebaseFirestore.instance);
});

/// The user's latest meals, newest first, for one-tap re-logging (see
/// [distinctRecentMeals] and [usualMealsAt]). Refreshed by
/// [LogMealController] after every change.
final recentMealsProvider = FutureProvider.autoDispose<List<Meal>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];
  return ref.watch(mealRepositoryProvider).fetchRecentMeals(uid);
});

/// [meals] newest first, reduced to the latest meal per name (case
/// insensitive), unnamed meals skipped, at most [max].
List<Meal> distinctRecentMeals(List<Meal> meals, {int max = 50}) {
  final seen = <String>{};
  return [
    for (final meal in meals)
      if (meal.name != null && seen.add(_nameKey(meal.name!))) meal,
  ].take(max).toList();
}

/// The meals the user habitually has around [now]'s time of day: named
/// meals logged at least twice within 90 minutes of it on earlier days,
/// most often first, leaving out any already logged today. Each is the
/// latest entry of its name, so it carries the latest figures.
List<Meal> usualMealsAt(List<Meal> meals, DateTime now, {int max = 5}) {
  final today = DateFormat('yyyy-MM-dd').format(now);
  final minute = now.hour * 60 + now.minute;
  final eatenToday = {
    for (final meal in meals)
      if (meal.date == today && meal.name != null) _nameKey(meal.name!),
  };
  final latest = <String, Meal>{};
  final counts = <String, int>{};
  for (final meal in meals) {
    if (meal.name == null) continue;
    final key = _nameKey(meal.name!);
    if (eatenToday.contains(key)) continue;
    final gap = (meal.timestamp.hour * 60 + meal.timestamp.minute - minute)
        .abs();
    if (min(gap, 24 * 60 - gap) > 90) continue;
    latest.putIfAbsent(key, () => meal);
    counts.update(key, (times) => times + 1, ifAbsent: () => 1);
  }
  final usual = latest.keys.where((key) => counts[key]! >= 2).toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0
          ? byCount
          : latest[b]!.createdAt.compareTo(latest[a]!.createdAt);
    });
  return [for (final key in usual.take(max)) latest[key]!];
}

String _nameKey(String name) => name.trim().toLowerCase();

/// Streams meals for the current user on [date] (yyyy-MM-dd).
final mealsForDateProvider = StreamProvider.autoDispose
    .family<List<Meal>, String>((ref, date) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return const Stream.empty();
      return ref.watch(mealRepositoryProvider).watchMealsForDate(uid, date);
    });
