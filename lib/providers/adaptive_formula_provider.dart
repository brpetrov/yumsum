import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';

/// The Adaptive formula's Monday run (docs/plans/08-adaptive-formula.md),
/// watched by the app. It acts the first time the app opens on or after a
/// Monday, once a week, and is safe across phones: whichever runs first
/// records the week. It also ends a lapsed subscriber's adjustment.
final adaptiveMondayProvider = FutureProvider.autoDispose<void>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;
  // Only the trigger: its first value can be this phone's cached copy, and
  // the writes below replace the whole profile, so they start from the
  // server's.
  if (await ref.watch(userProfileProvider.future) == null) return;
  // Awaited, so a subscription still loading is never read as free.
  final entitlement = await ref.watch(entitlementProvider.future);
  final now = DateTime.now();
  final today = AdaptiveFormula.dateKey(now);
  final profiles = ref.read(userProfileRepositoryProvider);
  final summaryService = ref.read(dailySummaryServiceProvider);
  final profile = await profiles.fetchProfile(uid);
  if (profile == null) return;

  if (!(entitlement?.isPlusAt(now) ?? false)) {
    // Frozen for 2 weeks after YumSum Star ends, then the plain plan.
    if (profile.adaptiveKcal == 0 ||
        AdaptiveFormula.frozen(endedAt: entitlement?.endedAt(now), now: now)) {
      return;
    }
    await profiles.createProfile(
      AdaptiveFormula.replanned(
        profile,
        0,
        now: now,
      ).copyWith(adaptiveNote: AdaptiveNote.off.value),
    );
    await summaryService.recomputeForDate(uid, today);
    return;
  }
  final monday = AdaptiveFormula.mondayOf(now);
  final week = AdaptiveFormula.dateKey(monday);
  if (profile.adaptiveWeek == week) return;
  // Just subscribed, or back after a lapse or a reset: this Monday only
  // starts the record, so the first change is always on a Monday.
  if (profile.adaptiveWeek == null ||
      profile.adaptiveNote == AdaptiveNote.off.value) {
    await profiles.createProfile(
      profile.copyWith(
        adaptiveWeek: week,
        adaptiveNote: AdaptiveNote.learning.value,
        updatedAt: now,
      ),
    );
    return;
  }

  final entries = await ref
      .read(weightEntryRepositoryProvider)
      .fetchEntries(uid);
  final summaries = await ref
      .read(dailySummaryRepositoryProvider)
      .fetchSummariesInRange(
        uid,
        startDate: AdaptiveFormula.dateKey(
          DateTime(
            monday.year,
            monday.month,
            monday.day - AdaptiveFormula.maxWindowDays,
          ),
        ),
        endDate: AdaptiveFormula.dateKey(
          DateTime(monday.year, monday.month, monday.day - 1),
        ),
      );
  final result = AdaptiveFormula.monday(
    profile: profile,
    entries: entries,
    summaries: summaries,
    monday: monday,
  );

  final moved = result.adjustment != profile.adaptiveKcal;
  var updated = moved
      ? AdaptiveFormula.replanned(profile, result.adjustment, now: now)
      : profile.copyWith(updatedAt: now);
  final from = profile.dailyCalorieTarget.round();
  final to = updated.dailyCalorieTarget.round();
  final changes = [
    ...profile.adaptiveChanges,
    (week: week, from: from, to: to),
  ];
  updated = updated.copyWith(
    adaptiveWeek: week,
    adaptiveNote: result.note.value,
    // The newest 6.
    adaptiveChanges: to == from
        ? null
        : changes.sublist(math.max(0, changes.length - 6)),
  );
  await profiles.createProfile(updated);
  if (moved) await summaryService.recomputeForDate(uid, today);

  final m = result.measure;
  debugPrint(
    'Adaptive: $week ${result.note.value}, gap ${m.gap.round()}, '
    'confidence ${m.confidence.toStringAsFixed(2)}, aim ${result.aim}, '
    'step ${result.step}, adjustment ${result.adjustment}, target $to '
    '(${m.weighIns} weigh-ins, ${m.daysLogged} days)',
  );
  if (kDebugMode) {
    debugPrint(adaptiveReplayJson(profile, entries, summaries, monday));
  }
});

/// After Reset progress or Reset all data: the adjustment goes back to 0,
/// since the data it learnt from is gone.
Future<void> resetAdaptive(Ref ref, String uid) async {
  final profile = await ref
      .read(userProfileRepositoryProvider)
      .fetchProfile(uid);
  if (profile == null) return;
  final now = DateTime.now();
  await ref
      .read(userProfileRepositoryProvider)
      .createProfile(
        AdaptiveFormula.replanned(
          profile,
          0,
          now: now,
        ).copyWith(adaptiveNote: AdaptiveNote.off.value),
      );
  await ref
      .read(dailySummaryServiceProvider)
      .recomputeForDate(uid, AdaptiveFormula.dateKey(now));
}

/// The window's data as JSON, for `test/adaptive_replay_test.dart` (copy it
/// from the debug log into `config/adaptive_replay.json`). One item a line,
/// so the log doesn't cut it.
String adaptiveReplayJson(
  UserProfile profile,
  List<WeightEntry> entries,
  List<DailySummary> summaries,
  DateTime monday,
) {
  final start = AdaptiveFormula.dateKey(
    DateTime(monday.year, monday.month, monday.day - 49),
  );
  final details = jsonEncode({
    'monday': AdaptiveFormula.dateKey(monday),
    'createdAt': AdaptiveFormula.dateKey(profile.createdAt),
    'adaptiveFrom': profile.adaptiveFrom,
    'age': profile.age,
    'gender': profile.gender.value,
    'heightCm': profile.heightCm,
    'currentWeightKg': profile.currentWeightKg,
    'targetWeightKg': profile.targetWeightKg,
    'activityLevel': profile.activityLevel.value,
    'trainingFrequency': profile.trainingFrequency.value,
    'weightLossPace': profile.weightLossPace.value,
  });
  final weighIns = [
    for (final entry in entries)
      if (entry.dateKey.compareTo(start) >= 0)
        jsonEncode({'date': entry.dateKey, 'kg': entry.weightKg}),
  ];
  final days = [
    for (final summary in summaries)
      jsonEncode({
        'date': summary.date,
        'kcal': summary.totalCalories,
        'target': summary.targetCalories,
      }),
  ];
  return '{"profile": $details,\n'
      '"weighIns": [\n${weighIns.join(',\n')}\n],\n'
      '"days": [\n${days.join(',\n')}\n]}';
}

/// What the formula knows so far, measured up to yesterday, for Plan
/// Settings.
final adaptiveProgressProvider = FutureProvider.autoDispose<AdaptiveMeasure?>((
  ref,
) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  final entries = await ref.watch(weightEntriesProvider.future);
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final summaries = await ref
      .watch(dailySummaryRepositoryProvider)
      .fetchSummariesInRange(
        uid,
        startDate: AdaptiveFormula.dateKey(
          DateTime(
            now.year,
            now.month,
            now.day - AdaptiveFormula.maxWindowDays,
          ),
        ),
        endDate: AdaptiveFormula.dateKey(yesterday),
      );
  return AdaptiveFormula.measure(
    profile: profile,
    entries: entries,
    summaries: summaries,
    end: yesterday,
  );
});

/// The Adaptive formula's line on Today, or null for none.
final adaptiveTodayLineProvider = Provider.autoDispose<String?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null || !ref.watch(plusProvider)) return null;
  return adaptiveTodayLine(
    profile,
    ref.watch(l10nProvider),
    lastWeighIn: ref.watch(latestWeightEntryProvider).valueOrNull?.date,
    now: DateTime.now(),
  );
});

/// This week's Monday result, from Monday to Sunday, as one short line; a
/// pause shows as soon as the last weigh-in is 10 days old. Nothing while
/// learning. Amounts are the target minus the plan's, so they match Plan
/// Settings.
String? adaptiveTodayLine(
  UserProfile profile,
  AppLocalizations l10n, {
  required DateTime? lastWeighIn,
  required DateTime now,
}) {
  if (lastWeighIn != null &&
      AdaptiveFormula.daysBetween(lastWeighIn, now) >=
          AdaptiveFormula.pausedDays) {
    return l10n.adaptivePaused;
  }
  if (profile.adaptiveWeek !=
      AdaptiveFormula.dateKey(AdaptiveFormula.mondayOf(now))) {
    return null;
  }
  final plan = AdaptiveFormula.planOf(profile, now: now);
  final amount =
      plan.dailyCalorieTarget.round() - plan.planCalorieTarget.round();
  final signed = amount < 0 ? '−${-amount}' : '+$amount';
  final note = AdaptiveNote.fromString(profile.adaptiveNote);
  final atMinimum =
      plan.calorieTargetClamped &&
      profile.adaptiveKcal < 0 &&
      !plan.isMaintaining;
  if (atMinimum &&
      (note == AdaptiveNote.lowered ||
          note == AdaptiveNote.raised ||
          note == AdaptiveNote.steady)) {
    return l10n.adaptiveAtMinimum(l10n.dayMonth(plan.targetDate));
  }
  return switch (note) {
    AdaptiveNote.lowered => l10n.adaptiveLowered(signed),
    AdaptiveNote.raised => l10n.adaptiveRaised(signed),
    AdaptiveNote.firstSign => l10n.adaptiveFirstSign,
    AdaptiveNote.steady when amount != 0 => l10n.adaptiveSteadyAdjusted(signed),
    AdaptiveNote.steady => l10n.adaptiveSteady,
    AdaptiveNote.fewWeighIns => l10n.adaptiveFewWeighIns,
    AdaptiveNote.fewDays => l10n.adaptiveFewDays,
    AdaptiveNote.unusual => l10n.adaptiveUnusual,
    _ => null,
  };
}

/// While YumSum Star has ended and the adjustment is frozen: the day the
/// target goes back to the standard plan. Null otherwise.
final adaptiveLapseProvider = Provider.autoDispose<DateTime?>((ref) {
  final entitlement = ref.watch(entitlementProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (!entitlement.hasValue || profile == null || profile.adaptiveKcal == 0) {
    return null;
  }
  final now = DateTime.now();
  if (entitlement.value?.isPlusAt(now) ?? false) return null;
  final ended = entitlement.value?.endedAt(now);
  if (!AdaptiveFormula.frozen(endedAt: ended, now: now)) return null;
  return AdaptiveFormula.lapseEnd(ended!);
});

/// The sum the Adaptive formula makes: "1670 from your plan − 80 adaptive =
/// 1590 kcal", for Plan Settings and Weight & Progress.
String adaptiveSumLine(HealthPlanCalculation preview, AppLocalizations l10n) {
  final plan = preview.planCalorieTarget.round();
  final target = preview.dailyCalorieTarget.round();
  final amount = target - plan;
  final sign = amount < 0 ? '−' : '+';
  return preview.calorieTargetClamped
      ? l10n.adaptiveSumMinimum(plan, sign, amount.abs(), target)
      : l10n.adaptiveSum(plan, sign, amount.abs(), target);
}

/// What you burn a day, to the nearest 10: what it has measured once it
/// can, before that the burn your target assumes (the formula's, plus any
/// adjustment).
int adaptiveBurn(UserProfile profile, AdaptiveMeasure? measure) {
  final burn = measure != null && measure.hold == null
      ? measure.burn
      : AdaptiveFormula.planOf(profile).tdee + profile.adaptiveKcal;
  return (burn / 10).round() * 10;
}

/// The one stage worth a line, as it asks for something: paused, for want
/// of a weigh-in. Null otherwise.
String? adaptivePausedLine(AdaptiveMeasure measure, AppLocalizations l10n) =>
    measure.stage == AdaptiveStage.paused ? l10n.adaptivePaused : null;
