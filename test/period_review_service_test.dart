import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/period_review.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/services/period_review_service.dart';

void main() {
  group('PeriodReviewService', () {
    test('a day off counts in the totals but is not judged', () {
      final review = PeriodReviewService().buildReview(
        startDate: DateTime(2026, 4, 6),
        endDate: DateTime(2026, 4, 12),
        summaries: [
          _summary('2026-04-06', calories: 1900),
          _summary(
            '2026-04-07',
            calories: 3400,
            status: DailyStatus.red,
            dayOff: true,
          ),
        ],
      );

      expect(review.loggedDays, 2);
      expect(review.totalCalories, 5300);
      expect(review.redDays, 0);
      expect(review.daysOff, 1);
      expect(review.calorieConsistencyRate, 1.0);
      expect(review.worstDay?.date, '2026-04-06');
    });

    test('averages calories across logged days, not every calendar day', () {
      final review = PeriodReviewService().buildReview(
        startDate: DateTime(2026, 4, 6),
        endDate: DateTime(2026, 4, 12),
        summaries: [
          _summary('2026-04-06', calories: 2000),
          _summary('2026-04-07', calories: 1900),
          _summary('2026-04-08', calories: 1800),
          _summary('2026-04-09', calories: 2000),
        ],
      );

      expect(review.daysInPeriod, 7);
      expect(review.loggedDays, 4);
      expect(review.totalCalories, 7700);
      expect(review.averageCaloriesPerDay, 1925);
    });

    test('ignores legacy empty daily summaries in activity metrics', () {
      final review = PeriodReviewService().buildReview(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30),
        summaries: [
          _summary(
            '2026-04-01',
            calories: 0,
            mealCount: 0,
            status: DailyStatus.red,
          ),
          _summary('2026-04-02', calories: 2000),
          _summary('2026-04-03', calories: 1800),
        ],
      );

      expect(review.daysInPeriod, 30);
      expect(review.loggedDays, 2);
      expect(review.summaries.map((summary) => summary.date), [
        '2026-04-02',
        '2026-04-03',
      ]);
      expect(review.totalCalories, 3800);
      expect(review.averageCaloriesPerDay, 1900);
    });

    group('inconsistent-logging note', () {
      const note =
          'Some days weren\'t logged. Log more days for a clearer review.';

      test('is fair to a week that is only part way through', () {
        final review = PeriodReviewService().buildReview(
          startDate: DateTime(2026, 4, 6),
          endDate: DateTime(2026, 4, 8),
          summaries: [
            _summary('2026-04-06', calories: 1900),
            _summary('2026-04-08', calories: 2000),
          ],
        );

        expect(review.guidance, isNot(contains(note)));
      });

      test('still appears when most of a full week is missing', () {
        final review = PeriodReviewService().buildReview(
          startDate: DateTime(2026, 4, 6),
          endDate: DateTime(2026, 4, 12),
          summaries: [
            _summary('2026-04-06', calories: 1900),
            _summary('2026-04-08', calories: 2000),
            _summary('2026-04-10', calories: 1950),
          ],
        );

        expect(review.guidance, contains(note));
      });
    });

    group('over-target note', () {
      const over =
          'You averaged 140 kcal a day over your target, so your goal '
          'date moves a little later.';

      /// [count] days from 2 November at [calories] against 1660.
      List<DailySummary> days(int count, int calories) => [
        for (var day = 2; day < 2 + count; day++)
          _summary(
            '2026-11-${day.toString().padLeft(2, '0')}',
            calories: calories,
            targetCalories: 1660,
          ),
      ];

      PeriodReview review(
        List<DailySummary> summaries, {
        bool month = true,
        WeightLossPace goal = WeightLossPace.moderate,
      }) => PeriodReviewService().buildReview(
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
        summaries: summaries,
        month: month,
        goal: goal,
      );

      const under =
          'You averaged 140 kcal a day under your target, so your goal '
          'date moves a little later.';

      test('a month over by more than 100 a day says the date moves', () {
        expect(review(days(10, 1800)).guidance, contains(over));
      });

      test('keeping weight, it leaves the goal date out', () {
        expect(
          review(days(10, 1800), goal: WeightLossPace.maintain).guidance,
          contains('You averaged 140 kcal a day over your target.'),
        );
      });

      test('gaining, over target has no date, under moves it later', () {
        const gain = WeightLossPace.gain;
        expect(
          review(days(10, 1800), goal: gain).guidance,
          contains('You averaged 140 kcal a day over your target.'),
        );
        expect(review(days(10, 1520), goal: gain).guidance, contains(under));
      });

      test('under target is left alone when losing or keeping', () {
        for (final goal in [WeightLossPace.moderate, WeightLossPace.maintain]) {
          expect(
            review(days(10, 1520), goal: goal).guidance,
            isNot(contains(under)),
          );
        }
      });

      test('gaining, not at 100 under, in a week, or before 7 days', () {
        const gain = WeightLossPace.gain;
        bool noted(PeriodReview review) =>
            review.guidance.any((note) => note.startsWith('You averaged'));
        expect(noted(review(days(10, 1560), goal: gain)), isFalse);
        expect(noted(review(days(7, 1500), month: false, goal: gain)), isFalse);
        expect(noted(review(days(6, 1500), goal: gain)), isFalse);
      });

      test('not at 100 over, in a week, or before 7 judged days', () {
        bool noted(PeriodReview review) =>
            review.guidance.any((note) => note.startsWith('You averaged'));
        expect(noted(review(days(10, 1760))), isFalse);
        expect(noted(review(days(7, 1960), month: false)), isFalse);
        expect(noted(review(days(6, 1960))), isFalse);
      });

      test('days off are left out, and each day has its own target', () {
        final summaries = [
          ...days(7, 1700),
          _summary(
            '2026-11-20',
            calories: 3500,
            targetCalories: 1660,
            dayOff: true,
          ),
          // 100 over a higher target from an earlier plan; against today's
          // 1660 it would tip the month over.
          _summary('2026-11-21', calories: 2200, targetCalories: 2100),
        ];
        expect(
          review(summaries).guidance.any((n) => n.startsWith('You averaged')),
          isFalse,
        );
      });
    });
  });
}

DailySummary _summary(
  String date, {
  required int calories,
  int targetCalories = 1900,
  int mealCount = 3,
  DailyStatus? status,
  bool dayOff = false,
}) {
  return DailySummary(
    date: date,
    totalCalories: calories,
    targetCalories: targetCalories,
    calorieDelta: calories - targetCalories,
    mealCount: mealCount,
    status: status ?? DailyStatus.green,
    dayOff: dayOff,
    updatedAt: DateTime(2026, 4, 20),
  );
}
