import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';

void main() {
  group('activity multipliers', () {
    test('uses daily movement plus structured training', () {
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.sedentary),
        1.25,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.lightlyActive),
        1.35,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.moderatelyActive),
        1.45,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.veryActive),
        1.60,
      );
      expect(
        HealthCalculator.activityMultiplier(
          ActivityLevel.sedentary,
          TrainingFrequency.threeToFour,
        ),
        1.35,
      );
      expect(
        HealthCalculator.activityMultiplier(
          ActivityLevel.veryActive,
          TrainingFrequency.fivePlus,
        ),
        1.75,
      );
    });
  });

  group('activity level parsing', () {
    test('maps legacy stored values to the new 4-level scale', () {
      expect(ActivityLevel.fromString('light'), ActivityLevel.sedentary);
      expect(ActivityLevel.fromString('medium'), ActivityLevel.lightlyActive);
      expect(ActivityLevel.fromString('hard'), ActivityLevel.moderatelyActive);
    });

    test('parses new stored values', () {
      expect(ActivityLevel.fromString('sedentary'), ActivityLevel.sedentary);
      expect(
        ActivityLevel.fromString('lightly_active'),
        ActivityLevel.lightlyActive,
      );
      expect(
        ActivityLevel.fromString('moderately_active'),
        ActivityLevel.moderatelyActive,
      );
      expect(ActivityLevel.fromString('very_active'), ActivityLevel.veryActive);
    });

    test('defaults old activity-only profiles to matching training levels', () {
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.sedentary),
        TrainingFrequency.none,
      );
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.lightlyActive),
        TrainingFrequency.oneToTwo,
      );
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.moderatelyActive),
        TrainingFrequency.threeToFour,
      );
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.veryActive),
        TrainingFrequency.fivePlus,
      );
    });
  });

  group('health plan calculation', () {
    test('activity changes maintenance and target when not clamped', () {
      final sedentary = HealthCalculator.calculatePlan(
        currentWeightKg: 100,
        targetWeightKg: 90,
        heightCm: 180,
        age: 30,
        gender: Gender.male,
        activityLevel: ActivityLevel.sedentary,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.slow,
        now: DateTime(2026, 4, 21),
      );
      final lightlyActive = HealthCalculator.calculatePlan(
        currentWeightKg: 100,
        targetWeightKg: 90,
        heightCm: 180,
        age: 30,
        gender: Gender.male,
        activityLevel: ActivityLevel.lightlyActive,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.slow,
        now: DateTime(2026, 4, 21),
      );

      expect(sedentary.bmr, closeTo(1980, 0.001));
      expect(sedentary.tdee, closeTo(2475, 0.001));
      expect(lightlyActive.tdee, closeTo(2673, 0.001));
      expect(sedentary.dailyCalorieTarget, closeTo(2200, 0.001));
      expect(lightlyActive.dailyCalorieTarget, closeTo(2398, 0.001));
      expect(sedentary.calorieTargetClamped, isFalse);
      expect(lightlyActive.calorieTargetClamped, isFalse);
    });

    test(
      'slow pace stays moderate for a sedentary lower-maintenance woman',
      () {
        final plan = HealthCalculator.calculatePlan(
          currentWeightKg: 72,
          targetWeightKg: 65,
          heightCm: 165,
          age: 27,
          gender: Gender.female,
          activityLevel: ActivityLevel.sedentary,
          trainingFrequency: TrainingFrequency.none,
          weightLossPace: WeightLossPace.slow,
          now: DateTime(2026, 4, 21),
        );

        expect(plan.bmr, closeTo(1455.25, 0.001));
        expect(plan.tdee, closeTo(1819.0625, 0.001));
        expect(plan.dailyCalorieTarget, closeTo(1544.0625, 0.001));
        expect(plan.goalPaceKgPerWeek, closeTo(0.25, 0.001));
        expect(plan.targetDate, DateTime(2026, 11, 3));
        expect(plan.calorieTargetClamped, isFalse);
        expect(plan.goalPaceLevel, GoalPaceLevel.safe);
      },
    );

    test('floor can keep target equal while activity still changes TDEE', () {
      final sedentary = HealthCalculator.calculatePlan(
        currentWeightKg: 60,
        targetWeightKg: 50,
        heightCm: 160,
        age: 30,
        gender: Gender.female,
        activityLevel: ActivityLevel.sedentary,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.fast,
        now: DateTime(2026, 4, 21),
      );
      final lightlyActive = HealthCalculator.calculatePlan(
        currentWeightKg: 60,
        targetWeightKg: 50,
        heightCm: 160,
        age: 30,
        gender: Gender.female,
        activityLevel: ActivityLevel.lightlyActive,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.fast,
        now: DateTime(2026, 4, 21),
      );

      expect(sedentary.tdee, isNot(lightlyActive.tdee));
      expect(sedentary.dailyCalorieTarget, 1200);
      expect(lightlyActive.dailyCalorieTarget, 1200);
      expect(sedentary.calorieTargetClamped, isTrue);
      expect(lightlyActive.calorieTargetClamped, isTrue);
      expect(sedentary.goalPaceLevel, GoalPaceLevel.warning);
      expect(lightlyActive.goalPaceLevel, GoalPaceLevel.warning);
      expect(sedentary.goalPaceKgPerWeek, closeTo(0.374, 0.001));
      expect(lightlyActive.goalPaceKgPerWeek, closeTo(0.491, 0.001));
    });

    test(
      'desk lifestyle with regular training does not use old moderate TDEE',
      () {
        final plan = HealthCalculator.calculatePlan(
          currentWeightKg: 80,
          targetWeightKg: 73,
          heightCm: 170,
          age: 29,
          gender: Gender.male,
          activityLevel: ActivityLevel.sedentary,
          trainingFrequency: TrainingFrequency.threeToFour,
          weightLossPace: WeightLossPace.fast,
          now: DateTime(2026, 4, 21),
        );

        expect(plan.bmr, closeTo(1722.5, 0.001));
        expect(plan.activityMultiplier, closeTo(1.35, 0.001));
        expect(plan.tdee, closeTo(2325.375, 0.001));
        expect(plan.dailyCalorieTarget, closeTo(1500.375, 0.001));
        expect(plan.calorieTargetClamped, isFalse);
      },
    );

    test(
      'maintain uses current weight, maintenance calories, and no deficit',
      () {
        final now = DateTime(2026, 4, 21);
        final plan = HealthCalculator.calculatePlan(
          currentWeightKg: 80,
          targetWeightKg: null,
          heightCm: 170,
          age: 30,
          gender: Gender.female,
          activityLevel: ActivityLevel.lightlyActive,
          trainingFrequency: TrainingFrequency.none,
          weightLossPace: WeightLossPace.maintain,
          now: now,
        );

        expect(plan.isMaintaining, isTrue);
        expect(plan.targetWeightKg, 80);
        expect(plan.goalPaceKgPerWeek, 0);
        expect(plan.targetDate, now);
        expect(plan.dailyCalorieTarget, plan.tdee);
        expect(plan.calorieTargetClamped, isFalse);
      },
    );

    test('maintain target date does not divide by zero', () {
      final now = DateTime(2026, 4, 21);

      expect(
        HealthCalculator.targetDateFromWeightLossPace(
          80,
          70,
          WeightLossPace.maintain,
          now: now,
        ),
        now,
      );
    });

    group('gain', () {
      final now = DateTime(2026, 4, 21);
      HealthPlanCalculation gain({
        double currentWeightKg = 55,
        double? targetWeightKg = 60,
        double adaptiveKcal = 0,
      }) => HealthCalculator.calculatePlan(
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        heightCm: 165,
        age: 27,
        gender: Gender.female,
        activityLevel: ActivityLevel.sedentary,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.gain,
        adaptiveKcal: adaptiveKcal,
        now: now,
      );

      test('adds 275 to maintenance and counts the kg to gain', () {
        final plan = gain();

        expect(plan.isGaining, isTrue);
        expect(plan.isMaintaining, isFalse);
        expect(plan.tdee, closeTo(1606.5625, 0.001));
        expect(plan.dailyCalorieTarget, closeTo(1881.5625, 0.001));
        expect(plan.planCalorieTarget, plan.dailyCalorieTarget);
        expect(plan.calorieTargetClamped, isFalse);
        expect(plan.goalPaceKgPerWeek, 0.25);
        expect(plan.goalPaceLevel, GoalPaceLevel.safe);
        expect(plan.targetWeightKg, 60);
        // 5 kg at 0.25 a week: 20 weeks.
        expect(plan.targetDate, DateTime(2026, 9, 8));
      });

      test('never under the minimum, even with a large Adaptive cut', () {
        // 1606.6 burn − 800 + 275 would be 1081.6, under the 1200 minimum.
        expect(gain(adaptiveKcal: -800).dailyCalorieTarget, 1200);
      });

      test('already at or over the target, the goal date is today', () {
        expect(gain(targetWeightKg: 55).targetDate, now);
        expect(gain(currentWeightKg: 62).targetDate, now);
        expect(gain(targetWeightKg: null).targetDate, now);
      });

      test('the Adaptive formula moves the burn and keeps the goal date', () {
        final plain = gain();
        for (final kcal in [-80.0, 120.0]) {
          final adjusted = gain(adaptiveKcal: kcal);
          expect(
            adjusted.dailyCalorieTarget,
            closeTo(plain.dailyCalorieTarget + kcal, 1e-9),
          );
          expect(adjusted.planCalorieTarget, plain.dailyCalorieTarget);
          expect(adjusted.tdee, plain.tdee);
          expect(adjusted.goalPaceKgPerWeek, 0.25);
          expect(adjusted.calorieTargetClamped, isFalse);
          expect(adjusted.targetDate, plain.targetDate);
        }
      });

      test('the date from the pace counts up', () {
        expect(
          HealthCalculator.targetDateFromWeightLossPace(
            70,
            75,
            WeightLossPace.gain,
            now: now,
          ),
          DateTime(2026, 9, 8),
        );
        expect(
          HealthCalculator.targetDateFromWeightLossPace(
            75,
            70,
            WeightLossPace.gain,
            now: now,
          ),
          now,
        );
      });
    });
  });

  group("the Adaptive formula's adjustment", () {
    HealthPlanCalculation plan({
      double weightKg = 80,
      Gender gender = Gender.male,
      WeightLossPace pace = WeightLossPace.moderate,
      double? adaptiveKcal,
    }) => HealthCalculator.calculatePlan(
      currentWeightKg: weightKg,
      targetWeightKg: 70,
      heightCm: 175,
      age: 35,
      gender: gender,
      activityLevel: ActivityLevel.lightlyActive,
      trainingFrequency: TrainingFrequency.oneToTwo,
      weightLossPace: pace,
      adaptiveKcal: adaptiveKcal ?? 0,
      now: DateTime(2026, 11, 2),
    );

    test('0 gives the same plan as before', () {
      for (final gender in Gender.values) {
        for (final pace in WeightLossPace.values) {
          for (final weightKg in [55.0, 80.0, 120.0]) {
            final before = HealthCalculator.calculatePlan(
              currentWeightKg: weightKg,
              targetWeightKg: 50,
              heightCm: 175,
              age: 35,
              gender: gender,
              activityLevel: ActivityLevel.lightlyActive,
              trainingFrequency: TrainingFrequency.oneToTwo,
              weightLossPace: pace,
              now: DateTime(2026, 11, 2),
            );
            final zero = HealthCalculator.calculatePlan(
              currentWeightKg: weightKg,
              targetWeightKg: 50,
              heightCm: 175,
              age: 35,
              gender: gender,
              activityLevel: ActivityLevel.lightlyActive,
              trainingFrequency: TrainingFrequency.oneToTwo,
              weightLossPace: pace,
              adaptiveKcal: 0,
              now: DateTime(2026, 11, 2),
            );
            expect(zero.dailyCalorieTarget, before.dailyCalorieTarget);
            expect(zero.planCalorieTarget, before.dailyCalorieTarget);
            expect(zero.calorieTargetClamped, before.calorieTargetClamped);
            expect(zero.goalPaceKgPerWeek, before.goalPaceKgPerWeek);
            expect(zero.targetDate, before.targetDate);
            expect(zero.tdee, before.tdee);
          }
        }
      }
    });

    test('−80 lowers the target by 80 and keeps the goal date', () {
      final plain = plan();
      final adjusted = plan(adaptiveKcal: -80);
      expect(
        adjusted.dailyCalorieTarget,
        closeTo(plain.dailyCalorieTarget - 80, 1e-9),
      );
      expect(adjusted.planCalorieTarget, plain.dailyCalorieTarget);
      expect(adjusted.tdee, plain.tdee);
      expect(adjusted.goalPaceKgPerWeek, closeTo(0.5, 1e-9));
      expect(adjusted.targetDate, plain.targetDate);
    });

    test('at the minimum it is clamped and the date is later', () {
      final plain = plan(pace: WeightLossPace.fast);
      final adjusted = plan(pace: WeightLossPace.fast, adaptiveKcal: -400);
      expect(adjusted.dailyCalorieTarget, 1500);
      expect(adjusted.calorieTargetClamped, isTrue);
      expect(adjusted.goalPaceKgPerWeek, lessThan(0.75));
      expect(adjusted.targetDate.isAfter(plain.targetDate), isTrue);
    });

    test('in maintain mode, −100 never goes below the minimum', () {
      // Maintenance of about 1260, 60 above a woman's minimum.
      HealthPlanCalculation maintain(double adaptiveKcal) =>
          HealthCalculator.calculatePlan(
            currentWeightKg: 45,
            targetWeightKg: null,
            heightCm: 155,
            age: 50,
            gender: Gender.female,
            activityLevel: ActivityLevel.sedentary,
            trainingFrequency: TrainingFrequency.none,
            weightLossPace: WeightLossPace.maintain,
            adaptiveKcal: adaptiveKcal,
          );
      expect(maintain(0).dailyCalorieTarget, closeTo(1259.7, 0.1));
      expect(maintain(-100).dailyCalorieTarget, 1200);
      expect(maintain(-100).planCalorieTarget, maintain(0).dailyCalorieTarget);
      expect(
        maintain(100).dailyCalorieTarget,
        closeTo(maintain(0).dailyCalorieTarget + 100, 1e-9),
      );
    });
  });

  group('protein target', () {
    test('scales goal weight by training frequency', () {
      int target(TrainingFrequency frequency) =>
          HealthCalculator.proteinTargetGrams(
            targetWeightKg: 75,
            trainingFrequency: frequency,
          );

      expect(target(TrainingFrequency.none), 90);
      expect(target(TrainingFrequency.oneToTwo), 120);
      expect(target(TrainingFrequency.threeToFour), 135);
      expect(target(TrainingFrequency.fivePlus), 150);
    });
  });

  group('macro targets', () {
    test('follow the calories and protein of the plan', () {
      final t = HealthCalculator.macroTargets(
        calories: 1670,
        proteinGrams: 131,
      );
      expect(t.fat, 56); // 30% of 1670 kcal is 501 kcal
      expect(t.carbs, 161); // (1670 - 131 × 4 - 501) / 4
      expect(t.saturates, 19); // 10% of the calories
      expect(t.sugars, 75); // 18%, the label guide's 90 g in 2,000 kcal
      expect(t.fibre, 25);
      expect(t.salt, 6);
    });

    test('a bigger plan gets bigger targets, fibre and salt stay', () {
      final small = HealthCalculator.macroTargets(
        calories: 1500,
        proteinGrams: 100,
      );
      final big = HealthCalculator.macroTargets(
        calories: 2500,
        proteinGrams: 100,
      );
      expect(big.fat, greaterThan(small.fat));
      expect(big.carbs, greaterThan(small.carbs));
      expect(big.saturates, greaterThan(small.saturates));
      expect((big.fibre, big.salt), (small.fibre, small.salt));
    });

    test('carbs never go below nothing', () {
      expect(
        HealthCalculator.macroTargets(calories: 900, proteinGrams: 200).carbs,
        0,
      );
    });
  });
}
