import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';

import 'adaptive_fixtures.dart';

const _learning = AdaptiveNote.learning;
const _steady = AdaptiveNote.steady;
const _firstSign = AdaptiveNote.firstSign;
const _lowered = AdaptiveNote.lowered;
const _raised = AdaptiveNote.raised;

double _median(List<num> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid].toDouble()
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Your plan, eating 1830 a day, weighing every morning and logging every
/// day, from Monday 2 November.
SimRun _yourPlan(double burnOffset, {int weeks = 8}) => simulate(
  Scenario(
    profile: planProfile(),
    weeks: weeks,
    burnOffset: burnOffset,
    intake: 1830,
  ),
);

/// The Monday 14 December run of [run]'s data, with the weigh-ins and days
/// changed as given, for [profile] (the plan's own by default).
AdaptiveMonday _rerun(
  SimRun run, {
  List<WeightEntry>? entries,
  List<DailySummary>? summaries,
  UserProfile? profile,
  DateTime? monday,
}) => AdaptiveFormula.monday(
  profile: profile ?? planProfile(),
  entries: entries ?? run.entries,
  summaries: summaries ?? run.summaries,
  monday: monday ?? DateTime(2026, 12, 14),
);

List<WeightEntry> _upTo(List<WeightEntry> entries, DateTime day) => [
  for (final entry in entries)
    if (!entry.date.isAfter(day)) entry,
];

void main() {
  group('your plan, noiseless, daily weigh-ins at 1830', () {
    test('(a) the formula is right: always steady, adjustment 0', () {
      final run = _yourPlan(0);
      expect(run.mondays.take(2).map((m) => m.note), everyElement(_learning));
      for (final monday in run.mondays.skip(2)) {
        expect(monday.note, _steady);
        expect(monday.adjustment, 0);
      }
    });

    test('(b) burning 225 less: a first sign, then −80, −160, −220', () {
      final run = _yourPlan(-227);
      expect(run.mondays.take(6).map((m) => m.note), [
        _learning,
        _learning,
        _firstSign,
        _lowered,
        _lowered,
        _lowered,
      ]);
      expect(run.mondays.take(6).map((m) => m.adjustment), [
        0,
        0,
        0,
        -80,
        -160,
        -220,
      ]);
      expect(run.on(11, 30).target, closeTo(1568, 2));
      for (final monday in run.mondays.skip(4)) {
        expect(monday.target, 1500);
      }
      final last = run.mondays.last.profile;
      expect(
        AdaptiveFormula.planOf(last).targetDate.isAfter(
          AdaptiveFormula.planOf(last, adaptiveKcal: 0).targetDate,
        ),
        isTrue,
      );
    });

    test('(c) burning 215 more: +80, +130, steady, +210', () {
      final run = _yourPlan(218);
      final acting = run.mondays.skip(2).take(4).toList();
      expect(acting.map((m) => m.note), [_raised, _raised, _steady, _raised]);
      expect(acting.map((m) => m.adjustment), [80, 130, 130, 210]);
    });
  });

  test('noisy daily weights, formula right: it wanders but stays near 0', () {
    final finals = <int>[];
    for (var seed = 1; seed <= 50; seed++) {
      final run = simulate(
        Scenario(
          profile: planProfile(),
          weeks: 10,
          intake: 1830,
          weightNoise: 0.5,
          intakeNoise: 250,
          seed: seed,
        ),
      );
      for (final monday in run.mondays) {
        expect(
          monday.adjustment.abs(),
          lessThanOrEqualTo(
            0.15 *
                AdaptiveFormula.planOf(
                  monday.profile,
                  adaptiveKcal: 0,
                ).dailyCalorieTarget,
          ),
        );
      }
      finals.add(run.mondays.last.adjustment);
    }
    expect(_median(finals).abs(), lessThanOrEqualTo(40));
  });

  group('logging 10% low, eating to target', () {
    // A man on a 2240 plan, losing 0.5 kg a week.
    final profile = planProfile(
      weightKg: 98,
      targetKg: 85,
      age: 30,
      heightCm: 185,
      training: TrainingFrequency.oneToTwo,
      pace: WeightLossPace.moderate,
    );

    test('the plan is the one the plan describes', () {
      expect(profile.dailyCalorieTarget, closeTo(2240, 5));
    });

    test('noiseless: the real loss comes back to the plan', () {
      final run = simulate(
        Scenario(profile: profile, weeks: 14, logShare: 0.9),
      );
      expect(run.lossPerWeek(4), closeTo(0.5, 0.05));
    });

    test('noisy: over 20 seeds it comes back too', () {
      final losses = [
        for (var seed = 1; seed <= 20; seed++)
          simulate(
            Scenario(
              profile: profile,
              weeks: 14,
              logShare: 0.9,
              weightNoise: 0.5,
              intakeNoise: 250,
              seed: seed,
            ),
          ).lossPerWeek(4),
      ];
      expect(losses.reduce((a, b) => a + b) / losses.length, closeTo(0.5, 0.1));
    });

    test('logging honestly, the adjustment stays within ±50', () {
      final run = simulate(Scenario(profile: profile, weeks: 14));
      for (final monday in run.mondays) {
        expect(monday.adjustment.abs(), lessThanOrEqualTo(50));
      }
    });
  });

  group('forgotten-meal days', () {
    final run = _yourPlan(0);
    final plain = _rerun(run).measure;

    List<DailySummary> withDay(String date, double share) => [
      for (final day in run.summaries)
        day.date == date
            ? loggedDay(
                DateTime.parse(date),
                (share * day.targetCalories).round(),
                day.targetCalories,
              )
            : day,
    ];

    test('a day at 40% of target is left out', () {
      final measured = _rerun(
        run,
        summaries: withDay('2026-12-01', 0.4),
      ).measure;
      expect(measured.daysLogged, plain.daysLogged - 1);
      expect(measured.gap, closeTo(plain.gap, 10));
    });

    test('a day at 65% counts', () {
      final measured = _rerun(
        run,
        summaries: withDay('2026-12-01', 0.65),
      ).measure;
      expect(measured.daysLogged, plain.daysLogged);
    });

    test('too few days logged in all, or in the week, give few_days', () {
      // Every other day: under 4 days in 7.
      final sparse = [
        for (final (i, day) in run.summaries.indexed)
          if (i.isEven) day,
      ];
      expect(_rerun(run, summaries: sparse).note, AdaptiveNote.fewDays);

      // Three days in the finished week.
      final thinWeek = [
        for (final day in run.summaries)
          if (day.date.compareTo('2026-12-07') < 0 ||
              day.date.compareTo('2026-12-11') >= 0)
            day,
      ];
      expect(_rerun(run, summaries: thinWeek).note, AdaptiveNote.fewDays);
    });
  });

  group('creatine', () {
    // 1 kg of water over 4 weeks from day 28, then it stays.
    double water(int day) => (day - 28).clamp(0, 28) / 28;

    test('without the hook: a dip that never passes 15%, then back', () {
      final run = simulate(
        Scenario(profile: planProfile(), weeks: 17, intake: 1830, water: water),
      );
      for (final monday in run.mondays) {
        expect(
          monday.adjustment,
          greaterThanOrEqualTo(
            -0.15 *
                AdaptiveFormula.planOf(
                  monday.profile,
                  adaptiveKcal: 0,
                ).dailyCalorieTarget,
          ),
        );
      }
      expect(run.mondays.map((m) => m.adjustment).reduce(_min), lessThan(0));
      // The water settles on day 56; 8 weeks later is day 112.
      final settled = run.mondays.firstWhere(
        (m) => m.monday.difference(DateTime(2026, 11, 2)).inDays >= 112,
      );
      expect(settled.adjustment.abs(), lessThanOrEqualTo(60));
    });

    test(
      'with adaptiveFrom 28 days after turning the reminder on: no change',
      () {
        final run = simulate(
          Scenario(
            profile: planProfile(adaptiveFrom: '2026-12-28'),
            weeks: 17,
            intake: 1830,
            water: water,
          ),
        );
        for (final monday in run.mondays) {
          expect(monday.adjustment, 0);
        }
      },
    );
  });

  group('typos', () {
    final run = _yourPlan(0);

    test('97.8 among 79s gives the same result as without it', () {
      final typo = [
        for (final entry in run.entries)
          entry.dateKey == '2026-12-02' ? weighIn(entry.date, 97.8) : entry,
      ];
      final without = [
        for (final entry in run.entries)
          if (entry.dateKey != '2026-12-02') entry,
      ];
      final withTypo = _rerun(run, entries: typo).measure;
      final withoutIt = _rerun(run, entries: without).measure;
      expect(withTypo.weighIns, withoutIt.weighIns);
      expect(withTypo.gap, closeTo(withoutIt.gap, 1e-9));
      expect(withTypo.confidence, closeTo(withoutIt.confidence, 1e-9));
    });

    test('a jump the next weigh-in confirms is used', () {
      final sunday = DateTime(2026, 12, 13);
      final jumped = [
        for (final entry in _upTo(run.entries, sunday))
          entry.dateKey.compareTo('2026-12-11') >= 0
              ? weighIn(entry.date, entry.weightKg + 3)
              : entry,
      ];
      final plain = _rerun(run).measure;
      final measured = _rerun(run, entries: jumped).measure;
      expect(measured.weighIns, plain.weighIns);
      expect(measured.gap, isNot(closeTo(plain.gap, 1)));
    });
  });

  group('a holiday: 14 unlogged, unweighed days at +1000 kcal', () {
    bool away(int day) => day >= 21 && day < 35;

    Scenario holiday({required bool splitAtBreaks}) => Scenario(
      profile: planProfile(),
      weeks: 12,
      intake: 1830,
      weighs: (day) => !away(day),
      logs: (day) => !away(day),
      extraKcal: (day) => away(day) ? 1000 : 0,
      splitAtBreaks: splitAtBreaks,
    );

    test('changes nothing', () {
      final run = simulate(holiday(splitAtBreaks: true));
      for (final monday in run.mondays) {
        expect(monday.adjustment, 0);
      }
    });

    test('without the break rule, it would cut', () {
      final run = simulate(holiday(splitAtBreaks: false));
      expect(run.mondays.map((m) => m.adjustment).reduce(_min), lessThan(0));
    });
  });

  group('weigh-in habits', () {
    AdaptiveMeasure measureAt(bool Function(int) weighs, {int weeks = 6}) {
      final run = simulate(
        Scenario(
          profile: planProfile(),
          weeks: weeks + 1,
          intake: 1830,
          weightNoise: 0.4,
          weighs: weighs,
        ),
      );
      return run.mondays.last.result.measure;
    }

    test('daily gives more confidence than 3 a week', () {
      final daily = measureAt(everyDay);
      final threeAWeek = measureAt(
        (day) => day % 7 == 0 || day % 7 == 2 || day % 7 == 4,
      );
      expect(daily.hold, isNull);
      expect(threeAWeek.hold, isNull);
      expect(daily.confidence, greaterThan(threeAWeek.confidence));
    });

    test('weekly gives few_weigh_ins every Monday', () {
      final run = simulate(
        Scenario(
          profile: planProfile(),
          weeks: 8,
          intake: 1830,
          weighs: (day) => day % 7 == 5,
        ),
      );
      for (final monday in run.mondays.skip(2)) {
        expect(monday.note, AdaptiveNote.fewWeighIns);
      }
    });

    test('fewer than 2 in the finished week gives few_weigh_ins', () {
      final run = _yourPlan(0);
      final oneLastWeek = [
        for (final entry in run.entries)
          if (entry.dateKey.compareTo('2026-12-07') < 0 ||
              entry.dateKey == '2026-12-10')
            entry,
      ];
      expect(_rerun(run, entries: oneLastWeek).note, AdaptiveNote.fewWeighIns);
    });
  });

  group('two Mondays to cut', () {
    // Burning 227 less: the 30 November run aims for −130.
    final run = _yourPlan(-227);
    final monday = DateTime(2026, 11, 30);
    AdaptiveMonday on({String? week, String? note}) => _rerun(
      run,
      monday: monday,
      profile: planProfile(adaptiveWeek: week, adaptiveNote: note),
    );

    test('a first cut is a first sign, with no change', () {
      final result = on();
      expect(result.note, _firstSign);
      expect(result.adjustment, 0);
    });

    test('the next Monday lowers it', () {
      final result = on(week: '2026-11-23', note: 'first_sign');
      expect(result.note, _lowered);
      expect(result.adjustment, -80);
    });

    test('a steady Monday in between, or a missed one, starts again', () {
      expect(on(week: '2026-11-23', note: 'steady').note, _firstSign);
      expect(on(week: '2026-11-16', note: 'first_sign').note, _firstSign);
    });

    test('a raise happens at once', () {
      final result = _rerun(_yourPlan(218), monday: monday);
      expect(result.note, _raised);
      expect(result.adjustment, 80);
    });
  });

  group('limits', () {
    ({AdaptiveNote note, int adjustment}) decide(
      int aim, {
      int current = 0,
      bool cutPending = true,
    }) => AdaptiveFormula.decide(
      aim: aim,
      current: current,
      planTarget: 2000,
      cutPending: cutPending,
    );

    test('a step is never more than 5% of the plan', () {
      expect(decide(-300).adjustment, -100);
      expect(decide(300).adjustment, 100);
      expect(decide(-300, current: -100).adjustment, -200);
    });

    test('the total is never more than 15% of the plan', () {
      expect(decide(-390, current: -250).adjustment, -300);
      expect(decide(-390, current: -300).note, _steady);
      expect(decide(390, current: 250).adjustment, 300);
    });

    test('an aim over 20% of the plan is unusual, with no change', () {
      expect(decide(-410, current: -80).note, AdaptiveNote.unusual);
      expect(decide(-410, current: -80).adjustment, -80);
      expect(decide(410).note, AdaptiveNote.unusual);
      expect(decide(-400).note, _lowered);
    });

    test('the dead band holds at 49 and moves at 50', () {
      expect(decide(49).note, _steady);
      expect(decide(50).note, _raised);
      expect(decide(50).adjustment, 50);
      expect(decide(-149, current: -100).note, _steady);
      expect(decide(-150, current: -100).adjustment, -150);
    });
  });

  group('the minimum and the goal date', () {
    test('the target is never below the minimum, whatever the gender', () {
      for (final gender in Gender.values) {
        final profile = planProfile(
          gender: gender,
          weightKg: 60,
          targetKg: 50,
          heightCm: 160,
        );
        final lowest = AdaptiveFormula.planOf(profile, adaptiveKcal: -400);
        expect(
          lowest.dailyCalorieTarget,
          HealthCalculator.calorieFloor(gender),
        );
      }
    });

    test('at the minimum because of the adjustment, the date is later', () {
      final profile = planProfile();
      final plain = AdaptiveFormula.planOf(profile, adaptiveKcal: 0);
      final adjusted = AdaptiveFormula.planOf(profile, adaptiveKcal: -220);
      expect(adjusted.dailyCalorieTarget, 1500);
      expect(adjusted.targetDate.isAfter(plain.targetDate), isTrue);
    });

    test('away from the minimum, the goal date is the plain plan\'s', () {
      final profile = planProfile();
      final plain = AdaptiveFormula.planOf(profile, adaptiveKcal: 0);
      final adjusted = AdaptiveFormula.planOf(profile, adaptiveKcal: -80);
      expect(
        adjusted.dailyCalorieTarget,
        closeTo(plain.dailyCalorieTarget - 80, 1e-9),
      );
      expect(adjusted.targetDate, plain.targetDate);
    });
  });

  group('the window', () {
    final run = _yourPlan(0, weeks: 10);

    test('under 21 days is learning', () {
      final measured = AdaptiveFormula.measure(
        profile: planProfile(),
        entries: run.entries,
        summaries: run.summaries,
        end: DateTime(2026, 11, 21),
      );
      expect(measured.days, 20);
      expect(measured.hold, _learning);
    });

    test('a new account\'s first 14 days aren\'t used', () {
      final measured = AdaptiveFormula.measure(
        profile: planProfile(createdAt: DateTime(2026, 11, 2)),
        entries: run.entries,
        summaries: run.summaries,
        end: DateTime(2026, 12, 6),
      );
      // 16 November to 6 December.
      expect(measured.days, 21);
    });

    test('nothing older than 42 days is used', () {
      final monday = DateTime(2027, 1, 4);
      final old = AdaptiveFormula.dateKey(DateTime(2026, 11, 22));
      final changed = [
        for (final entry in run.entries)
          entry.dateKey == old
              ? weighIn(entry.date, entry.weightKg + 0.5)
              : entry,
      ];
      final plain = _rerun(run, monday: monday).measure;
      final measured = _rerun(run, entries: changed, monday: monday).measure;
      expect(plain.days, 42);
      expect(measured.gap, plain.gap);
      expect(measured.confidence, plain.confidence);
    });

    test('adaptiveFrom is respected', () {
      final measured = AdaptiveFormula.measure(
        profile: planProfile(adaptiveFrom: '2026-11-20'),
        entries: run.entries,
        summaries: run.summaries,
        end: DateTime(2026, 12, 13),
      );
      expect(measured.days, 24);
    });
  });

  test('paused: the last weigh-in 10 days ago, the adjustment unchanged', () {
    final run = _yourPlan(0);
    final monday = DateTime(2026, 12, 14);
    final profile = planProfile(adaptiveKcal: -80);
    AdaptiveMonday lastWeighIn(int daysAgo) => _rerun(
      run,
      monday: monday,
      profile: profile,
      entries: _upTo(
        run.entries,
        DateTime(monday.year, monday.month, monday.day - daysAgo),
      ),
    );

    expect(lastWeighIn(10).note, AdaptiveNote.paused);
    expect(lastWeighIn(10).adjustment, -80);
    expect(lastWeighIn(9).note, isNot(AdaptiveNote.paused));
  });

  test('a lapse: frozen for 2 weeks from the end, then over', () {
    final ended = DateTime(2026, 11, 1, 18);
    expect(
      AdaptiveFormula.frozen(endedAt: ended, now: DateTime(2026, 11, 10)),
      isTrue,
    );
    expect(
      AdaptiveFormula.frozen(endedAt: ended, now: DateTime(2026, 11, 15)),
      isFalse,
    );
    expect(AdaptiveFormula.lapseEnd(ended), DateTime(2026, 11, 15));
    expect(
      AdaptiveFormula.frozen(endedAt: null, now: DateTime(2026, 11, 10)),
      isFalse,
    );
  });
}

int _min(int a, int b) => a < b ? a : b;
