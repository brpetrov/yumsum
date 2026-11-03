import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/review/day_meals_sheet.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:intl/intl.dart';

/// A macros line as the app shows it, each figure held together.
String _line(String text) => text.replaceAllMapped(
  RegExp(r'(\w+) ([\d.]+) g'),
  (m) => '${m[1]}\u00A0${m[2]}\u00A0g',
);

void main() {
  group('isPastDay', () {
    final now = DateTime(2026, 10, 15, 9, 30);

    test('earlier days are past days', () {
      expect(isPastDay('2026-10-14', now), isTrue);
      expect(isPastDay('2026-09-30', now), isTrue);
    });

    test('today is not a past day', () {
      expect(isPastDay('2026-10-15', now), isFalse);
    });
  });

  group('hasSettledStatus', () {
    DailySummary summaryOn(DateTime day, int calories) => DailySummary(
      date: DateFormat('yyyy-MM-dd').format(day),
      totalCalories: calories,
      targetCalories: 2000,
      calorieDelta: calories - 2000,
      mealCount: 1,
      status: calories >= 1800 && calories <= 2200
          ? DailyStatus.green
          : DailyStatus.red,
      updatedAt: day,
    );
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    test('today under target is not judged yet', () {
      expect(hasSettledStatus(summaryOn(today, 900)), isFalse);
    });

    test('today on track or over target is shown', () {
      expect(hasSettledStatus(summaryOn(today, 2000)), isTrue);
      expect(hasSettledStatus(summaryOn(today, 2900)), isTrue);
    });

    test('earlier days always show their status', () {
      expect(hasSettledStatus(summaryOn(yesterday, 900)), isTrue);
    });

    test('a day off never shows one', () {
      final off = summaryOn(yesterday, 3200);
      expect(
        hasSettledStatus(
          DailySummary(
            date: off.date,
            totalCalories: off.totalCalories,
            targetCalories: off.targetCalories,
            calorieDelta: off.calorieDelta,
            mealCount: off.mealCount,
            status: off.status,
            dayOff: true,
            updatedAt: off.updatedAt,
          ),
        ),
        isFalse,
      );
    });
  });

  group('DayMealsSheet', () {
    final day = DateTime(2020, 3, 10);
    final meal = Meal(
      id: 'm1',
      date: '2020-03-10',
      timestamp: DateTime(2020, 3, 10, 19, 5),
      name: 'Musaka',
      calories: 640,
      proteinGrams: 31,
      macros: const Nutrients(
        fat: 34,
        saturates: 14,
        carbs: 42,
        sugars: 9,
        fibre: 5,
        salt: 2.3,
      ),
      createdAt: DateTime(2020, 3, 10, 19, 5),
      updatedAt: DateTime(2020, 3, 10, 19, 5),
    );
    final summary = DailySummary(
      date: '2020-03-10',
      totalCalories: 640,
      targetCalories: 1900,
      calorieDelta: -1260,
      mealCount: 1,
      status: DailyStatus.red,
      updatedAt: DateTime(2020, 3, 10),
    );

    Future<void> pumpSheet(
      WidgetTester tester, {
      int changesUsed = 0,
      bool plus = false,
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            plusProvider.overrideWithValue(plus),
            mealsForDateProvider.overrideWith(
              (ref, date) => Stream.value([meal]),
            ),
            dailySummaryForDateProvider.overrideWith(
              (ref, date) => Stream.value(summary),
            ),
            dayEditsThisMonthProvider.overrideWith(
              (ref) => Stream.value(changesUsed),
            ),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DayMealsSheet(date: day)),
          ),
        ),
      );
    }

    testWidgets('lists the day and how many past-day changes are left', (
      tester,
    ) async {
      await pumpSheet(tester, changesUsed: 3);
      await tester.pump();

      expect(find.text('Tuesday, 10 March'), findsOneWidget);
      expect(find.text('640 of 1900 kcal · 31 g protein'), findsOneWidget);
      expect(find.text('Musaka'), findsOneWidget);
      expect(
        find.text('7 of 10 past-day changes left this month'),
        findsOneWidget,
      );
      final addMeal = tester.widget<ButtonStyleButton>(
        find.widgetWithText(ElevatedButton, 'Add meal'),
      );
      expect(addMeal.onPressed, isNotNull);
    });

    testWidgets('adding is switched off once the month is used up', (
      tester,
    ) async {
      await pumpSheet(tester, changesUsed: 10);
      await tester.pump();

      expect(
        find.text('0 of 10 past-day changes left this month'),
        findsOneWidget,
      );
      final addMeal = tester.widget<ButtonStyleButton>(
        find.widgetWithText(ElevatedButton, 'Add meal'),
      );
      expect(addMeal.onPressed, isNull);
    });

    final closedLine = _line('Fat 34 g · carbs 42 g · salt 2.3 g');
    final rowLine = _line(
      'Fat 34 g · saturates 14 g · carbs 42 g · sugars 9 g · fibre 5 g · '
      'protein 31 g · salt 2.3 g',
    );

    testWidgets('YumSum Star sees the day\'s macros and each meal\'s on a '
        'tap', (tester) async {
      await pumpSheet(tester, plus: true);
      await tester.pump();

      expect(find.text(closedLine), findsOneWidget);
      expect(find.text(rowLine), findsNothing);
      await tester.tap(find.text('Musaka'));
      await tester.pump();
      expect(find.text(rowLine), findsOneWidget);
    });

    testWidgets('a free account sees no macros', (tester) async {
      await pumpSheet(tester);
      await tester.pump();

      expect(find.text(closedLine), findsNothing);
      await tester.tap(find.text('Musaka'));
      await tester.pump();
      expect(find.text(rowLine), findsNothing);
    });
  });
}
