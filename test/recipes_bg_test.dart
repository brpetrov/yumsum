import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/auth_provider.dart';
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

/// The real recipe library in Bulgarian on a 360-wide phone: the list,
/// search in both languages, what was cooked lately whatever the language
/// it was logged in, a recipe page, and the name a portion is logged under.
/// Nothing may overflow (an overflow is reported as an exception).

class _FakeLogMealController extends LogMealController {
  final saved = <String?>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
    Nutrients? macros,
  }) async {
    await future;
    saved.add(name);
  }
}

Meal _meal(String name) {
  final at = DateTime.now().subtract(const Duration(days: 1));
  return Meal(
    id: name,
    date: '${at.year}-${at.month}-${at.day}',
    timestamp: at,
    name: name,
    calories: 500,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  late List<Recipe> library;
  late _FakeLogMealController controller;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    library = parseRecipes(
      await rootBundle.loadString('assets/recipes/recipes.json'),
    );
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<Meal> recent = const [],
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    controller = _FakeLogMealController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipesProvider.overrideWith((ref) async => library),
          recipeImageProvider.overrideWithValue(pixelImage),
          recentMealsProvider.overrideWith((ref) => Stream.value(recent)),
          currentUidProvider.overrideWithValue('user-1'),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          plusProvider.overrideWithValue(false),
          logMealControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('bg'),
          home: home,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the library, cooked recently and search', (tester) async {
    // Logged in English, before the switch.
    await pump(
      tester,
      const RecipesScreen(),
      recent: [_meal('Chicken curry with rice × 1.5')],
    );

    expect(find.text('Готвени наскоро'), findsOneWidget);
    expect(
      find.widgetWithText(ActionChip, 'Пилешко къри с ориз'),
      findsOneWidget,
    );
    expect(find.text('Цедено кисело мляко с горски плодове'), findsOneWidget);
    expect(find.text('Greek yoghurt berry bowl'), findsNothing);
    expect(tester.takeException(), isNull);

    Future<void> search(String query) async {
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
    }

    for (final query in ['пилешко къри', 'curry', 'КЪРИ С ОРИЗ']) {
      await search(query);
      expect(find.text('Пилешко къри с ориз'), findsOneWidget, reason: query);
      expect(find.text('Готвени наскоро'), findsNothing);
    }

    await search('бял боб');
    expect(find.text('Салата с риба тон и бял боб'), findsOneWidget);
    expect(find.text('Треска с чоризо и бял боб'), findsOneWidget);
    expect(find.text('Пилешко къри с ориз'), findsNothing);
    expect(tester.takeException(), isNull);

    await search('шопска');
    expect(find.text('Шопска салата с пиле'), findsOneWidget);
    expect(find.text('Обяд'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a recipe page, logged under its Bulgarian name', (tester) async {
    await pump(tester, const RecipeScreen(recipeId: 'beef-burgers-wedges'));

    expect(find.text('Телешки бургери с картофи по селски'), findsOneWidget);
    expect(
      find.text(
        'Американска кухня · Домашни бургери от постно телешко с картофи от '
        'фурната.',
      ),
      findsOneWidget,
    );
    // Amounts hold together: „1 с. л.“ never breaks after the number.
    expect(find.text('500 г'), findsOneWidget);
    expect(find.text('1 с. л.'), findsOneWidget);
    expect(find.text('Постна телешка кайма, 5% мазнини'), findsOneWidget);
    expect(find.text('Начин на приготвяне'), findsOneWidget);

    /// The bold parts of the step that starts with [start].
    List<String> boldIn(String start) {
      final step = tester.widget<RichText>(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText().startsWith(start),
        ),
      );
      final bold = <String>[];
      step.text.visitChildren((span) {
        if (span is TextSpan && span.style?.fontWeight == FontWeight.w800) {
          bold.add(span.text!);
        }
        return true;
      });
      return bold;
    }

    expect(boldIn('Загрей фурната'), ['220°C (200°C с вентилатор)']);
    expect(boldIn('В голяма тава'), ['30–35 минути']);
    expect(boldIn('Когато на картофите'), ['12 минути', '4–5 минути']);
    expect(boldIn('Разрежи питките'), ['1 минута']);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Запиши порция'));
    await tester.pumpAndSettle();
    expect(find.text('Телешки бургери с картофи по селски'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Повече'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Запиши'));
    await tester.pumpAndSettle();

    expect(controller.saved, ['Телешки бургери с картофи по селски × 1,5']);
    expect(
      find.text('Записахме „Телешки бургери с картофи по селски × 1,5“.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
