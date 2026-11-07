import 'dart:math' as math;

import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';

/// The plan's own example (docs/plans/08-adaptive-formula.md, "Your plan"):
/// male, 29, 170 cm, 79.8 kg, goal 73 kg at the faster pace, movement and
/// training ×1.45, so a formula burn of 2495 and a target of 1670. Metric,
/// whatever the test's locale.
UserProfile planProfile({
  double weightKg = 79.8,
  double targetKg = 73,
  int age = 29,
  double heightCm = 170,
  Gender gender = Gender.male,
  ActivityLevel activity = ActivityLevel.lightlyActive,
  TrainingFrequency training = TrainingFrequency.threeToFour,
  WeightLossPace pace = WeightLossPace.fast,
  int adaptiveKcal = 0,
  DateTime? createdAt,
  String? adaptiveFrom,
  String? adaptiveWeek,
  String? adaptiveNote,
}) {
  final created = createdAt ?? DateTime(2026, 9, 1);
  final profile = UserProfile(
    uid: 'user-1',
    email: 'a@b.com',
    name: 'Test',
    weightUnit: WeightUnit.kg,
    heightUnit: HeightUnit.cm,
    age: age,
    gender: gender,
    heightCm: heightCm,
    currentWeightKg: weightKg,
    targetWeightKg: targetKg,
    activityLevel: activity,
    trainingFrequency: training,
    activityScaleVersion: currentActivityScaleVersion,
    planCalculationVersion: currentPlanCalculationVersion,
    weightLossPace: pace,
    targetDate: created,
    bmi: 0,
    bmr: 0,
    tdee: 0,
    dailyCalorieTarget: 0,
    goalPaceKgPerWeek: 0,
    goalPaceLevel: GoalPaceLevel.safe,
    onboardingCompleted: true,
    createdAt: created,
    updatedAt: created,
    adaptiveFrom: adaptiveFrom,
    adaptiveWeek: adaptiveWeek,
    adaptiveNote: adaptiveNote,
  );
  return AdaptiveFormula.replanned(profile, adaptiveKcal, now: created);
}

WeightEntry weighIn(DateTime day, double kg) => WeightEntry(
  dateKey: AdaptiveFormula.dateKey(day),
  weightKg: kg,
  loggedAt: day,
  source: WeightSource.manual,
);

DailySummary loggedDay(DateTime day, int kcal, int target) => DailySummary(
  date: AdaptiveFormula.dateKey(day),
  totalCalories: kcal,
  targetCalories: target,
  calorieDelta: kcal - target,
  mealCount: 3,
  status: DailyStatus.green,
  updatedAt: day,
);

bool everyDay(int day) => true;
double nothing(int day) => 0;

/// One simulated person, day by day: the plan's simulation in Dart. Their
/// real burn is the formula's plus [burnOffset]; they eat [intake] a day,
/// or to their target when null, and log [logShare] of it.
class Scenario {
  Scenario({
    required this.profile,
    DateTime? start,
    required this.weeks,
    this.burnOffset = 0,
    this.intake,
    this.logShare = 1,
    this.weightNoise = 0,
    this.intakeNoise = 0,
    this.weighs = everyDay,
    this.logs = everyDay,
    this.water = nothing,
    this.extraKcal = nothing,
    this.seed = 1,
    this.splitAtBreaks = true,
  }) : start = start ?? DateTime(2026, 11, 2);

  final UserProfile profile;

  /// Day 0, Monday 2 November 2026 unless given.
  final DateTime start;
  final int weeks;
  final double burnOffset;
  final double? intake;
  final double logShare;

  /// Standard deviations of each weigh-in (kg) and each day's food (kcal).
  final double weightNoise;
  final double intakeNoise;

  /// Whether day `i` (0 is [start]) has a weigh-in, or a logged day.
  final bool Function(int day) weighs;
  final bool Function(int day) logs;

  /// Water on the scale on day `i` (kg), and food over the usual (kcal).
  final double Function(int day) water;
  final double Function(int day) extraKcal;
  final int seed;
  final bool splitAtBreaks;
}

class SimMonday {
  const SimMonday(this.monday, this.result, this.profile);

  final DateTime monday;
  final AdaptiveMonday result;

  /// The profile after the run.
  final UserProfile profile;

  AdaptiveNote get note => result.note;
  int get adjustment => profile.adaptiveKcal;
  int get target => profile.dailyCalorieTarget.round();
}

class SimRun {
  SimRun(this.mondays, this.weights, this.entries, this.summaries);

  final List<SimMonday> mondays;

  /// The real weight at the start of each day.
  final List<double> weights;
  final List<WeightEntry> entries;
  final List<DailySummary> summaries;

  SimMonday on(int month, int day) =>
      mondays.firstWhere((m) => m.monday.month == month && m.monday.day == day);

  /// Real kg a week over the last [weeks] weeks.
  double lossPerWeek(int weeks) =>
      (weights[weights.length - 1 - weeks * 7] - weights.last) / weeks;
}

/// Runs [s]: each Monday goes through [AdaptiveFormula.monday], and each
/// weigh-in re-plans from the new weight, as the app does.
SimRun simulate(Scenario s) {
  final random = math.Random(s.seed);
  double gauss() =>
      math.sqrt(-2 * math.log(1 - random.nextDouble())) *
      math.cos(2 * math.pi * random.nextDouble());

  var profile = s.profile;
  var weight = profile.currentWeightKg;
  final mondays = <SimMonday>[];
  final weights = <double>[];
  final entries = <WeightEntry>[];
  final summaries = <DailySummary>[];

  for (var i = 0; i < s.weeks * 7; i++) {
    final day = DateTime(s.start.year, s.start.month, s.start.day + i);
    weights.add(weight);
    if (day.weekday == DateTime.monday && i > 0) {
      final result = AdaptiveFormula.monday(
        profile: profile,
        entries: entries,
        summaries: summaries,
        monday: day,
        splitAtBreaks: s.splitAtBreaks,
      );
      if (result.adjustment != profile.adaptiveKcal) {
        profile = AdaptiveFormula.replanned(
          profile,
          result.adjustment,
          now: day,
        );
      }
      profile = profile.copyWith(
        adaptiveWeek: AdaptiveFormula.dateKey(day),
        adaptiveNote: result.note.value,
      );
      mondays.add(SimMonday(day, result, profile));
    }

    if (s.weighs(i)) {
      final kg = weight + s.water(i) + s.weightNoise * gauss();
      entries.add(weighIn(day, kg));
      profile = AdaptiveFormula.replanned(
        profile.copyWith(currentWeightKg: kg),
        profile.adaptiveKcal,
        now: day,
      );
    }

    final target = profile.dailyCalorieTarget;
    final eaten =
        (s.intake ?? target / s.logShare) +
        s.extraKcal(i) +
        s.intakeNoise * gauss();
    if (s.logs(i)) {
      summaries.add(
        loggedDay(day, (eaten * s.logShare).round(), target.round()),
      );
    }

    final burn =
        HealthCalculator.tdee(
          HealthCalculator.bmr(
            weight,
            profile.heightCm,
            profile.age,
            profile.gender,
          ),
          profile.activityLevel,
          profile.trainingFrequency,
        ) +
        s.burnOffset;
    weight += (eaten - burn) / AdaptiveFormula.kcalPerKg;
  }
  weights.add(weight);
  return SimRun(mondays, weights, entries, summaries);
}
