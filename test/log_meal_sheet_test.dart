import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

typedef _Saved = ({
  String? date,
  String? name,
  double calories,
  Meal? edited,
  Nutrients? macros,
});

class _FakeEstimates extends Fake implements CalorieEstimateService {
  @override
  Future<CalorieEstimate> estimate(String uid, String description) async => (
    kcal: 500,
    protein: 30,
    macros: const Nutrients(fat: 20, carbs: 40, salt: 2),
    items: const <EstimateItem>[],
  );
}

class _FakeLogMealController extends LogMealController {
  final saved = <_Saved>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
    Nutrients? macros,
  }) async {
    // What the real controller keeps for an edit given no macros.
    saved.add((
      date: date,
      name: name,
      calories: calories,
      edited: existingMeal,
      macros:
          macros ??
          (existingMeal == null
              ? null
              : macrosAfterEdit(existingMeal, name?.trim(), calories)),
    ));
  }
}

void main() {
  late _FakeLogMealController controller;

  Future<void> openSheet(
    WidgetTester tester, {
    String? date,
    Meal? existingMeal,
  }) async {
    controller = _FakeLogMealController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logMealControllerProvider.overrideWith(() => controller),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          currentUidProvider.overrideWithValue('user-1'),
          calorieEstimateServiceProvider.overrideWithValue(_FakeEstimates()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showLogMealSheet(
                  context,
                  date: date,
                  existingMeal: existingMeal,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('adds a meal to the day it was opened for', (tester) async {
    await openSheet(tester, date: '2026-10-10');

    expect(find.text('Saturday, 10 October'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Meal'), 'Musaka');
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '640');
    await tester.tap(find.text('Save meal'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.saved.single.date, '2026-10-10');
    expect(controller.saved.single.name, 'Musaka');
    expect(controller.saved.single.calories, 640);
  });

  testWidgets('editing pre-fills the meal and saves it in place', (
    tester,
  ) async {
    final meal = Meal(
      id: 'm1',
      date: '2026-10-12',
      timestamp: DateTime(2026, 10, 12, 19),
      name: 'Banitsa',
      calories: 380,
      proteinGrams: 14,
      createdAt: DateTime(2026, 10, 12, 19),
      updatedAt: DateTime(2026, 10, 12, 19),
    );
    await openSheet(tester, existingMeal: meal);

    expect(find.text('Edit meal'), findsOneWidget);
    expect(find.text('Banitsa'), findsOneWidget);
    expect(find.text('380'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);

    await tester.tap(find.text('Save changes'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.saved.single.edited, same(meal));
    expect(controller.saved.single.date, '2026-10-12');
  });

  testWidgets('saves the estimate\'s macros, scaled to edited calories', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Meal'), 'Musaka');
    await tester.pump();
    await tester.tap(find.text('Estimate from name'));
    await tester.pumpAndSettle();
    expect(find.text('500'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '600');
    await tester.tap(find.text('Save meal'));
    await tester.pump(const Duration(milliseconds: 500));

    final macros = controller.saved.single.macros!;
    expect(macros.fat, closeTo(24, 1e-9));
    expect(macros.salt, closeTo(2.4, 1e-9));
  });

  final banitsa = Meal(
    id: 'm1',
    date: '2026-10-12',
    timestamp: DateTime(2026, 10, 12, 19),
    name: 'Banitsa',
    calories: 380,
    proteinGrams: 14,
    macros: const Nutrients(fat: 19, salt: 1.5),
    createdAt: DateTime(2026, 10, 12, 19),
    updatedAt: DateTime(2026, 10, 12, 19),
  );

  testWidgets('an edit keeps the meal\'s macros, scaled to its calories', (
    tester,
  ) async {
    await openSheet(tester, existingMeal: banitsa);
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '760');
    await tester.tap(find.text('Save changes'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.saved.single.macros?.fat, 38);
    expect(controller.saved.single.macros?.salt, 3);
  });

  testWidgets('a renamed meal drops its macros', (tester) async {
    await openSheet(tester, existingMeal: banitsa);
    await tester.enterText(find.widgetWithText(TextField, 'Meal'), 'Musaka');
    await tester.tap(find.text('Save changes'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.saved.single.macros, isNull);
  });

  testWidgets('asks for calories before saving', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Save meal'));
    await tester.pump();

    expect(find.text('Enter the calories, or estimate them.'), findsOneWidget);
    expect(controller.saved, isEmpty);
  });
}
