import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/helpers/meal_suggestions.dart';
import 'package:lean_streak/models/meal.dart';

import 'recipe_fixtures.dart';

final _now = DateTime(2026, 10, 31, 13);

Meal _meal(String name, {int daysAgo = 1, double kcal = 400}) {
  final at = _now.subtract(Duration(days: daysAgo));
  return Meal(
    id: '$name $daysAgo',
    date: DateFormat('yyyy-MM-dd').format(at),
    timestamp: at,
    name: name,
    calories: kcal,
    createdAt: at,
    updatedAt: at,
  );
}

List<String> _names(List<MealSuggestion> suggestions) => [
  for (final s in suggestions) '${s.name}${s.fromRecipe ? ' (recipe)' : ''}',
];

void main() {
  final recipes = [
    testRecipe('Pasta bolognese', kcal: 560, protein: 42),
    testRecipe('Pasta primavera'),
    testRecipe('Chicken soup'),
  ];

  test('with nothing typed, only the usual meals, never recipes', () {
    final recents = [
      _meal('Pasta salad', daysAgo: 1),
      _meal('Pasta salad', daysAgo: 2),
    ];
    expect(
      _names(
        suggestionsFor(
          recents: recents,
          recipes: recipes,
          query: ' ',
          now: _now,
        ),
      ),
      ['Pasta salad'],
    );
  });

  test('own meals first, and a matching recipe always gets a place', () {
    final recents = [
      _meal('Pasta salad'),
      _meal('Pasta bake', daysAgo: 2),
      _meal('Pasta al forno', daysAgo: 3),
    ];
    final found = suggestionsFor(
      recents: recents,
      recipes: recipes,
      query: 'pasta',
      now: _now,
    );
    expect(_names(found), [
      'Pasta salad',
      'Pasta bake',
      'Pasta bolognese (recipe)',
    ]);
    expect(found.last.kcal, 560);
    expect(found.last.protein, 42);
  });

  test('without a matching recipe, up to three own meals', () {
    final recents = [_meal('Soup'), _meal('Soup bowl'), _meal('Soup cup')];
    expect(
      suggestionsFor(
        recents: recents,
        recipes: recipes,
        query: 'soup ',
        now: _now,
      ).where((s) => !s.fromRecipe),
      hasLength(2),
    );
    expect(
      _names(
        suggestionsFor(
          recents: recents,
          recipes: const [],
          query: 'soup',
          now: _now,
        ),
      ),
      ['Soup', 'Soup bowl', 'Soup cup'],
    );
  });

  test('a recipe already among the user\'s meals isn\'t repeated', () {
    final recents = [_meal('Pasta bolognese', kcal: 700)];
    expect(
      _names(
        suggestionsFor(
          recents: recents,
          recipes: recipes,
          query: 'bolog',
          now: _now,
        ),
      ),
      ['Pasta bolognese'],
    );
  });

  test('with no own meals, recipes fill the row', () {
    expect(
      _names(
        suggestionsFor(
          recents: const [],
          recipes: recipes,
          query: 'pasta',
          now: _now,
        ),
      ),
      ['Pasta bolognese (recipe)', 'Pasta primavera (recipe)'],
    );
  });
}
