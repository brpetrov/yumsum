import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/meal_provider.dart';

Meal _meal(String id, String? name, double kcal) => Meal(
  id: id,
  date: '2026-10-16',
  timestamp: DateTime(2026, 10, 16, 12),
  name: name,
  calories: kcal,
  createdAt: DateTime(2026, 10, 16, 12),
  updatedAt: DateTime(2026, 10, 16, 12),
);

/// A meal had on 16 + [day] October at [hour]:[minute].
Meal _at(String name, double kcal, int day, int hour, [int minute = 0]) {
  final at = DateTime(2026, 10, day, hour, minute);
  return Meal(
    id: '$name $day $hour',
    date: '2026-10-${day.toString().padLeft(2, '0')}',
    timestamp: at,
    name: name,
    calories: kcal,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  test('keeps the latest entry per name and skips unnamed meals', () {
    final recents = distinctRecentMeals([
      _meal('1', 'Musaka', 640),
      _meal('2', null, 200),
      _meal('3', 'musaka ', 600),
      _meal('4', 'Apple', 80),
    ]);

    expect(recents.map((meal) => meal.id), ['1', '4']);
  });

  test('caps the list', () {
    final recents = distinctRecentMeals([
      for (var i = 0; i < 60; i++) _meal('$i', 'Meal $i', 100),
    ]);

    expect(recents.length, 50);
  });

  test('usual meals are those had at this time on more than one day', () {
    final now = DateTime(2026, 10, 22, 12, 15);
    final usual = usualMealsAt([
      _at('Ham sandwich', 500, 21, 12, 30),
      _at('Coffee', 60, 21, 11),
      _at('Musaka', 640, 21, 19),
      _at('ham sandwich ', 480, 20, 13, 30),
      _at('Coffee', 50, 20, 11, 30),
      _at('Musaka', 640, 20, 19),
      _at('Apple', 80, 20, 12),
      _at('Ham sandwich', 480, 19, 12),
    ], now);

    // Musaka is an evening meal and Apple was had once; the sandwich
    // (three times) leads, carrying its latest figures.
    expect(usual.map((meal) => meal.name), ['Ham sandwich', 'Coffee']);
    expect(usual.first.calories, 500);
  });

  test('usual meals skip what is already logged today, and wrap midnight', () {
    final usual = usualMealsAt([
      _at('Ham sandwich', 500, 22, 12),
      _at('Toast', 200, 21, 23, 50),
      _at('Ham sandwich', 500, 21, 12),
      _at('Toast', 200, 20, 23, 30),
      _at('Ham sandwich', 500, 20, 12),
    ], DateTime(2026, 10, 22, 0, 30));

    expect(usual.map((meal) => meal.name), ['Toast']);
  });
}
