import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/recipe_provider.dart';

Map<String, dynamic> _json({Map<String, dynamic> change = const {}}) => {
  'id': 'pasta-bolognese',
  'name': 'Pasta bolognese',
  'description': 'A lean beef ragù.',
  'cuisine': 'Italian',
  'category': 'dinner',
  'tags': ['high-protein', 'quick'],
  'servings': 4,
  'minutes': 40,
  'prepMinutes': 10,
  'kcalPerPortion': 560,
  'proteinPerPortion': 42,
  'fatPerPortion': 14.5,
  'saturatesPerPortion': 5.2,
  'carbsPerPortion': 66,
  'sugarsPerPortion': 9.8,
  'fibrePerPortion': 5,
  'saltPerPortion': 1.4,
  'ingredients': [
    {
      'item': 'Beef mince',
      'amount': '500 g',
      'kcal': 625,
      'protein': 105,
      'fat': 25,
      'saturates': 11,
      'carbs': 0,
      'sugars': 0,
      'fibre': 0,
      'salt': 1,
    },
    {'item': 'Salt', 'amount': 'to taste'},
  ],
  'steps': ['Brown the mince.', 'Simmer.'],
  ...change,
};

Recipe _recipe(String name, {int kcal = 500}) => Recipe.fromJson(
  _json(
    change: {
      'id': name.toLowerCase().replaceAll(' ', '-'),
      'name': name,
      'kcalPerPortion': kcal,
    },
  ),
);

Meal _meal(String name, DateTime at) => Meal(
  id: '$name $at',
  date: '2026-10-31',
  timestamp: at,
  name: name,
  calories: 500,
  createdAt: at,
  updatedAt: at,
);

void main() {
  group('Recipe.fromJson', () {
    test('reads every field', () {
      final recipe = Recipe.fromJson(_json());
      expect(recipe.category, RecipeCategory.dinner);
      expect(recipe.tags, [RecipeTag.highProtein, RecipeTag.quick]);
      final mince = recipe.ingredients.first;
      expect(
        (mince.item, mince.amount, mince.kcal, mince.protein),
        ('Beef mince', '500 g', 625, 105),
      );
      expect(mince.macros?.fat, 25);
      expect(mince.macros?.salt, 1);
      expect(recipe.ingredients.last.kcal, isNull);
      expect(recipe.ingredients.last.macros, isNull);
      final macros = recipe.macrosPerPortion;
      expect(
        [
          macros.fat,
          macros.saturates,
          macros.carbs,
          macros.sugars,
          macros.fibre,
          macros.salt,
        ],
        [14.5, 5.2, 66, 9.8, 5, 1.4],
      );
      expect(recipe.steps, hasLength(2));
      expect(recipe.cookMinutes, 30);
      expect(
        recipe.photoUrl,
        'https://yumsum.web.app/recipes/pasta-bolognese.webp',
      );
    });

    test('a description is optional', () {
      final recipe = Recipe.fromJson(_json()..remove('description'));
      expect(recipe.description, isNull);
    });

    test('anything wrong names the recipe and the field', () {
      final bad = <String, Object?>{
        'id': 'Pasta Bolognese',
        'name': '',
        'cuisine': null,
        'category': 'supper',
        'tags': ['spicy'],
        'servings': 0,
        'minutes': 700,
        // More prep than the whole recipe takes.
        'prepMinutes': 41,
        'kcalPerPortion': 20,
        'proteinPerPortion': 200,
        'fatPerPortion': 151,
        // More than the fat, and more than the carbs.
        'saturatesPerPortion': 15,
        'carbsPerPortion': -1,
        'sugarsPerPortion': 70,
        'fibrePerPortion': 81,
        'saltPerPortion': '1.4',
        'ingredients': <Object>[],
        'steps': [''],
      };
      for (final MapEntry(:key, :value) in bad.entries) {
        expect(
          () => Recipe.fromJson(_json(change: {key: value})),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains(key == 'id' ? 'id' : 'pasta-bolognese: $key'),
            ),
          ),
          reason: key,
        );
      }
      expect(
        () => Recipe.fromJson(
          _json(
            change: {
              'tags': ['quick', 'quick'],
            },
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => Recipe.fromJson(_json()..remove('saltPerPortion')),
        throwsFormatException,
      );
      expect(
        () => Recipe.fromJson(
          _json(
            change: {
              'ingredients': [
                {'item': 'Oil', 'amount': '1 tbsp', 'fat': -1},
              ],
            },
          ),
        ),
        throwsFormatException,
      );
    });

    test('portions scale and name the meal', () {
      final recipe = Recipe.fromJson(_json());
      expect(recipe.kcalFor(1.5), 840);
      expect(recipe.proteinFor(0.5), 21);
      expect(recipe.macrosFor(1.5).fat, 21.75);
      expect(recipe.macrosFor(1.5).salt, closeTo(2.1, 1e-9));
      expect(recipe.mealName(1), 'Pasta bolognese');
      expect(recipe.mealName(2), 'Pasta bolognese × 2');
      expect(recipe.mealName(1.5), 'Pasta bolognese × 1.5');
    });
  });

  test('a portion fits only once something is logged and it is under '
      'what is left', () {
    final recipe = _recipe('Soup', kcal: 400);
    expect(fitsRemaining(recipe, null), isFalse);
    expect(fitsRemaining(recipe, 0), isFalse);
    expect(fitsRemaining(recipe, 400), isTrue);
    expect(fitsRemaining(recipe, 399), isFalse);
  });

  test('recipes match by name, any case', () {
    final recipes = [_recipe('Pasta bolognese'), _recipe('Chicken soup')];
    expect(matchingRecipes(recipes, 'PASTA').map((r) => r.name), [
      'Pasta bolognese',
    ]);
    expect(matchingRecipes(recipes, '  '), isEmpty);
  });

  test('search wants every word in the name, meal, cuisine, labels or '
      'ingredients, forgiving plurals, accents and half-typed words', () {
    Recipe dish(
      String name,
      List<String> items, {
      String category = 'dinner',
      String cuisine = 'Italian',
      List<String> tags = const [],
    }) => Recipe.fromJson(
      _json(
        change: {
          'id': name.toLowerCase().replaceAll(RegExp('[^a-z]+'), '-'),
          'name': name,
          'category': category,
          'cuisine': cuisine,
          'tags': tags,
          'ingredients': [
            for (final item in items) {'item': item, 'amount': '1'},
          ],
        },
      ),
    );
    final recipes = [
      dish(
        'Tomato and feta omelette',
        ['Eggs', 'Cherry tomatoes', 'Feta'],
        category: 'breakfast',
        tags: ['quick', 'vegetarian'],
      ),
      dish(
        'Tuna niçoise salad',
        ['New potatoes', 'Eggs', 'Tuna in spring water'],
        category: 'lunch',
        cuisine: 'French',
      ),
      dish('Garlic prawn spaghetti', ['Spaghetti, dried', 'Raw king prawns']),
      dish('Chicken stir-fry', ['Chicken breast', 'Egg noodles, dried']),
      dish(
        'Greek yoghurt berry bowl',
        ['Greek yoghurt', 'Mixed berries'],
        category: 'breakfast',
        cuisine: 'Greek',
        tags: ['vegetarian'],
      ),
    ];
    List<String> search(String query) => [
      for (final recipe in searchRecipes(recipes, query)) recipe.name,
    ];

    expect(search('  '), hasLength(5));
    expect(search('EGGS'), ['Tomato and feta omelette', 'Tuna niçoise salad']);
    expect(search('egg'), search('eggs'));
    expect(search('egg noodles'), ['Chicken stir-fry']);
    expect(search('potato'), ['Tuna niçoise salad']);
    expect(search('nicoise'), ['Tuna niçoise salad']);
    expect(search('french'), ['Tuna niçoise salad']);
    expect(search('berries'), ['Greek yoghurt berry bowl']);
    expect(search('berri'), ['Greek yoghurt berry bowl']);
    expect(search('quick veggie breakfast'), ['Tomato and feta omelette']);
    expect(search('fish'), ['Tuna niçoise salad']);
    expect(search('pasta with prawns'), ['Garlic prawn spaghetti']);
    expect(search('yogurt'), ['Greek yoghurt berry bowl']);
    expect(search('to'), ['Tomato and feta omelette']);
    expect(search('omelette lunch'), isEmpty);
  });

  test('recently cooked recipes come from the last two weeks of meals, '
      'portions and all', () {
    final now = DateTime(2026, 10, 31, 12);
    final recipes = [
      _recipe('Pasta bolognese'),
      _recipe('Chicken soup'),
      _recipe('Omelette'),
    ];
    final meals = [
      _meal('Chicken soup', now.subtract(const Duration(days: 3))),
      _meal('Pasta bolognese × 1.5', now.subtract(const Duration(hours: 5))),
      _meal('pasta bolognese', now.subtract(const Duration(days: 1))),
      _meal('Omelette', now.subtract(const Duration(days: 20))),
      _meal('Toast', now),
    ];
    expect(recentlyCookedRecipes(recipes, meals, now).map((r) => r.name), [
      'Pasta bolognese',
      'Chicken soup',
    ]);
  });
}
