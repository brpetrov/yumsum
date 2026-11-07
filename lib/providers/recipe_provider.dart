import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/recipe.dart';

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

/// Recipes whose name in either language contains [query], in library
/// order.
List<Recipe> matchingRecipes(List<Recipe> recipes, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final recipe in recipes)
      if (recipe.name.toLowerCase().contains(q) ||
          (recipe.bg?.name.toLowerCase().contains(q) ?? false))
        recipe,
  ];
}

/// Recipes with every word of [query] in their name, meal, cuisine, labels
/// or ingredients, in English or Bulgarian, in library order; all of them
/// for a blank query. Plurals and accents don't matter, a word may be half
/// typed ("chick"), and a few everyday words stand for others ("fish" finds
/// salmon, cod and tuna).
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
  final bg = recipe.bg;
  final about = [
    recipe.name,
    recipe.cuisine,
    recipe.category.label,
    for (final tag in recipe.tags) tag.json,
    if (bg != null) ...[
      bg.name,
      bg.cuisine,
      recipe.category.shownLabel(_bulgarian),
      for (final tag in recipe.tags) ?_bulgarianTags[tag],
    ],
  ].join(' ');
  final words = {
    for (final word in _words(about)) ...{word, _stem(word)},
  };
  for (final ingredient in [
    for (final ingredient in recipe.ingredients) ingredient.item,
    for (final ingredient in bg?.ingredients ?? const []) ingredient.item,
  ]) {
    final item = _words(ingredient);
    for (final (i, word) in item.indexed) {
      final next = i + 1 < item.length ? _stem(item[i + 1]) : null;
      // Egg noodles hold no eggs and Greek yoghurt makes no dish Greek,
      // unless the search names the noodles or the yoghurt too.
      if (next != null &&
          _describes[word] == next &&
          !wanted.any(next.startsWith)) {
        continue;
      }
      // Nor is кисело мляко (yoghurt) milk, unless the search says кисело.
      final before = i > 0 ? _stem(item[i - 1]) : null;
      if (before != null &&
          _describedBy[word] == before &&
          !wanted.any(before.startsWith)) {
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
  // Bulgarian: и, с, в, на, за, от, или, по.
  'и',
  'с',
  'със',
  'в',
  'във',
  'на',
  'за',
  'от',
  'или',
  'по',
};

/// Ingredient words that only describe the next word.
const _describes = {
  'egg': 'noodle',
  'greek': 'yoghurt',
  'chicken': 'stock',
  'beef': 'stock',
  'vegetable': 'stock',
  'пилешки': 'бульон',
  'телешки': 'бульон',
};

/// Ingredient words that mean something else after the word before.
const _describedBy = {'мляко': 'кисел'};

/// The meals' names in Bulgarian, for search.
final _bulgarian = lookupAppLocalizations(const Locale('bg'));

/// The labels in Bulgarian, for search.
const _bulgarianTags = {
  RecipeTag.highProtein: 'протеиново',
  RecipeTag.vegetarian: 'вегетарианско',
  RecipeTag.vegan: 'веганско',
  RecipeTag.quick: 'бързо',
  RecipeTag.lowCalorie: 'нискокалорично',
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
  // Bulgarian, by stem: риба, паста, сирене, фета, морски, йогурт.
  'риб': ['сьомг', 'треск'],
  'паст': ['спагет', 'талиател'],
  'сирен': ['фета', 'пармезан', 'чедър'],
  'фет': ['сирен'],
  'морск': ['скарид'],
  'йогурт': ['кисел'],
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

final _bulgarianEnding = RegExp(r'(?:ите|ове|еве|[аеиоуъюя])$');

/// Plural to singular, roughly: berries → berry, tomatoes → tomato,
/// eggs → egg. Bulgarian loses its last vowel or plural ending: домати →
/// домат, яйца and яйце → яйц. Applied to both sides, so a rough guess
/// still matches.
String _stem(String word) {
  final ending = _bulgarianEnding.firstMatch(word);
  if (ending != null) {
    return ending.start >= 3 ? word.substring(0, ending.start) : word;
  }
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

final _portionsSuffix = RegExp(r'\s×\s[\d.,]+$');

/// Recipes logged in the last 14 days, newest first, found by the meal's
/// name in either language: a logged "Pasta bolognese × 1.5" or "Паста
/// болонезе × 1,5" counts as Pasta bolognese.
List<Recipe> recentlyCookedRecipes(
  List<Recipe> recipes,
  List<Meal> meals,
  DateTime now,
) {
  final since = now.subtract(const Duration(days: 14));
  final found = <Recipe>[];
  final sorted = [...meals]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  for (final meal in sorted) {
    if (meal.timestamp.isBefore(since)) continue;
    final name = meal.name?.replaceFirst(_portionsSuffix, '').trim();
    final recipe = name == null
        ? null
        : recipes.where((r) => r.isNamed(name)).firstOrNull;
    if (recipe != null && !found.contains(recipe)) found.add(recipe);
  }
  return found;
}
