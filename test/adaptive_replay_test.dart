import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/user_profile.dart';

import 'adaptive_fixtures.dart';

/// Your real weigh-ins and days, copied from the debug log's "Adaptive"
/// JSON into config/adaptive_replay.json (gitignored), run through the
/// calculator to show what each past Monday would have done. That's how
/// the starting values get tuned (docs/plans/08-adaptive-formula.md).
const _file = 'config/adaptive_replay.json';

void main() {
  test(
    'replays each Monday of your own data',
    () {
      final data = jsonDecode(File(_file).readAsStringSync()) as Map;
      final details = data['profile'] as Map;
      final entries = [
        for (final item in data['weighIns'] as List)
          weighIn(DateTime.parse(item['date']), (item['kg'] as num).toDouble()),
      ]..sort((a, b) => a.dateKey.compareTo(b.dateKey));
      final summaries = [
        for (final item in data['days'] as List)
          loggedDay(DateTime.parse(item['date']), item['kcal'], item['target']),
      ];
      var profile = planProfile(
        weightKg: (details['currentWeightKg'] as num).toDouble(),
        targetKg: (details['targetWeightKg'] as num).toDouble(),
        age: details['age'],
        heightCm: (details['heightCm'] as num).toDouble(),
        gender: Gender.fromString(details['gender']),
        activity: ActivityLevel.fromString(details['activityLevel']),
        training: TrainingFrequency.fromString(details['trainingFrequency']),
        pace: WeightLossPace.fromString(details['weightLossPace']),
        createdAt: DateTime.parse(details['createdAt']),
        adaptiveFrom: details['adaptiveFrom'],
      );

      final last = DateTime.parse(details['monday']);
      final first = [
        ...entries.map((e) => e.date),
        ...summaries.map((s) => DateTime.parse(s.date)),
      ].reduce((a, b) => a.isBefore(b) ? a : b);
      var monday = AdaptiveFormula.mondayOf(
        DateTime(first.year, first.month, first.day + 7),
      );
      while (!monday.isAfter(last)) {
        final before = [
          for (final entry in entries)
            if (entry.date.isBefore(monday)) entry,
        ];
        if (before.isNotEmpty) {
          profile = AdaptiveFormula.replanned(
            profile.copyWith(currentWeightKg: before.last.weightKg),
            profile.adaptiveKcal,
            now: monday,
          );
        }
        final result = AdaptiveFormula.monday(
          profile: profile,
          entries: entries,
          summaries: summaries,
          monday: monday,
        );
        profile =
            AdaptiveFormula.replanned(
              profile,
              result.adjustment,
              now: monday,
            ).copyWith(
              adaptiveWeek: AdaptiveFormula.dateKey(monday),
              adaptiveNote: result.note.value,
            );
        final m = result.measure;
        // ignore: avoid_print
        print(
          '${AdaptiveFormula.dateKey(monday)} ${result.note.value}, '
          'gap ${m.gap.round()}, confidence ${m.confidence.toStringAsFixed(2)}, '
          'aim ${result.aim}, step ${result.step}, '
          'adjustment ${result.adjustment}, '
          'target ${profile.dailyCalorieTarget.round()} '
          '(${m.weighIns} weigh-ins, ${m.daysLogged} days in ${m.days})',
        );
        monday = DateTime(monday.year, monday.month, monday.day + 7);
      }
    },
    skip: File(_file).existsSync() ? false : 'No $_file to replay.',
  );
}
