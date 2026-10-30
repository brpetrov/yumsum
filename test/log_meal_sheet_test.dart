import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';

typedef _Saved = ({String? date, String? name, double calories, Meal? edited});

class _FakeLogMealController extends LogMealController {
  final saved = <_Saved>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
  }) async {
    saved.add((
      date: date,
      name: name,
      calories: calories,
      edited: existingMeal,
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

  testWidgets('asks for calories before saving', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Save meal'));
    await tester.pump();

    expect(find.text('Enter the calories, or estimate them.'), findsOneWidget);
    expect(controller.saved, isEmpty);
  });
}
