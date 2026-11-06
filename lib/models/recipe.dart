import 'dart:convert';

import 'package:lean_streak/models/nutrients.dart';

/// Where the recipe photos are served from. They ship with the website
/// (`tools/hosting/recipes/`), not the app, so the app stays small.
const recipePhotoBase = 'https://yumsum.web.app/recipes/';

enum RecipeCategory {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const RecipeCategory(this.label);
  final String label;
}

enum RecipeTag {
  highProtein('high-protein'),
  vegetarian('vegetarian'),
  vegan('vegan'),
  quick('quick'),
  lowCalorie('low-calorie');

  const RecipeTag(this.json);
  final String json;
}

/// One line of the shopping list, for the whole recipe. [kcal], [protein]
/// and [macros] are the ingredient's share, given so the totals can be
/// checked.
typedef Ingredient = ({
  String item,
  String amount,
  int? kcal,
  int? protein,
  Nutrients? macros,
});

final _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

const _macroKeys = ['fat', 'saturates', 'carbs', 'sugars', 'fibre', 'salt'];

/// A dish from the bundled library (`assets/recipes/recipes.json`). The
/// nutrition is per portion; the ingredients are for [servings] portions.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    this.description,
    required this.cuisine,
    required this.category,
    required this.tags,
    required this.servings,
    required this.minutes,
    required this.prepMinutes,
    required this.kcalPerPortion,
    required this.proteinPerPortion,
    required this.macrosPerPortion,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String name;
  final String? description;
  final String cuisine;
  final RecipeCategory category;
  final List<RecipeTag> tags;
  final int servings;

  /// Prep plus cooking.
  final int minutes;

  /// Chopping, mixing and the like, before anything cooks.
  final int prepMinutes;
  final int kcalPerPortion;
  final int proteinPerPortion;

  /// All six are known for a library recipe.
  final Nutrients macrosPerPortion;
  final List<Ingredient> ingredients;
  final List<String> steps;

  /// Reads one recipe strictly: anything missing or out of range throws a
  /// [FormatException] naming the recipe and the field, so a bad library
  /// fails its test instead of showing odd numbers.
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final label = 'recipe ${id is String ? id : '?'}';
    Never bad(String field) => throw FormatException('$label: $field');

    String text(String field, int max, {bool optional = false}) {
      final value = json[field];
      if (value == null && optional) return '';
      if (value is! String || value.trim().isEmpty || value.length > max) {
        bad(field);
      }
      return value.trim();
    }

    int number(String field, int min, int max) {
      final value = json[field];
      if (value is! int || value < min || value > max) bad(field);
      return value;
    }

    // Grams, to one decimal place.
    double grams(String field, double max) {
      final value = json[field];
      if (value is! num || value < 0 || value > max) bad(field);
      return value.toDouble();
    }

    if (id is! String || !_idPattern.hasMatch(id)) bad('id');
    final category = RecipeCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => bad('category'),
    );
    final rawTags = json['tags'];
    if (rawTags is! List) bad('tags');
    final tags = [
      for (final tag in rawTags)
        RecipeTag.values.firstWhere(
          (t) => t.json == tag,
          orElse: () => bad('tags'),
        ),
    ];
    if (tags.toSet().length != tags.length) bad('tags');

    final rawIngredients = json['ingredients'];
    if (rawIngredients is! List || rawIngredients.isEmpty) bad('ingredients');
    final ingredients = <Ingredient>[
      for (final entry in rawIngredients)
        if (entry is Map &&
            entry['item'] is String &&
            (entry['item'] as String).trim().isNotEmpty &&
            entry['amount'] is String &&
            (entry['kcal'] == null || entry['kcal'] is int) &&
            (entry['protein'] == null || entry['protein'] is int) &&
            _macroKeys.every(
              (key) =>
                  entry[key] == null || (entry[key] is num && entry[key] >= 0),
            ))
          (
            item: (entry['item'] as String).trim(),
            amount: (entry['amount'] as String).trim(),
            kcal: entry['kcal'] as int?,
            protein: entry['protein'] as int?,
            macros: _macroKeys.any((key) => entry[key] != null)
                ? Nutrients(
                    fat: (entry['fat'] as num?)?.toDouble(),
                    saturates: (entry['saturates'] as num?)?.toDouble(),
                    carbs: (entry['carbs'] as num?)?.toDouble(),
                    sugars: (entry['sugars'] as num?)?.toDouble(),
                    fibre: (entry['fibre'] as num?)?.toDouble(),
                    salt: (entry['salt'] as num?)?.toDouble(),
                  )
                : null,
          )
        else
          bad('ingredients'),
    ];

    final rawSteps = json['steps'];
    if (rawSteps is! List || rawSteps.isEmpty) bad('steps');
    final steps = [
      for (final step in rawSteps)
        if (step is String && step.trim().isNotEmpty)
          step.trim()
        else
          bad('steps'),
    ];

    final description = text('description', 140, optional: true);
    final minutes = number('minutes', 1, 600);
    final fat = grams('fatPerPortion', 150);
    final carbs = grams('carbsPerPortion', 300);
    return Recipe(
      id: id,
      name: text('name', 60),
      description: description.isEmpty ? null : description,
      cuisine: text('cuisine', 30),
      category: category,
      tags: tags,
      servings: number('servings', 1, 12),
      minutes: minutes,
      prepMinutes: number('prepMinutes', 0, minutes),
      kcalPerPortion: number('kcalPerPortion', 50, 1500),
      proteinPerPortion: number('proteinPerPortion', 0, 150),
      macrosPerPortion: Nutrients(
        fat: fat,
        saturates: grams('saturatesPerPortion', fat),
        carbs: carbs,
        sugars: grams('sugarsPerPortion', carbs),
        fibre: grams('fibrePerPortion', 80),
        salt: grams('saltPerPortion', 15),
      ),
      ingredients: ingredients,
      steps: steps,
    );
  }

  String get photoUrl => '$recipePhotoBase$id.webp';

  /// At least 8 g of fibre a portion, over a quarter of the 30 g a day.
  bool get highFibre => macrosPerPortion.fibre! >= 8;

  /// The rest of [minutes] after the prep; 0 for dishes with no cooking.
  int get cookMinutes => minutes - prepMinutes;

  int kcalFor(double portions) => (kcalPerPortion * portions).round();
  int proteinFor(double portions) => (proteinPerPortion * portions).round();
  Nutrients macrosFor(double portions) => macrosPerPortion.scaled(portions);

  /// What a logged meal of [portions] is called, so the day's list explains
  /// its calories: "Pasta bolognese", or "Pasta bolognese × 1.5".
  String mealName(double portions) => portions == 1
      ? name
      : '$name × ${portions % 1 == 0 ? portions.toInt() : portions}';
}

/// The library file, a JSON array of recipes, in its own order.
List<Recipe> parseRecipes(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) throw const FormatException('recipes: not a list');
  return [
    for (final entry in decoded)
      if (entry is Map<String, dynamic>)
        Recipe.fromJson(entry)
      else
        throw const FormatException('recipes: an entry is not an object'),
  ];
}
