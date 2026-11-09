import 'dart:math' as math;

import 'package:lean_streak/models/user_profile.dart';

/// Pure functions for health and calorie calculations.
///
/// docs/features.md (Plan, weight and the trend) describes them.
class HealthCalculator {
  HealthCalculator._();

  /// BMI = weight(kg) / height(m)^2
  static double bmi(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Male:   BMR = 10w + 6.25h - 5a + 5
  /// Female: BMR = 10w + 6.25h - 5a - 161
  /// Other:  average of male and female offsets (-78)
  static double bmr(double weightKg, double heightCm, int age, Gender gender) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (gender) {
      Gender.male => base + 5,
      Gender.female => base - 161,
      Gender.other => base - 78,
    };
  }

  /// Converts general daily movement to a base TDEE multiplier.
  static double lifestyleMultiplier(ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => 1.25,
      ActivityLevel.lightlyActive => 1.35,
      ActivityLevel.moderatelyActive => 1.45,
      ActivityLevel.veryActive => 1.60,
    };
  }

  /// Adds structured training on top of the user's normal daily movement.
  static double trainingMultiplierBonus(TrainingFrequency frequency) {
    return switch (frequency) {
      TrainingFrequency.none => 0.0,
      TrainingFrequency.oneToTwo => 0.05,
      TrainingFrequency.threeToFour => 0.10,
      TrainingFrequency.fivePlus => 0.15,
    };
  }

  static double activityMultiplier(
    ActivityLevel level, [
    TrainingFrequency trainingFrequency = TrainingFrequency.none,
  ]) {
    final combined =
        lifestyleMultiplier(level) + trainingMultiplierBonus(trainingFrequency);
    return combined.clamp(1.20, 1.75).toDouble();
  }

  static double tdee(
    double bmr,
    ActivityLevel level, [
    TrainingFrequency trainingFrequency = TrainingFrequency.none,
  ]) {
    return bmr * activityMultiplier(level, trainingFrequency);
  }

  static double maintenanceCalories(double tdee) {
    return tdee;
  }

  /// Daily protein target in grams, per kg of goal weight. Goal weight rather
  /// than current weight so a higher starting body fat doesn't inflate it.
  static int proteinTargetGrams({
    required double targetWeightKg,
    required TrainingFrequency trainingFrequency,
  }) {
    final gramsPerKg = switch (trainingFrequency) {
      TrainingFrequency.none => 1.2,
      TrainingFrequency.oneToTwo => 1.6,
      TrainingFrequency.threeToFour => 1.8,
      TrainingFrequency.fivePlus => 2.0,
    };
    return (targetWeightKg * gramsPerKg).round();
  }

  /// The day's macro targets, from the plan's [calories] and protein, so they
  /// follow weight, height, age, gender and activity with it: fat about 30%
  /// of the calories, carbs the rest after protein and fat, saturates no
  /// more than 10% (the UK's advice) and all sugars no more than 18% (the
  /// food-label guide, 90 g in 2,000 kcal). Fibre (at least 25 g, the WHO's
  /// minimum: the UK's 30 g was out of reach on a low-calorie plan) and salt
  /// (no more than 6 g) are the same for every adult.
  static ({int fat, int carbs, int saturates, int sugars, int fibre, int salt})
  macroTargets({required int calories, required int proteinGrams}) {
    final fat = calories * 0.30 / 9;
    return (
      fat: fat.round(),
      carbs: math.max(0, (calories - proteinGrams * 4 - fat * 9) / 4).round(),
      saturates: (calories * 0.10 / 9).round(),
      sugars: (calories * 0.18 / 4).round(),
      fibre: 25,
      salt: 6,
    );
  }

  /// Converts the user's chosen weight-loss pace to kg/week.
  static double goalPaceFromWeightLossPace(WeightLossPace pace) {
    return switch (pace) {
      WeightLossPace.slow => 0.25,
      WeightLossPace.moderate => 0.50,
      WeightLossPace.fast => 0.75,
      WeightLossPace.maintain => 0.0,
    };
  }

  static DateTime targetDateFromPaceKgPerWeek(
    double currentWeightKg,
    double targetWeightKg,
    double paceKgPerWeek, {
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final totalKgToLose = (currentWeightKg - targetWeightKg).clamp(
      0,
      double.infinity,
    );
    if (paceKgPerWeek <= 0 || totalKgToLose <= 0) return anchor;
    final daysNeeded = ((totalKgToLose / paceKgPerWeek) * 7).ceil();
    return DateTime(anchor.year, anchor.month, anchor.day + daysNeeded);
  }

  /// Calculates the estimated target date from the user's chosen pace.
  static DateTime targetDateFromWeightLossPace(
    double currentWeightKg,
    double targetWeightKg,
    WeightLossPace pace, {
    DateTime? now,
  }) {
    return targetDateFromPaceKgPerWeek(
      currentWeightKg,
      targetWeightKg,
      goalPaceFromWeightLossPace(pace),
      now: now,
    );
  }

  /// <= 0.50 kg/week -> safe
  /// <= 0.75 kg/week -> caution
  /// > 0.75 kg/week -> warning
  static GoalPaceLevel goalPaceLevel(double kgPerWeek) {
    if (kgPerWeek <= 0.50) return GoalPaceLevel.safe;
    if (kgPerWeek <= 0.75) return GoalPaceLevel.caution;
    return GoalPaceLevel.warning;
  }

  static double calorieFloor(Gender gender) {
    return switch (gender) {
      Gender.male => 1500,
      Gender.female => 1200,
      Gender.other => 1350,
    };
  }

  /// 1 kg fat ~= 7700 kcal -> daily deficit = pace * 1100
  static ({double calories, bool clamped}) dailyCalorieTargetFromPace({
    required double tdee,
    required double paceKgPerWeek,
    required Gender gender,
  }) {
    final dailyDeficit = paceKgPerWeek * 1100;
    final raw = tdee - dailyDeficit;
    final floor = calorieFloor(gender);
    if (raw < floor) return (calories: floor, clamped: true);
    return (calories: raw, clamped: false);
  }

  static double effectivePaceKgPerWeek({
    required double tdee,
    required double dailyCalorieTarget,
  }) {
    final dailyDeficit = (tdee - dailyCalorieTarget)
        .clamp(0, double.infinity)
        .toDouble();
    return dailyDeficit / 1100;
  }

  /// [adaptiveKcal] is the Adaptive formula's correction to the formula's
  /// burn (docs/plans/08-adaptive-formula.md, step 9). It goes in before the
  /// minimum, so away from it the target moves by the same amount and the
  /// goal date stays; at the minimum the pace drops and the date moves later.
  static HealthPlanCalculation calculatePlan({
    required double currentWeightKg,
    required double? targetWeightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
    required TrainingFrequency trainingFrequency,
    required WeightLossPace weightLossPace,
    double adaptiveKcal = 0,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final calcBmi = bmi(currentWeightKg, heightCm);
    final calcBmr = bmr(currentWeightKg, heightCm, age, gender);
    final lifestyle = lifestyleMultiplier(activityLevel);
    final trainingBonus = trainingMultiplierBonus(trainingFrequency);
    final multiplier = activityMultiplier(activityLevel, trainingFrequency);
    final calcTdee = tdee(calcBmr, activityLevel, trainingFrequency);
    final burn = calcTdee + adaptiveKcal;
    final isMaintaining = weightLossPace == WeightLossPace.maintain;
    final resolvedTargetWeight = isMaintaining
        ? currentWeightKg
        : (targetWeightKg ?? currentWeightKg);
    final requestedPace = goalPaceFromWeightLossPace(weightLossPace);
    // A cut never takes maintenance below the minimum (or below the plain
    // maintenance, when that is already under it).
    final maintainFloor = math.min(calorieFloor(gender), calcTdee);
    final calorieResult = isMaintaining
        ? (
            calories: math.max(maintenanceCalories(burn), maintainFloor),
            clamped: burn < maintainFloor,
          )
        : dailyCalorieTargetFromPace(
            tdee: burn,
            paceKgPerWeek: requestedPace,
            gender: gender,
          );
    final effectivePace = isMaintaining
        ? 0.0
        : effectivePaceKgPerWeek(
            tdee: burn,
            dailyCalorieTarget: calorieResult.calories,
          );
    final calcTargetDate = isMaintaining
        ? anchor
        : targetDateFromPaceKgPerWeek(
            currentWeightKg,
            resolvedTargetWeight,
            effectivePace,
            now: anchor,
          );
    final paceLevel = isMaintaining
        ? GoalPaceLevel.safe
        : calorieResult.clamped
        ? GoalPaceLevel.warning
        : goalPaceLevel(requestedPace);
    final planCalorieTarget = adaptiveKcal == 0
        ? calorieResult.calories
        : isMaintaining
        ? calcTdee
        : dailyCalorieTargetFromPace(
            tdee: calcTdee,
            paceKgPerWeek: requestedPace,
            gender: gender,
          ).calories;

    return HealthPlanCalculation(
      bmi: calcBmi,
      bmr: calcBmr,
      lifestyleMultiplier: lifestyle,
      trainingMultiplierBonus: trainingBonus,
      activityMultiplier: multiplier,
      tdee: calcTdee,
      adaptiveKcal: adaptiveKcal,
      planCalorieTarget: planCalorieTarget,
      dailyCalorieTarget: calorieResult.calories,
      calorieTargetClamped: calorieResult.clamped,
      goalPaceKgPerWeek: effectivePace,
      goalPaceLevel: paceLevel,
      targetWeightKg: resolvedTargetWeight,
      targetDate: calcTargetDate,
      isMaintaining: isMaintaining,
    );
  }
}

class HealthPlanCalculation {
  const HealthPlanCalculation({
    required this.bmi,
    required this.bmr,
    required this.lifestyleMultiplier,
    required this.trainingMultiplierBonus,
    required this.activityMultiplier,
    required this.tdee,
    this.adaptiveKcal = 0,
    required this.planCalorieTarget,
    required this.dailyCalorieTarget,
    required this.calorieTargetClamped,
    required this.goalPaceKgPerWeek,
    required this.goalPaceLevel,
    required this.targetWeightKg,
    required this.targetDate,
    required this.isMaintaining,
  });

  final double bmi;
  final double bmr;
  final double lifestyleMultiplier;
  final double trainingMultiplierBonus;
  final double activityMultiplier;

  /// The formula's maintenance, without the Adaptive formula.
  final double tdee;

  /// The Adaptive formula's correction to [tdee], in kcal a day.
  final double adaptiveKcal;

  /// The target the formula alone gives (with [adaptiveKcal] 0).
  final double planCalorieTarget;
  final double dailyCalorieTarget;
  final bool calorieTargetClamped;
  final double goalPaceKgPerWeek;
  final GoalPaceLevel goalPaceLevel;
  final double targetWeightKg;
  final DateTime targetDate;
  final bool isMaintaining;
}
