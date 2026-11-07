import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';

/// A chip in the quick-log bar: one of the user's own meals, or a portion
/// of a library recipe.
typedef MealSuggestion = ({
  String name,
  int kcal,
  int? protein,
  Nutrients? macros,
  bool fromRecipe,
});

/// What the bar offers for [query]. With nothing typed, the meals usually
/// had around [now] (never recipes, which would only be noise). Once typing,
/// up to three matches: the user's own meals first, with a matching recipe
/// always given one place, and a recipe that's already among the user's
/// meals (in either language) left out, since their own latest figures win.
/// A recipe is found by its name in either language and offered in
/// [language].
List<MealSuggestion> suggestionsFor({
  required List<Meal> recents,
  required List<Recipe> recipes,
  required String query,
  required DateTime now,
  String language = 'en',
}) {
  MealSuggestion fromMeal(Meal meal) => (
    name: meal.name!,
    kcal: meal.calories.round(),
    protein: meal.proteinGrams?.round(),
    macros: meal.macros,
    fromRecipe: false,
  );

  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return [for (final meal in usualMealsAt(recents, now)) fromMeal(meal)];
  }

  final own = [
    for (final meal in distinctRecentMeals(recents))
      if (meal.name!.toLowerCase().contains(q)) meal,
  ];
  final fromLibrary = [
    for (final recipe in matchingRecipes(recipes, q))
      if (!own.any((meal) => recipe.isNamed(meal.name!))) recipe,
  ];
  final mine = own.take(fromLibrary.isEmpty ? 3 : 2).map(fromMeal).toList();
  return [
    ...mine,
    for (final recipe in fromLibrary.take(3 - mine.length))
      (
        name: recipe.nameIn(language),
        kcal: recipe.kcalPerPortion,
        protein: recipe.proteinPerPortion,
        macros: recipe.macrosPerPortion,
        fromRecipe: true,
      ),
  ];
}
