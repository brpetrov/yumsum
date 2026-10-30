import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/review/day_meals_sheet.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:intl/intl.dart';

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

    Future<void> pumpSheet(WidgetTester tester, {required int changesUsed}) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
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
  });
}
