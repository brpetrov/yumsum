import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/day_off_repository.dart';
import 'package:lean_streak/repositories/meal_repository.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';

class _Unused
    implements
        MealRepository,
        UserProfileRepository,
        DailySummaryRepository,
        DayOffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('buildSummary needs no repository');
}

Meal _meal(String id, double calories, double? protein, {Nutrients? macros}) =>
    Meal(
      id: id,
      date: '2026-10-10',
      timestamp: DateTime(2026, 10, 10, 12),
      name: id,
      calories: calories,
      proteinGrams: protein,
      macros: macros,
      createdAt: DateTime(2026, 10, 10, 12),
      updatedAt: DateTime(2026, 10, 10, 12),
    );

void main() {
  final service = DailySummaryService(
    mealRepository: _Unused(),
    userProfileRepository: _Unused(),
    dailySummaryRepository: _Unused(),
    dayOffRepository: _Unused(),
  );

  test('adds up protein from the meals that have it', () {
    final summary = service.buildSummary(
      date: '2026-10-10',
      meals: [
        _meal('a', 400, 30),
        _meal('b', 200, null),
        _meal('c', 300, 12.4),
      ],
      dailyCalorieTarget: 1900,
    );

    expect(summary.totalCalories, 900);
    expect(summary.proteinGrams, 42);
  });

  test('leaves protein empty when no meal has it', () {
    final summary = service.buildSummary(
      date: '2026-10-10',
      meals: [_meal('a', 400, null)],
      dailyCalorieTarget: 1900,
    );

    expect(summary.proteinGrams, isNull);
    expect(summary.toFirestore().containsKey('proteinGrams'), isFalse);
  });

  test('totals macros over the meals that have them', () {
    final summary = service.buildSummary(
      date: '2026-10-10',
      meals: [
        _meal('a', 400, 30, macros: const Nutrients(fat: 12, salt: 1.2)),
        _meal('b', 200, null),
        _meal('c', 300, 12, macros: const Nutrients(fat: 8.5, fibre: 4)),
      ],
      dailyCalorieTarget: 1900,
    );

    expect(summary.macros?.fat, 20.5);
    expect(summary.macros?.salt, 1.2);
    expect(summary.macros?.fibre, 4);
    expect(summary.macros?.carbs, isNull);
    expect(summary.toFirestore(), containsPair('fatGrams', 20.5));
    expect(summary.toFirestore().containsKey('carbsGrams'), isFalse);
  });

  test('leaves macros out when no meal has any', () {
    final summary = service.buildSummary(
      date: '2026-10-10',
      meals: [_meal('a', 400, 30)],
      dailyCalorieTarget: 1900,
    );

    expect(summary.macros, isNull);
    expect(summary.toFirestore().keys.where((key) => key.endsWith('Grams')), [
      'proteinGrams',
    ]);
  });
}
