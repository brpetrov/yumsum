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

/// Recipes with every word of [query] in their name, meal, cuisine, labels
/// or ingredients, in library order; all of them for a blank query. Plurals
/// and accents don't matter, a word may be half typed ("chick"), and a few
/// everyday words stand for others ("fish" finds salmon, cod and tuna).
List<Recipe> searchRecipes(List<Recipe> recipes, String query) {
  final words = _words(query);
  final wanted = [
    for (final word in words)
      // "chicken and rice" means chicken and rice; "to" alone is half typed.
      if (words.length == 1 || !_fillers.contains(word)) _stem(word),
  ];
  if (wanted.isEmpty) return recipes;
  return [
    for (final recipe in recipes)
      if (_hasAll(recipe, wanted)) recipe,
  ];
}

bool _hasAll(Recipe recipe, List<String> wanted) {
  final about = [
    recipe.name,
    recipe.cuisine,
    recipe.category.label,
    for (final tag in recipe.tags) tag.json,
  ].join(' ');
  final words = {
    for (final word in _words(about)) ...{word, _stem(word)},
  };
  for (final ingredient in recipe.ingredients) {
    final item = _words(ingredient.item);
    for (final (i, word) in item.indexed) {
      final next = i + 1 < item.length ? _stem(item[i + 1]) : null;
      // Egg noodles hold no eggs and Greek yoghurt makes no dish Greek,
      // unless the search names the noodles or the yoghurt too.
      if (next != null &&
          _describes[word] == next &&
          !wanted.any(next.startsWith)) {
        continue;
      }
      words.addAll({word, _stem(word)});
    }
  }
  return wanted.every(
    (want) => [
      want,
      ...?_alsoMeans[want],
    ].any((term) => words.any((word) => word.startsWith(term))),
  );
}

const _fillers = {
  'a',
  'an',
  'and',
  'for',
  'in',
  'of',
  'on',
  'or',
  'the',
  'to',
  'with',
};

/// Ingredient words that only describe the next word.
const _describes = {
  'egg': 'noodle',
  'greek': 'yoghurt',
  'chicken': 'stock',
  'beef': 'stock',
  'vegetable': 'stock',
};

/// Everyday words for what the library calls something else.
const _alsoMeans = {
  'cheese': ['feta', 'parmesan', 'cheddar', 'sirene'],
  'fish': ['salmon', 'cod', 'tuna'],
  'seafood': ['prawn'],
  'shrimp': ['prawn'],
  'pasta': ['spaghetti', 'tagliatelle'],
  'veggie': ['vegetarian'],
  'yogurt': ['yoghurt'],
};

const _plainLetters = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
};

final _wordBreak = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Lower-case words without accents: "Niçoise salad" → [nicoise, salad].
List<String> _words(String text) => text
    .toLowerCase()
    .split('')
    .map((c) => _plainLetters[c] ?? c)
    .join()
    .split(_wordBreak)
    .where((word) => word.isNotEmpty)
    .toList();

/// Plural to singular, roughly: berries → berry, tomatoes → tomato,
/// eggs → egg. Applied to both sides, so a rough guess still matches.
String _stem(String word) {
  if (word.length > 4 && word.endsWith('ies')) {
    return '${word.substring(0, word.length - 3)}y';
  }
  if (word.length > 4 && word.endsWith('oes')) {
    return word.substring(0, word.length - 2);
  }
  if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
    return word.substring(0, word.length - 1);
  }
  return word;
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
