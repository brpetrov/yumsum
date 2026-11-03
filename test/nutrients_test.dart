import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';

Meal _meal({String? name = 'Chicken wrap', Nutrients? macros}) => Meal(
  id: 'm1',
  date: '2026-11-03',
  timestamp: DateTime(2026, 11, 3, 12, 40),
  name: name,
  calories: 400,
  proteinGrams: 30,
  macros: macros,
  createdAt: DateTime(2026, 11, 3, 12, 40),
  updatedAt: DateTime(2026, 11, 3, 12, 40),
);

void main() {
  const wrap = Nutrients(
    fat: 18,
    saturates: 6,
    carbs: 52,
    sugars: 5,
    fibre: 4,
    salt: 2.1,
  );

  test('scales every known figure and keeps unknowns unknown', () {
    final half = const Nutrients(fat: 18, salt: 2.1).scaled(0.5);
    expect(half.fat, 9);
    expect(half.salt, closeTo(1.05, 1e-9));
    expect(half.carbs, isNull);
  });

  test('totals each nutrient over the entries that have it', () {
    final total = Nutrients.total([
      const Nutrients(fat: 10, fibre: 3),
      null,
      const Nutrients(fat: 5.5, salt: 0.4),
    ])!;
    expect(total.fat, 15.5);
    expect(total.fibre, 3);
    expect(total.salt, 0.4);
    expect(total.sugars, isNull);
    expect(Nutrients.total([null, null]), isNull);
    expect(Nutrients.total([]), isNull);
  });

  test('a meal stores only the known figures, to 0.1 g', () {
    final data = _meal(
      macros: const Nutrients(fat: 18.26, salt: 2.04),
    ).toFirestore();
    expect(data, containsPair('fatGrams', 18.3));
    expect(data, containsPair('saltGrams', 2.0));
    expect(data.containsKey('carbsGrams'), isFalse);

    final back = Nutrients.fromFields(data)!;
    expect(back.fat, 18.3);
    expect(back.salt, 2.0);
    expect(back.carbs, isNull);
  });

  test('a meal without macros stores none and reads back as null', () {
    final data = _meal().toFirestore();
    expect(data.keys.where((key) => key.endsWith('Grams')), ['proteinGrams']);
    expect(Nutrients.fromFields(data), isNull);
  });

  test('reads Open Food Facts figures, with salt from sodium', () {
    final macros = nutrientsFromOff({
      'fat_100g': 9.5,
      'saturated-fat_100g': '3.1',
      'carbohydrates_100g': 24,
      'sugars_100g': -1,
      'sodium_100g': 0.4,
    }, suffix: '_100g')!;
    expect(macros.fat, 9.5);
    expect(macros.saturates, 3.1);
    expect(macros.carbs, 24);
    expect(macros.sugars, isNull);
    expect(macros.fibre, isNull);
    expect(macros.salt, 1.0);

    expect(
      nutrientsFromOff({
        'salt_100g': 1.2,
        'sodium_100g': 0.4,
      }, suffix: '_100g')?.salt,
      1.2,
    );
    expect(
      nutrientsFromOff({'energy-kcal_100g': 100}, suffix: '_100g'),
      isNull,
    );
    expect(nutrientsFromOff({'fat': 3.0, 'fiber': 2.5})?.fibre, 2.5);
  });

  group('the edit rule', () {
    test('keeps the meal\'s own macros, scaled to the new calories', () {
      final kept = macrosAfterEdit(_meal(macros: wrap), 'Chicken wrap', 500)!;
      expect(kept.fat, 22.5);
      expect(kept.salt, closeTo(2.625, 1e-9));
    });

    test('a renamed meal loses them', () {
      expect(macrosAfterEdit(_meal(macros: wrap), 'Tuna wrap', 400), isNull);
      expect(macrosAfterEdit(_meal(macros: wrap), null, 400), isNull);
    });

    test('a meal without macros has none to keep', () {
      expect(macrosAfterEdit(_meal(), 'Chicken wrap', 400), isNull);
    });
  });
}
