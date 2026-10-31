import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
