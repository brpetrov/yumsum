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
}
