import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';

/// A 1x1 PNG, so recipe photos decode in tests.
final testPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Stands in for the website: every photo is the test pixel.
ImageProvider pixelImage(String url) => MemoryImage(testPixel);

Recipe testRecipe(
  String name, {
  RecipeCategory category = RecipeCategory.dinner,
  int kcal = 500,
  int protein = 40,
  int servings = 4,
  int minutes = 30,
  int prepMinutes = 10,
}) => Recipe(
  id: name.toLowerCase().replaceAll(' ', '-'),
  name: name,
  cuisine: 'Italian',
  category: category,
  tags: const [RecipeTag.highProtein],
  servings: servings,
  minutes: minutes,
  prepMinutes: prepMinutes,
  kcalPerPortion: kcal,
  proteinPerPortion: protein,
  macrosPerPortion: const Nutrients(
    fat: 14,
    saturates: 5,
    carbs: 60,
    sugars: 9,
    fibre: 5,
    salt: 1.4,
  ),
  ingredients: const [
    (
      item: 'Beef mince',
      amount: '500 g',
      kcal: null,
      protein: null,
      macros: null,
    ),
    (
      item: 'Spaghetti',
      amount: '320 g',
      kcal: null,
      protein: null,
      macros: null,
    ),
  ],
  steps: const ['Brown the mince for 5 minutes.', 'Simmer and serve.'],
);
