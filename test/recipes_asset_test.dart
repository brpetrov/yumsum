import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';

/// The gate for the recipe library: run after adding recipes or photos.
/// Every recipe must parse, add up, and have its photo ready for the
/// website, in `tools/hosting/recipes/`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Recipe> recipes;

  setUpAll(() async {
    recipes = parseRecipes(
      await rootBundle.loadString('assets/recipes/recipes.json'),
    );
  });

  test('ids are unique', () {
    final ids = recipes.map((r) => r.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('the ingredients add up to the per-portion figures', () {
    for (final recipe in recipes) {
      final items = recipe.ingredients;
      if (items.any((i) => i.kcal == null)) continue;
      final kcal = items.fold<int>(0, (sum, i) => sum + i.kcal!);
      final perPortion = kcal / recipe.servings;
      expect(
        (perPortion - recipe.kcalPerPortion).abs(),
        lessThanOrEqualTo(recipe.kcalPerPortion * 0.1),
        reason: '${recipe.id}: ingredients come to ${perPortion.round()} kcal',
      );
      if (items.any((i) => i.protein == null)) continue;
      final protein =
          items.fold<int>(0, (sum, i) => sum + i.protein!) / recipe.servings;
      expect(
        (protein - recipe.proteinPerPortion).abs(),
        lessThanOrEqualTo(3 + recipe.proteinPerPortion * 0.1),
        reason:
            '${recipe.id}: ingredients come to ${protein.round()} g protein',
      );
    }
  });

  List<double?> six(Nutrients? n) => [
    n?.fat,
    n?.saturates,
    n?.carbs,
    n?.sugars,
    n?.fibre,
    n?.salt,
  ];
  const names = ['fat', 'saturates', 'carbs', 'sugars', 'fibre', 'salt'];

  test('the ingredients add up to the per-portion macros', () {
    for (final recipe in recipes) {
      final items = recipe.ingredients;
      if (items.any((i) => six(i.macros).contains(null))) continue;
      final portion = six(recipe.macrosPerPortion);
      for (var n = 0; n < names.length; n++) {
        final sum =
            items.fold<double>(0, (total, i) => total + six(i.macros)[n]!) /
            recipe.servings;
        final given = portion[n]!;
        final reason =
            '${recipe.id}: ingredients come to ${sum.toStringAsFixed(1)} g '
            '${names[n]}';
        if (names[n] == 'salt') {
          // The method's pinch of seasoning (0.5 g a portion) is on the
          // portion only.
          final slack = 0.2 + given * 0.1;
          expect(given, greaterThanOrEqualTo(sum - slack), reason: reason);
          expect(given, lessThanOrEqualTo(sum + 0.5 + slack), reason: reason);
        } else {
          expect(
            (sum - given).abs(),
            lessThanOrEqualTo(1 + given * 0.1),
            reason: reason,
          );
        }
      }
    }
  });

  test('saturates are part of the fat and sugars part of the carbs', () {
    for (final recipe in recipes) {
      for (final n in [
        recipe.macrosPerPortion,
        ...recipe.ingredients.map((i) => i.macros).nonNulls,
      ]) {
        expect(n.saturates!, lessThanOrEqualTo(n.fat!), reason: recipe.id);
        expect(n.sugars!, lessThanOrEqualTo(n.carbs!), reason: recipe.id);
      }
    }
  });

  test('the macros account for the calories', () {
    for (final recipe in recipes) {
      final n = recipe.macrosPerPortion;
      final kcal =
          4 * recipe.proteinPerPortion +
          4 * n.carbs! +
          9 * n.fat! +
          2 * n.fibre!;
      expect(
        (kcal - recipe.kcalPerPortion).abs(),
        lessThanOrEqualTo(recipe.kcalPerPortion * 0.15),
        reason: '${recipe.id}: the macros come to ${kcal.round()} kcal',
      );
    }
  });

  test('every recipe has a small WebP photo for the website', () {
    for (final recipe in recipes) {
      final file = File('tools/hosting/recipes/${recipe.id}.webp');
      expect(file.existsSync(), isTrue, reason: '${recipe.id}: no photo');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, lessThanOrEqualTo(80 * 1024), reason: recipe.id);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
    }
  });

  test('the library is complete', () {
    expect(recipes.length, greaterThanOrEqualTo(30));
  });
}
