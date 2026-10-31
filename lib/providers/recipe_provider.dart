import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';

/// The recipe library, read once from the app's own files.
final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  return parseRecipes(
    await rootBundle.loadString('assets/recipes/recipes.json'),
  );
});

/// How a recipe photo is fetched: from the website, kept on the phone after
/// the first download. Overridden in tests, which never touch the network.
final recipeImageProvider = Provider<ImageProvider Function(String url)>(
  (ref) =>
      (url) => CachedNetworkImageProvider(url, maxWidth: 640),
);

/// Calories left today, the same figure Today shows; null until something
/// is logged, when every recipe would "fit" and saying so means nothing.
final remainingCaloriesTodayProvider = Provider.autoDispose<int?>((ref) {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final summary = ref.watch(dailySummaryForDateProvider(today)).valueOrNull;
  if (summary == null || summary.mealCount == 0) return null;
  return summary.targetCalories - summary.totalCalories;
});

/// Whether a portion of [recipe] fits in what's left of today.
bool fitsRemaining(Recipe recipe, int? remaining) =>
    remaining != null && remaining > 0 && recipe.kcalPerPortion <= remaining;

/// Recipes whose name contains [query], in library order.
List<Recipe> matchingRecipes(List<Recipe> recipes, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final recipe in recipes)
      if (recipe.name.toLowerCase().contains(q)) recipe,
  ];
}

final _portionsSuffix = RegExp(r'\s×\s[\d.]+$');

/// Recipes logged in the last 14 days, newest first, found by the meal's
/// name: a logged "Pasta bolognese × 1.5" counts as Pasta bolognese.
List<Recipe> recentlyCookedRecipes(
  List<Recipe> recipes,
  List<Meal> meals,
  DateTime now,
) {
  final byName = {for (final r in recipes) r.name.toLowerCase(): r};
  final since = now.subtract(const Duration(days: 14));
  final found = <Recipe>[];
  final sorted = [...meals]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  for (final meal in sorted) {
    if (meal.timestamp.isBefore(since)) continue;
    final name = meal.name?.replaceFirst(_portionsSuffix, '').trim();
    final recipe = name == null ? null : byName[name.toLowerCase()];
    if (recipe != null && !found.contains(recipe)) found.add(recipe);
  }
  return found;
}
