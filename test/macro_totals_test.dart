import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/widgets/macro_totals.dart';
import 'package:lean_streak/widgets/meal_row.dart';
import 'package:lean_streak/widgets/nutrition_icon.dart';

/// A macros line as the app shows it, each figure held together.
String _line(String text) => text.replaceAllMapped(
  RegExp(r'(\w+) ([\d.]+) g'),
  (m) => '${m[1]}\u00A0${m[2]}\u00A0g',
);

class _SavingController extends LogMealController {
  final saved = <(String?, String?, double, Nutrients?)>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
    Nutrients? macros,
  }) async => saved.add((date, name, calories, macros));
}

Meal _meal(String name, Nutrients? macros) => Meal(
  id: name,
  date: '2026-11-03',
  timestamp: DateTime(2026, 11, 3, 12),
  name: name,
  calories: 500,
  macros: macros,
  createdAt: DateTime(2026, 11, 3, 12),
  updatedAt: DateTime(2026, 11, 3, 12),
);

void main() {
  Future<void> pumpWidget(WidgetTester tester, Widget child) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (ref) => Stream<UserProfile?>.value(null),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: child),
          ),
        ),
      );

  Future<void> pump(WidgetTester tester, List<Meal> meals) =>
      pumpWidget(tester, MacroTotals(meals: meals));

  final wrap = _meal(
    'Chicken wrap',
    const Nutrients(
      fat: 18,
      saturates: 6,
      carbs: 52,
      sugars: 5,
      fibre: 4,
      salt: 2.1,
    ),
  );
  // A packet without fibre, as UK labels allow.
  final crisps = _meal(
    'Crisps',
    const Nutrients(
      fat: 8.4,
      saturates: 0.7,
      carbs: 15,
      sugars: 0.2,
      salt: 0.4,
    ),
  );

  test(
    'macrosLine gives whole grams, salt to one decimal, known ones only',
    () {
      expect(
        macrosLine(wrap.macros!),
        'Fat\u00A018\u00A0g · saturates\u00A06\u00A0g · '
        'carbs\u00A052\u00A0g · sugars\u00A05\u00A0g · '
        'fibre\u00A04\u00A0g · salt\u00A02.1\u00A0g',
      );
      expect(
        macrosLine(const Nutrients(carbs: 12.6, salt: 0.04)),
        _line('Carbs 13 g · salt 0.0 g'),
      );
    },
  );

  testWidgets('a closed line of fat, carbs and salt opens to all six', (
    tester,
  ) async {
    await pump(tester, [wrap, crisps, _meal('Toast', null)]);

    expect(
      find.text(_line('Fat 26 g · carbs 67 g · salt 2.5 g')),
      findsOneWidget,
    );
    expect(find.text('Saturates'), findsNothing);

    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.text('Saturates'), findsOneWidget);
    expect(find.text('26\u00A0g'), findsOneWidget);
    expect(find.text('7\u00A0g'), findsOneWidget);
    expect(find.text('67\u00A0g'), findsOneWidget);
    expect(find.text('5\u00A0g'), findsOneWidget);
    // The crisps don't say, so the fibre is a floor.
    expect(find.text('at least 4\u00A0g'), findsOneWidget);
    expect(find.text('2.5\u00A0g'), findsOneWidget);
    expect(find.text('1 meal not counted (no macro info)'), findsOneWidget);

    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.text('Saturates'), findsNothing);
  });

  testWidgets('the info button explains each macro and its target', (
    tester,
  ) async {
    await pump(tester, [wrap, crisps]);
    await tester.tap(find.byTooltip('About macros'));
    await tester.pumpAndSettle();
    expect(find.text('Your macros'), findsOneWidget);
    expect(find.text('AIM FOR'), findsOneWidget);
    expect(find.text('KEEP UNDER'), findsOneWidget);
    expect(find.text('Salt'), findsOneWidget);
    // The day sheet has no protein, so neither does its guide; no figures.
    expect(find.text('Protein'), findsNothing);
    expect(find.text('2.5 g'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Your macros'), findsNothing);
  });

  testWidgets('a meal with macros says so beside its time, and opens', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      Column(
        children: [
          MealRow(meal: wrap, onEdit: () {}, onDelete: () {}, showMacros: true),
          MealRow(
            meal: _meal('Toast', null),
            onEdit: () {},
            onDelete: () {},
            showMacros: true,
          ),
        ],
      ),
    );
    // Only the wrap has macros to show: an apple, named when held.
    expect(find.byType(NutritionIcon), findsOneWidget);
    expect(find.byTooltip('Nutrition'), findsOneWidget);
    await tester.tap(find.text('Chicken wrap'));
    await tester.pump();
    expect(find.text(macrosLine(wrap.macros!)), findsOneWidget);
  });

  testWidgets('Log again saves the meal on today with its figures, and '
      'says so', (tester) async {
    final controller = _SavingController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [logMealControllerProvider.overrideWith(() => controller)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => MealRow(
                meal: wrap,
                onEdit: () {},
                onDelete: () {},
                onLogAgain: () => logMealAgain(context, wrap),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Meal options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log again'));
    await tester.pumpAndSettle();
    expect(controller.saved, [(null, 'Chicken wrap', 500.0, wrap.macros)]);
    expect(find.text('Added to today.'), findsOneWidget);
  });

  testWidgets('the menu offers Log again where it is given', (tester) async {
    var again = 0;
    await pumpWidget(
      tester,
      MealRow(
        meal: wrap,
        onEdit: () {},
        onDelete: () {},
        onLogAgain: () => again++,
      ),
    );
    await tester.tap(find.byTooltip('Meal options'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Log again'));
    await tester.pumpAndSettle();
    expect(again, 1);

    await pumpWidget(
      tester,
      MealRow(
        key: const ValueKey('without'),
        meal: wrap,
        onEdit: () {},
        onDelete: () {},
      ),
    );
    await tester.tap(find.byTooltip('Meal options'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Log again'), findsNothing);
  });

  testWidgets('a meal\'s nutrition has its protein where a label has it, '
      'while protein is tracked', (tester) async {
    final withProtein = Meal(
      id: 'wrap',
      date: '2026-11-03',
      timestamp: DateTime(2026, 11, 3, 12),
      name: 'Chicken wrap',
      calories: 500,
      proteinGrams: 32.4,
      macros: wrap.macros,
      createdAt: DateTime(2026, 11, 3, 12),
      updatedAt: DateTime(2026, 11, 3, 12),
    );
    Future<void> open({required bool showProtein}) async {
      await pumpWidget(
        tester,
        MealRow(
          key: ValueKey(showProtein),
          meal: withProtein,
          onEdit: () {},
          onDelete: () {},
          showProtein: showProtein,
          showMacros: true,
        ),
      );
      await tester.tap(find.text('Chicken wrap'));
      await tester.pump();
    }

    await open(showProtein: true);
    expect(
      find.text(
        _line(
          'Fat 18 g · saturates 6 g · carbs 52 g · sugars 5 g · fibre 4 g · '
          'protein 32 g · salt 2.1 g',
        ),
      ),
      findsOneWidget,
    );

    await open(showProtein: false);
    expect(find.text(macrosLine(wrap.macros!)), findsOneWidget);
    expect(find.textContaining('protein'), findsNothing);
  });

  testWidgets('without YumSum Star a meal row has no macros hint', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      MealRow(meal: wrap, onEdit: () {}, onDelete: () {}),
    );
    expect(find.byType(NutritionIcon), findsNothing);
  });

  testWidgets('every meal counted needs no note', (tester) async {
    await pump(tester, [wrap]);
    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.textContaining('not counted'), findsNothing);
    expect(find.text('4\u00A0g'), findsOneWidget);
  });

  testWidgets('says so when no meal has macros, and doesn\'t open', (
    tester,
  ) async {
    await pump(tester, [_meal('Toast', null)]);
    expect(find.text('No macro info for today\'s meals'), findsOneWidget);
    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.text('Fat'), findsNothing);
  });

  testWidgets('nothing at all with nothing logged', (tester) async {
    await pump(tester, const []);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('a long meal name keeps clear of the calories', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpWidget(
      tester,
      MealRow(
        meal: _meal('2 slices whole wheat bread and butter', null),
        onEdit: () {},
        onDelete: () {},
      ),
    );
    final name = tester.getRect(
      find.text('2 slices whole wheat bread and butter'),
    );
    final kcal = tester.getRect(find.text('500 kcal'));
    expect(kcal.left - name.right, greaterThanOrEqualTo(12));
  });
}
