import 'dart:math' as math;

import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/helpers/weight_trend.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';

/// A Monday's result, stored as the profile's `adaptiveNote`.
enum AdaptiveNote {
  learning('learning'),
  paused('paused'),
  fewWeighIns('few_weigh_ins'),
  fewDays('few_days'),
  unusual('unusual'),
  steady('steady'),
  firstSign('first_sign'),
  lowered('lowered'),
  raised('raised'),
  off('off');

  const AdaptiveNote(this.value);
  final String value;

  /// Null for a profile that has never had one.
  static AdaptiveNote? fromString(String? value) {
    for (final note in values) {
      if (note.value == value) return note;
    }
    return null;
  }
}

/// How well it knows you, as Plan Settings says it.
enum AdaptiveStage { paused, learning, gettingToKnow, fairlyWell, well }

/// What the last 1 to 6 weeks of weigh-ins and logged days say.
class AdaptiveMeasure {
  const AdaptiveMeasure({
    required this.hold,
    required this.days,
    required this.weighIns,
    required this.daysLogged,
    this.gap = 0,
    this.confidence = 0,
    this.formulaBurn = 0,
  });

  /// Why it can't act yet (paused, learning, too few weigh-ins or logged
  /// days), or null when it can.
  final AdaptiveNote? hold;

  /// The window's length, L.
  final int days;

  /// Weigh-ins and logged days that count.
  final int weighIns;
  final int daysLogged;

  /// Measured burn minus the formula's, in kcal a day.
  final double gap;

  /// From 0 to 1: weigh-ins × days logged × steadiness × weeks.
  final double confidence;

  /// The formula's burn at the window's average weight, in kcal a day.
  final double formulaBurn;

  /// What you burn a day as far as it trusts what it has measured: the
  /// formula's guess, moved towards the measured burn by [confidence].
  double get burn => formulaBurn + gap * confidence;

  AdaptiveStage get stage => switch (hold) {
    AdaptiveNote.paused => AdaptiveStage.paused,
    null when confidence >= 0.7 => AdaptiveStage.well,
    null when confidence >= 0.4 => AdaptiveStage.fairlyWell,
    null => AdaptiveStage.gettingToKnow,
    _ => AdaptiveStage.learning,
  };
}

/// One Monday's decision.
class AdaptiveMonday {
  const AdaptiveMonday({
    required this.note,
    required this.adjustment,
    required this.aim,
    required this.step,
    required this.measure,
  });

  final AdaptiveNote note;

  /// The new adjustment, in kcal a day.
  final int adjustment;
  final int aim;
  final int step;
  final AdaptiveMeasure measure;
}

/// The Adaptive formula (docs/plans/08-adaptive-formula.md): a personal
/// adjustment on top of the plan, learnt from weigh-ins and logged food and
/// changed only on Mondays. Pure, so every rule can be tested.
class AdaptiveFormula {
  AdaptiveFormula._();

  // The trend's smoothing and the typo rule are in weight_trend.dart.
  static const maxWindowDays = 42;
  static const minWindowDays = 7;
  static const newAccountDays = 7;
  static const creatineDays = 28;
  static const halfLoggedShare = 0.6;
  static const breakDays = 3;
  static const minWeighIns = 3;
  static const minWeighInSpanDays = 5;
  static const minWeighInsInWeek = 2;
  static const minLoggedShare = 4 / 7;
  static const minLoggedInWeek = 4;
  static const pausedDays = 10;
  static const fullWeighInsPerWeek = 4;
  static const fullScatter = 0.005;
  static const fullWeeks = 6;
  static const deadBand = 20;
  static const stepShare = 0.05;
  static const fullStepDays = 21;
  static const totalShare = 0.15;
  static const unusualShare = 0.20;
  static const kcalPerKg = 7700;

  /// How far under the plan at the fast pace the target may ever go.
  static const belowFastest = 50;

  /// How long the adjustment stays frozen once YumSum Star ends.
  static const lapseDays = 14;

  static final _dateKey = DateFormat('yyyy-MM-dd');

  static String dateKey(DateTime day) => _dateKey.format(day);

  /// The Monday of [now]'s week.
  static DateTime mondayOf(DateTime now) =>
      DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));

  /// The day the target goes back to the standard plan after YumSum Star
  /// ended on [endedAt].
  static DateTime lapseEnd(DateTime endedAt) =>
      DateTime(endedAt.year, endedAt.month, endedAt.day + lapseDays);

  /// Whether a lapsed adjustment is still frozen: ended less than 2 weeks
  /// ago. Without an end date it isn't.
  static bool frozen({required DateTime? endedAt, required DateTime now}) =>
      endedAt != null && now.isBefore(lapseEnd(endedAt));

  /// The plan from the profile's own details, with [adaptiveKcal] (the
  /// profile's own when not given).
  static HealthPlanCalculation planOf(
    UserProfile profile, {
    int? adaptiveKcal,
    DateTime? now,
  }) {
    return HealthCalculator.calculatePlan(
      currentWeightKg: profile.currentWeightKg,
      targetWeightKg: profile.targetWeightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      gender: profile.gender,
      activityLevel: profile.activityLevel,
      trainingFrequency: profile.trainingFrequency,
      weightLossPace: profile.weightLossPace,
      adaptiveKcal: (adaptiveKcal ?? profile.adaptiveKcal).toDouble(),
      now: now,
    );
  }

  /// The lowest adjustment allowed: the target never goes more than
  /// [belowFastest] kcal under what the plan would be at the fast pace, so a
  /// cut can't make a plan harsher than the harshest one offered. On the
  /// fast pace itself that's −50; on the others the 15% limit usually bites
  /// first.
  static int lowestAdjustment(UserProfile profile) {
    final plan = planOf(profile, adaptiveKcal: 0).dailyCalorieTarget;
    final fastest = planOf(
      profile.copyWith(weightLossPace: WeightLossPace.fast),
      adaptiveKcal: 0,
    ).dailyCalorieTarget;
    return ((fastest - belowFastest - plan) / 10).ceil() * 10;
  }

  /// [profile] re-planned with [adaptiveKcal], every other detail kept.
  static UserProfile replanned(
    UserProfile profile,
    int adaptiveKcal, {
    required DateTime now,
  }) {
    final plan = planOf(profile, adaptiveKcal: adaptiveKcal, now: now);
    return profile.copyWith(
      adaptiveKcal: adaptiveKcal,
      targetWeightKg: plan.targetWeightKg,
      targetDate: plan.targetDate,
      bmi: plan.bmi,
      bmr: plan.bmr,
      tdee: plan.tdee,
      dailyCalorieTarget: plan.dailyCalorieTarget,
      goalPaceKgPerWeek: plan.goalPaceKgPerWeek,
      goalPaceLevel: plan.goalPaceLevel,
      updatedAt: now,
    );
  }

  /// Steps 1 to 7, over the weigh-ins and logged days up to [end] (Sunday on
  /// a Monday, or yesterday for Plan Settings). [entries] are all the
  /// weigh-ins, oldest first; [summaries] those of the window. Only tests
  /// turn [splitAtBreaks] off, to show what the break rule is for.
  static AdaptiveMeasure measure({
    required UserProfile profile,
    required List<WeightEntry> entries,
    required List<DailySummary> summaries,
    required DateTime end,
    bool splitAtBreaks = true,
  }) {
    final endDay = _day(end);
    final today = endDay + 1;

    // Step 1: the window, never older than 6 weeks, nor a new account's
    // first week (mostly water and stored carbohydrate), nor before
    // adaptiveFrom or the first day logged.
    var start = math.max(
      today - maxWindowDays,
      _day(profile.createdAt) + newAccountDays,
    );
    final from = profile.adaptiveFrom;
    if (from != null) start = math.max(start, _day(DateTime.parse(from)));
    final loggedDays = [
      for (final summary in summaries) _day(DateTime.parse(summary.date)),
      for (final entry in entries) _day(entry.date),
    ].where((day) => day >= start && day <= endDay);
    final days = loggedDays.isEmpty
        ? 0
        : endDay - loggedDays.reduce(math.min) + 1;
    start = endDay - days + 1;

    // Step 2: which days count. A break (3 or more days with nothing
    // logged) splits the window into stretches.
    final summaryOn = {
      for (final summary in summaries)
        if (_day(DateTime.parse(summary.date)) case final day
            when day >= start && day <= endDay)
          day: summary,
    };
    final counted = [
      for (final summary in summaryOn.values)
        if (summary.totalCalories >= halfLoggedShare * summary.targetCalories)
          summary,
    ];
    // Days in a break belong to no stretch.
    final stretchOf = <int, int>{};
    var stretch = 0;
    var run = <int>[];
    void endRun() {
      if (splitAtBreaks && run.length >= breakDays) {
        run.forEach(stretchOf.remove);
        stretch++;
      }
      run = [];
    }

    for (var day = start; day <= endDay; day++) {
      if (summaryOn.containsKey(day)) {
        endRun();
      } else {
        run.add(day);
      }
      stretchOf[day] = stretch;
    }
    endRun();

    // Step 3: which weigh-ins count. The typo rule runs over every weigh-in
    // up to the end, but only the window's are used.
    final upToEnd = [
      for (final entry in entries)
        if (_day(entry.date) <= endDay) entry,
    ];
    final trend = weightTrend(upToEnd);
    final byStretch = <int, List<({int day, double kg})>>{};
    for (final (i, entry) in upToEnd.indexed) {
      final day = _day(entry.date);
      final s = stretchOf[day];
      if (day < start || s == null || trend[i].setAside) continue;
      (byStretch[s] ??= []).add((day: day, kg: entry.weightKg));
    }
    final stretches = [
      for (final points in byStretch.values)
        if (points.length >= 2) points,
    ];
    final weighIns = [for (final points in stretches) ...points];

    AdaptiveMeasure hold(AdaptiveNote note) => AdaptiveMeasure(
      hold: note,
      days: days,
      weighIns: weighIns.length,
      daysLogged: counted.length,
    );

    // Step 6: enough data to act? Someone who has never weighed in is
    // still learning rather than paused.
    final lastWeighIn = [
      for (final entry in entries)
        if (_day(entry.date) <= today) _day(entry.date),
    ].fold<int?>(null, (last, day) => math.max(last ?? day, day));
    if (lastWeighIn != null && today - lastWeighIn >= pausedDays) {
      return hold(AdaptiveNote.paused);
    }
    if (days < minWindowDays) return hold(AdaptiveNote.learning);
    final weekStart = endDay - 6;
    final span = weighIns.isEmpty
        ? 0
        : weighIns.map((p) => p.day).reduce(math.max) -
              weighIns.map((p) => p.day).reduce(math.min) +
              1;
    if (weighIns.length < minWeighIns ||
        span < minWeighInSpanDays ||
        weighIns.where((p) => p.day >= weekStart).length < minWeighInsInWeek) {
      return hold(AdaptiveNote.fewWeighIns);
    }
    if (counted.length < minLoggedShare * days ||
        counted.where((s) => _day(DateTime.parse(s.date)) >= weekStart).length <
            minLoggedInWeek) {
      return hold(AdaptiveNote.fewDays);
    }

    // Step 4: one slope through every stretch, each with its own level.
    var sxy = 0.0;
    var sxx = 0.0;
    final centred = <({double t, double w})>[];
    for (final points in stretches) {
      final tMean =
          points.fold<double>(0, (sum, p) => sum + p.day) / points.length;
      final wMean =
          points.fold<double>(0, (sum, p) => sum + p.kg) / points.length;
      for (final p in points) {
        final t = p.day - tMean;
        final w = p.kg - wMean;
        sxy += t * w;
        sxx += t * t;
        centred.add((t: t, w: w));
      }
    }
    final slope = sxy / sxx;
    final averageKg =
        weighIns.fold<double>(0, (sum, p) => sum + p.kg) / weighIns.length;
    final squares = centred.fold<double>(0, (sum, p) {
      final off = p.w - slope * p.t;
      return sum + off * off;
    });
    final scatter = math.sqrt(squares / centred.length) / averageKg;

    // Step 5: the measurement.
    final averageKcal =
        counted.fold<double>(0, (sum, s) => sum + s.totalCalories) /
        counted.length;
    final measuredBurn = averageKcal - slope * kcalPerKg;
    final formulaBurn = HealthCalculator.tdee(
      HealthCalculator.bmr(
        averageKg,
        profile.heightCm,
        profile.age,
        profile.gender,
      ),
      profile.activityLevel,
      profile.trainingFrequency,
    );

    // Step 7: confidence.
    final weeks = days / 7;
    final w = math.min(1.0, weighIns.length / weeks / fullWeighInsPerWeek);
    final d = counted.length / days;
    final s = scatter == 0 ? 1.0 : math.min(1.0, fullScatter / scatter);
    final t = math.min(1.0, weeks / fullWeeks);

    return AdaptiveMeasure(
      hold: null,
      days: days,
      weighIns: weighIns.length,
      daysLogged: counted.length,
      gap: measuredBurn - formulaBurn,
      confidence: w * d * s * t,
      formulaBurn: formulaBurn,
    );
  }

  /// The Monday run's decision for [monday], from the week that ended the
  /// day before.
  static AdaptiveMonday monday({
    required UserProfile profile,
    required List<WeightEntry> entries,
    required List<DailySummary> summaries,
    required DateTime monday,
    bool splitAtBreaks = true,
  }) {
    final measured = measure(
      profile: profile,
      entries: entries,
      summaries: summaries,
      end: DateTime(monday.year, monday.month, monday.day - 1),
      splitAtBreaks: splitAtBreaks,
    );
    final current = profile.adaptiveKcal;
    if (measured.hold case final note?) {
      return AdaptiveMonday(
        note: note,
        adjustment: current,
        aim: 0,
        step: 0,
        measure: measured,
      );
    }
    final aim = (measured.gap * measured.confidence / 10).truncate() * 10;
    final lastMonday = dateKey(
      DateTime(monday.year, monday.month, monday.day - 7),
    );
    final lastNote = AdaptiveNote.fromString(profile.adaptiveNote);
    final decision = decide(
      aim: aim,
      current: current,
      planTarget: planOf(profile, adaptiveKcal: 0).dailyCalorieTarget,
      floor: lowestAdjustment(profile),
      cutPending:
          profile.adaptiveWeek == lastMonday &&
          (lastNote == AdaptiveNote.firstSign ||
              lastNote == AdaptiveNote.lowered),
      stepScale: math.min(1.0, measured.days / fullStepDays),
    );
    return AdaptiveMonday(
      note: decision.note,
      adjustment: decision.adjustment,
      aim: aim,
      step: decision.adjustment - current,
      measure: measured,
    );
  }

  /// Step 8, from the aim (gap × confidence): the limits, the dead band and
  /// the two Mondays a cut needs. [cutPending] is last Monday wanting one;
  /// [stepScale] shrinks the step limit while there are under 3 weeks of
  /// data, so early weeks move the target only a little. [floor] is the
  /// lowest adjustment allowed ([lowestAdjustment]); the 15% limit without.
  static ({AdaptiveNote note, int adjustment}) decide({
    required int aim,
    required int current,
    required double planTarget,
    required bool cutPending,
    double stepScale = 1,
    int? floor,
  }) {
    int tens(double kcal) => (kcal / 10).floor() * 10;
    if (aim.abs() > unusualShare * planTarget) {
      return (note: AdaptiveNote.unusual, adjustment: current);
    }
    final limit = tens(totalShare * planTarget);
    final lowest = math.max(-limit, floor ?? -limit);
    final wanted = aim.clamp(lowest, limit) - current;
    if (wanted.abs() < deadBand) {
      return (note: AdaptiveNote.steady, adjustment: current);
    }
    final maxStep = tens(stepShare * stepScale * planTarget);
    final step = wanted.clamp(-maxStep, maxStep);
    if (step > 0) {
      return (note: AdaptiveNote.raised, adjustment: current + step);
    }
    if (!cutPending) {
      return (note: AdaptiveNote.firstSign, adjustment: current);
    }
    return (note: AdaptiveNote.lowered, adjustment: current + step);
  }

  /// Whole days from [from] to [to], whatever the time of day or the clocks.
  static int daysBetween(DateTime from, DateTime to) => _day(to) - _day(from);

  /// A day as a whole number, the same across clock changes.
  static int _day(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
