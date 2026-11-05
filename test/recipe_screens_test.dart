import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/recipes/recipe_screen.dart';
import 'package:lean_streak/screens/recipes/recipes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recipe_fixtures.dart';

/// A macros line as the app shows it, each figure held together.
String _line(String text) => text.replaceAllMapped(
  RegExp(r'(\w+) ([\d.]+) g'),
  (m) => '${m[1]}\u00A0${m[2]}\u00A0g',
);

class _FakeLogMealController extends LogMealController {
  _FakeLogMealController({this.fails = false});

  final bool fails;
  final saved = <({String? name, double calories, double? protein})>[];
  final savedMacros = <Nutrients?>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
    Nutrients? macros,
  }) async {
    // Let build() finish first, or it would wipe the error below.
    await future;
    if (fails) {
      state = AsyncError(Exception('offline'), StackTrace.current);
      return;
    }
    saved.add((name: name, calories: calories, protein: proteinGrams));
    savedMacros.add(macros);
  }
}

final _bolognese = testRecipe('Pasta bolognese', kcal: 560, protein: 42);
final _oats = testRecipe(
  'Overnight oats',
  category: RecipeCategory.breakfast,
  kcal: 350,
  protein: 20,
);
final _soup = testRecipe('Lentil soup', category: RecipeCategory.lunch);

final _noProteinProfile = UserProfile(
  uid: 'user-1',
  email: 'a@b.com',
  name: 'Test',
  trackProtein: false,
  age: 30,
  gender: Gender.male,
  heightCm: 180,
  currentWeightKg: 86,
  targetWeightKg: 75,
  activityLevel: ActivityLevel.lightlyActive,
  trainingFrequency: TrainingFrequency.oneToTwo,
  activityScaleVersion: currentActivityScaleVersion,
  planCalculationVersion: currentPlanCalculationVersion,
  weightLossPace: WeightLossPace.moderate,
  targetDate: DateTime(2027),
  bmi: 26.5,
  bmr: 1800,
  tdee: 2400,
  dailyCalorieTarget: 1900,
  goalPaceKgPerWeek: 0.5,
  goalPaceLevel: GoalPaceLevel.values.first,
  onboardingCompleted: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

DailySummary _eaten(int kcal) => DailySummary(
  date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  totalCalories: kcal,
  targetCalories: 1900,
  calorieDelta: kcal - 1900,
  mealCount: 1,
  status: DailyStatus.green,
  updatedAt: DateTime.now(),
);

Meal _meal(String name) => Meal(
  id: name,
  date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  timestamp: DateTime.now().subtract(const Duration(days: 1)),
  name: name,
  calories: 500,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

void main() {
  late _FakeLogMealController controller;
  late GoRouter router;

  Future<void> pump(
    WidgetTester tester, {
    String at = AppRoutes.recipes,
    DailySummary? today,
    List<Meal> recent = const [],
    bool trackProtein = true,
    bool failing = false,
    bool plus = false,
  }) async {
    // Tall enough for every meal's section to be built.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    controller = _FakeLogMealController(fails: failing);
    router = GoRouter(
      initialLocation: at,
      routes: [
        GoRoute(
          path: AppRoutes.recipes,
          builder: (_, _) => const RecipesScreen(),
        ),
        GoRoute(
          path: AppRoutes.recipe,
          builder: (_, state) =>
              RecipeScreen(recipeId: state.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        // A fresh scope each time, so a second pump takes new figures.
        key: UniqueKey(),
        overrides: [
          recipesProvider.overrideWith(
            (ref) async => [_oats, _soup, _bolognese],
          ),
          recipeImageProvider.overrideWithValue(pixelImage),
          recentMealsProvider.overrideWith((ref) => Stream.value(recent)),
          dailySummaryForDateProvider.overrideWith(
            (ref, date) => Stream.value(today),
          ),
          currentUidProvider.overrideWithValue('user-1'),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(trackProtein ? null : _noProteinProfile),
          ),
          logMealControllerProvider.overrideWith(() => controller),
          sharedPreferencesProvider.overrideWithValue(prefs),
          plusProvider.overrideWithValue(plus),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    // The tiles appear once the library resolves; their photos then decode
    // outside the fake clock, and until they do their spinners keep
    // pumpAndSettle busy.
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

  group('Recipes page', () {
    testWidgets('shows a tile per recipe with its numbers under its meal, '
        'filtered by meal', (tester) async {
      await pump(tester);
      expect(find.text('Pasta bolognese'), findsOneWidget);
      expect(find.text('560 kcal · 42 g protein'), findsOneWidget);
      expect(find.text('Cooked recently'), findsNothing);
      // The chip and the heading; no snack recipes, so no Snack heading.
      expect(find.text('Lunch'), findsNWidgets(2));
      expect(find.text('Snack'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Breakfast'));
      await tester.pumpAndSettle();
      expect(find.text('Overnight oats'), findsOneWidget);
      expect(find.text('Pasta bolognese'), findsNothing);
      // The chip and the heading, which stays for the picked meal.
      expect(find.text('Breakfast'), findsNWidgets(2));
    });

    testWidgets('search filters the sections and says when nothing matches', (
      tester,
    ) async {
      await pump(tester, recent: [_meal('Pasta bolognese')]);
      await tester.enterText(find.byType(TextField), 'OATS');
      await tester.pumpAndSettle();
      expect(find.text('Overnight oats'), findsOneWidget);
      expect(find.text('Pasta bolognese'), findsNothing);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Cooked recently'), findsNothing);

      // Every fixture has beef mince; only one is a lunch.
      await tester.enterText(find.byType(TextField), 'mince lunch');
      await tester.pumpAndSettle();
      expect(find.text('Lentil soup'), findsOneWidget);
      expect(find.text('Overnight oats'), findsNothing);

      await tester.enterText(find.byType(TextField), 'tofu');
      await tester.pumpAndSettle();
      expect(
        find.text('No recipes match that. Try other words.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Pasta bolognese'), findsNWidgets(2));
      expect(find.text('Cooked recently'), findsOneWidget);
    });

    testWidgets('no protein on tiles when it is switched off', (tester) async {
      await pump(tester, trackProtein: false);
      expect(find.text('560 kcal'), findsOneWidget);
    });

    testWidgets('marks what fits only once something is logged', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Fits today'), findsNothing);

      // 1,500 of 1,900 eaten: 400 left, which only the oats (350) fit.
      await pump(tester, today: _eaten(1500));
      expect(find.text('Fits today'), findsOneWidget);
    });

    testWidgets('a tile opens its recipe', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Lentil soup'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/recipes/lentil-soup');
      expect(find.text('How to make it'), findsOneWidget);
    });

    testWidgets('a tile\'s + logs portions without opening it', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('Log a portion').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More'));
      await tester.pump();
      expect(find.text('525 kcal · 30 g protein'), findsOneWidget);
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();

      expect(controller.saved, [
        (name: 'Overnight oats × 1.5', calories: 525.0, protein: 30.0),
      ]);
      expect(find.text('Overnight oats × 1.5 logged.'), findsOneWidget);
      expect(router.state.uri.path, AppRoutes.recipes);
    });

    testWidgets('lists what was cooked recently, portions and all', (
      tester,
    ) async {
      await pump(
        tester,
        recent: [_meal('Pasta bolognese × 2'), _meal('Toast')],
      );
      expect(find.text('Cooked recently'), findsOneWidget);
      final chip = find.widgetWithText(ActionChip, 'Pasta bolognese');
      expect(chip, findsOneWidget);

      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();
      expect(controller.saved.single.name, 'Pasta bolognese');
    });
  });

  group('Recipe page', () {
    testWidgets('shows the recipe and logs a portion', (tester) async {
      await pump(tester, at: '/recipes/pasta-bolognese');
      expect(find.text('560 kcal · 42 g protein per portion'), findsOneWidget);
      // Prep, cooking and portions.
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);
      expect(find.text('Serves'), findsOneWidget);
      expect(find.text('Beef mince'), findsOneWidget);
      expect(find.text('Simmer and serve.'), findsOneWidget);
      // The step's time stands out.
      final step = tester.widget<Text>(
        find.text('Brown the mince for 5 minutes.'),
      );
      final time = (step.textSpan! as TextSpan).children!
          .cast<TextSpan>()
          .firstWhere((span) => span.text == '5 minutes');
      expect(time.style!.fontWeight, FontWeight.w800);

      await tester.tap(find.text('Log a portion'));
      await tester.pumpAndSettle();
      // Down to a half, and no further.
      await tester.tap(find.byTooltip('Less'));
      await tester.pump();
      await tester.tap(find.byTooltip('Less'));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('recipe-portions'))).data,
        '0.5',
      );
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();

      expect(controller.saved, [
        (name: 'Pasta bolognese × 0.5', calories: 280.0, protein: 21.0),
      ]);
      // Half the recipe's macros, so no AI is needed for them.
      expect(controller.savedMacros.single?.fat, 7);
      expect(controller.savedMacros.single?.salt, closeTo(0.7, 1e-9));
    });

    testWidgets('YumSum Star sees the macros per portion', (tester) async {
      final line = _line(
        'Fat 14 g · saturates 5 g · carbs 60 g · sugars 9 g · fibre 5 g · '
        'salt 1.4 g',
      );
      await pump(tester, at: '/recipes/pasta-bolognese');
      expect(find.text(line), findsNothing);

      await pump(tester, at: '/recipes/pasta-bolognese', plus: true);
      expect(find.text(line), findsOneWidget);
    });

    testWidgets('says so when logging fails', (tester) async {
      await pump(tester, at: '/recipes/pasta-bolognese', failing: true);
      await tester.tap(find.text('Log a portion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();
      expect(find.text('Could not log the meal. Try again.'), findsOneWidget);
    });

    testWidgets('no protein when it is switched off', (tester) async {
      await pump(tester, at: '/recipes/pasta-bolognese', trackProtein: false);
      expect(find.text('560 kcal per portion'), findsOneWidget);
      await tester.tap(find.text('Log a portion'));
      await tester.pumpAndSettle();
      expect(find.text('560 kcal'), findsOneWidget);
    });

    testWidgets('puts the ingredients beside the steps when there is room, '
        'and above them on a phone', (tester) async {
      await pump(tester, at: '/recipes/pasta-bolognese');
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('How to make it'), top('Ingredients'));

      tester.view.physicalSize = const Size(400, 2400);
      await tester.pumpAndSettle();
      expect(top('How to make it'), greaterThan(top('Ingredients')));
    });

    testWidgets('an unknown recipe says so', (tester) async {
      await pump(tester, at: '/recipes/nothing-here');
      expect(find.text('Could not load the recipe.'), findsOneWidget);
    });
  });
}
