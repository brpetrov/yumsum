import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/repositories/day_edit_repository.dart';
import 'package:lean_streak/repositories/meal_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';

// ignore: subtype_of_sealed_class
class _FakeRef extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  String get id => 'new-meal';
}

class _FakeMeals extends Fake implements MealRepository {
  final saved = <Meal>[];

  @override
  DocumentReference<Map<String, dynamic>> newMealRef(String uid) => _FakeRef();

  @override
  Future<void> addMeal(String uid, Meal meal) async => saved.add(meal);

  @override
  Future<void> updateMeal(String uid, Meal meal) async => saved.add(meal);
}

class _FakeDayEdits extends Fake implements DayEditRepository {
  int counted = 0;

  @override
  Future<int> fetchCount(String uid, String monthKey) async => 0;

  @override
  Future<void> increment(String uid, String monthKey) async => counted++;
}

class _FakeSummaryService extends Fake implements DailySummaryService {
  final recomputed = <String>[];

  @override
  Future<void> recomputeForDate(String uid, String date) async =>
      recomputed.add(date);
}

void main() {
  late _FakeMeals meals;
  late _FakeDayEdits dayEdits;
  late _FakeSummaryService summaries;

  /// Saves an unnamed meal (so no AI is asked) and returns what was stored.
  Future<Meal> save({Meal? existingMeal, String? date, TimeOfDay? time}) async {
    meals = _FakeMeals();
    dayEdits = _FakeDayEdits();
    summaries = _FakeSummaryService();
    final container = ProviderContainer(
      overrides: [
        currentUidProvider.overrideWithValue('user-1'),
        mealRepositoryProvider.overrideWithValue(meals),
        dayEditRepositoryProvider.overrideWithValue(dayEdits),
        dailySummaryServiceProvider.overrideWithValue(summaries),
        adminProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(logMealControllerProvider.notifier)
        .submit(
          existingMeal: existingMeal,
          date: date,
          calories: 400,
          time: time,
        );
    expect(container.read(logMealControllerProvider).hasError, isFalse);
    return meals.saved.single;
  }

  final porridge = Meal(
    id: 'm1',
    date: '2026-10-12',
    timestamp: DateTime(2026, 10, 12, 13, 4, 30),
    calories: 350,
    createdAt: DateTime(2026, 10, 12, 13, 4, 30),
    updatedAt: DateTime(2026, 10, 12, 13, 4, 30),
  );

  test('a new meal with a time goes on today at that time', () async {
    final now = DateTime.now();
    final meal = await save(time: const TimeOfDay(hour: 8, minute: 15));
    expect(meal.date, DateFormat('yyyy-MM-dd').format(now));
    expect(meal.timestamp, DateTime(now.year, now.month, now.day, 8, 15));
    expect(dayEdits.counted, 0);
  });

  test('a new meal on a past day with a time goes on that day at that '
      'time', () async {
    final meal = await save(
      date: '2026-10-10',
      time: const TimeOfDay(hour: 19, minute: 45),
    );
    expect(meal.date, '2026-10-10');
    expect(meal.timestamp, DateTime(2026, 10, 10, 19, 45));
    expect(summaries.recomputed, ['2026-10-10']);
    expect(dayEdits.counted, 1);
  });

  test('an edit with a time keeps the date and changes the time', () async {
    final meal = await save(
      existingMeal: porridge,
      date: '2026-10-12',
      time: const TimeOfDay(hour: 8, minute: 0),
    );
    expect(meal.id, 'm1');
    expect(meal.date, '2026-10-12');
    expect(meal.timestamp, DateTime(2026, 10, 12, 8));
    expect(summaries.recomputed, ['2026-10-12']);
    // A change to a past day, as any edit of one is.
    expect(dayEdits.counted, 1);
  });

  test('an edit without a time keeps the timestamp', () async {
    final meal = await save(existingMeal: porridge, date: '2026-10-12');
    expect(meal.timestamp, porridge.timestamp);
    expect(meal.date, '2026-10-12');
  });
}
