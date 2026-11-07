import 'dart:convert';

import 'package:lean_streak/l10n/l10n.dart';
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

  /// In English, for search and the AI's facts; [shownLabel] is the one on
  /// screen.
  final String label;

  /// The meal as the app shows it, in [l10n]'s language.
  String shownLabel(AppLocalizations l10n) => switch (this) {
    RecipeCategory.breakfast => l10n.recipesBreakfast,
    RecipeCategory.lunch => l10n.recipesLunch,
    RecipeCategory.dinner => l10n.recipesDinner,
    RecipeCategory.snack => l10n.recipesSnack,
  };
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

/// A recipe's words in one language: what the list and the recipe page
/// show. The ingredients are in the library's order, one for each English
/// one, whose figures they share.
typedef RecipeText = ({
  String name,
  String? description,
  String cuisine,
  List<({String item, String amount})> ingredients,
  List<String> steps,
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
    this.bg,
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

  /// The Bulgarian, shown when the app is in Bulgarian. Every library
  /// recipe has it; the fields above are the English.
  final RecipeText? bg;

  /// Reads one recipe strictly: anything missing or out of range throws a
  /// [FormatException] naming the recipe and the field, so a bad library
  /// fails its test instead of showing odd numbers.
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final label = 'recipe ${id is String ? id : '?'}';
    Never bad(String field) => throw FormatException('$label: $field');

    String textIn(
      Map<String, dynamic> from,
      String field,
      int max, {
      bool optional = false,
    }) {
      final value = from[field];
      if (value == null && optional) return '';
      if (value is! String || value.trim().isEmpty || value.length > max) {
        bad(from == json ? field : 'bg.$field');
      }
      return value.trim();
    }

    String text(String field, int max, {bool optional = false}) =>
        textIn(json, field, max, optional: optional);

    List<String> lines(Object? raw, String field) {
      if (raw is! List || raw.isEmpty) bad(field);
      return [
        for (final line in raw)
          if (line is String && line.trim().isNotEmpty)
            line.trim()
          else
            bad(field),
      ];
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

    final steps = lines(json['steps'], 'steps');

    // The Bulgarian: the same words, and an item and amount for each
    // ingredient, in the same order.
    RecipeText? bulgarian() {
      final raw = json['bg'];
      if (raw == null) return null;
      if (raw is! Map<String, dynamic>) bad('bg');
      final items = raw['ingredients'];
      if (items is! List || items.length != ingredients.length) {
        bad('bg.ingredients');
      }
      final description = textIn(raw, 'description', 140, optional: true);
      return (
        name: textIn(raw, 'name', 60),
        description: description.isEmpty ? null : description,
        cuisine: textIn(raw, 'cuisine', 30),
        ingredients: [
          for (final entry in items)
            if (entry is Map<String, dynamic>)
              (
                item: textIn(entry, 'item', 80),
                amount: textIn(entry, 'amount', 40),
              )
            else
              bad('bg.ingredients'),
        ],
        steps: lines(raw['steps'], 'bg.steps'),
      );
    }

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
      bg: bulgarian(),
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

  /// Its words in [language] ('en' or 'bg'): the Bulgarian where it has
  /// them, else the English.
  RecipeText textIn(String language) => language == 'bg' && bg != null
      ? bg!
      : (
          name: name,
          description: description,
          cuisine: cuisine,
          ingredients: [
            for (final i in ingredients) (item: i.item, amount: i.amount),
          ],
          steps: steps,
        );

  /// Its name in [language].
  String nameIn(String language) => language == 'bg' ? bg?.name ?? name : name;

  /// Whether [text] is its name in any language, whatever the case: a meal
  /// logged in English is still this recipe once the app is in Bulgarian,
  /// and the other way round.
  bool isNamed(String text) {
    final wanted = text.trim().toLowerCase();
    return wanted == name.toLowerCase() || wanted == bg?.name.toLowerCase();
  }

  /// What a logged meal of [portions] is called, in [l10n]'s language, so
  /// the day's list explains its calories: "Pasta bolognese", or "Pasta
  /// bolognese × 1.5", "Паста болонезе × 1,5".
  String mealName(double portions, AppLocalizations l10n) {
    final shown = nameIn(l10n.localeName);
    if (portions == 1) return shown;
    return '$shown × '
        '${portions % 1 == 0 ? portions.toInt() : l10n.decimal(portions)}';
  }
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
