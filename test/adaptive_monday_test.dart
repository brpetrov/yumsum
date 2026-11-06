import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';
import 'package:lean_streak/repositories/weight_entry_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';

import 'adaptive_fixtures.dart';

class _FakeProfiles extends Fake implements UserProfileRepository {
  _FakeProfiles(this.server);

  /// The server's copy, which the run decides from.
  final UserProfile server;
  final saved = <UserProfile>[];

  @override
  Future<UserProfile?> fetchProfile(String uid) async => server;

  @override
  Future<void> createProfile(UserProfile profile) async => saved.add(profile);
}

class _FakeSummaryService extends Fake implements DailySummaryService {
  final recomputed = <String>[];

  @override
  Future<void> recomputeForDate(String uid, String date) async =>
      recomputed.add(date);
}

class _FakeWeighIns extends Fake implements WeightEntryRepository {
  _FakeWeighIns(this.entries);

  final List<WeightEntry> entries;

  @override
  Future<List<WeightEntry>> fetchEntries(String uid) async => entries;
}

class _FakeSummaries extends Fake implements DailySummaryRepository {
  _FakeSummaries(this.summaries);

  final List<DailySummary> summaries;

  @override
  Future<List<DailySummary>> fetchSummariesInRange(
    String uid, {
    required String startDate,
    required String endDate,
  }) async => [
    for (final summary in summaries)
      if (summary.date.compareTo(startDate) >= 0 &&
          summary.date.compareTo(endDate) <= 0)
        summary,
  ];
}

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

void main() {
  final now = DateTime.now();
  final monday = AdaptiveFormula.mondayOf(now);
  final thisWeek = AdaptiveFormula.dateKey(monday);
  final lastWeek = AdaptiveFormula.dateKey(
    DateTime(monday.year, monday.month, monday.day - 7),
  );
  late _FakeProfiles profiles;
  late _FakeSummaryService summaryService;

  /// Runs the Monday run once for [profile], with 4 weeks of data from
  /// someone burning 227 less than the formula says. [cached] is what the
  /// phone's stream shows first, the server's copy by default.
  Future<void> run(
    UserProfile profile, {
    Entitlement? entitlement,
    UserProfile? cached,
  }) async {
    final data = simulate(
      Scenario(
        profile: planProfile(),
        start: DateTime(monday.year, monday.month, monday.day - 28),
        weeks: 4,
        burnOffset: -227,
        intake: 1830,
      ),
    );
    profiles = _FakeProfiles(profile);
    summaryService = _FakeSummaryService();
    final container = ProviderContainer(
      overrides: [
        currentUidProvider.overrideWithValue('user-1'),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(cached ?? profile),
        ),
        entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
        userProfileRepositoryProvider.overrideWithValue(profiles),
        dailySummaryServiceProvider.overrideWithValue(summaryService),
        weightEntryRepositoryProvider.overrideWithValue(
          _FakeWeighIns(data.entries),
        ),
        dailySummaryRepositoryProvider.overrideWithValue(
          _FakeSummaries(data.summaries),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(adaptiveMondayProvider, (_, _) {});
    await container.read(adaptiveMondayProvider.future);
  }

  group('subscribed', () {
    test('acts once a week: lowered after last Monday\'s first sign', () async {
      final profile = planProfile(
        adaptiveWeek: lastWeek,
        adaptiveNote: 'first_sign',
      );
      await run(profile, entitlement: _plus);
      final saved = profiles.saved.single;
      expect(saved.adaptiveWeek, thisWeek);
      expect(saved.adaptiveNote, 'lowered');
      // As far as the fast pace allows.
      expect(saved.adaptiveKcal, -50);
      expect(
        saved.dailyCalorieTarget,
        closeTo(profile.dailyCalorieTarget - 50, 1e-9),
      );
      expect(saved.adaptiveChanges, [
        (
          week: thisWeek,
          from: profile.dailyCalorieTarget.round(),
          to: saved.dailyCalorieTarget.round(),
        ),
      ]);
      expect(summaryService.recomputed, [AdaptiveFormula.dateKey(now)]);
    });

    test('a week already done, on this phone or another, is left', () async {
      await run(
        planProfile(adaptiveWeek: thisWeek, adaptiveNote: 'steady'),
        entitlement: _plus,
      );
      expect(profiles.saved, isEmpty);
    });

    test('decides from the server, not a stale cached copy', () async {
      await run(
        planProfile(adaptiveWeek: thisWeek, adaptiveNote: 'steady'),
        entitlement: _plus,
        cached: planProfile(adaptiveWeek: lastWeek, adaptiveNote: 'first_sign'),
      );
      expect(profiles.saved, isEmpty);
    });

    test('never run, or back after a lapse: this Monday only starts', () async {
      for (final profile in [
        planProfile(),
        planProfile(adaptiveWeek: lastWeek, adaptiveNote: 'off'),
      ]) {
        await run(profile, entitlement: _plus);
        final saved = profiles.saved.single;
        expect(saved.adaptiveWeek, thisWeek);
        expect(saved.adaptiveNote, 'learning');
        expect(saved.adaptiveKcal, 0);
        expect(summaryService.recomputed, isEmpty);
      }
    });

    test('the owner\'s admin account counts as subscribed', () async {
      await run(
        planProfile(),
        entitlement: const Entitlement(
          active: false,
          source: EntitlementSource.manual,
          admin: true,
        ),
      );
      expect(profiles.saved.single.adaptiveNote, 'learning');
    });
  });

  group('when YumSum Star ends', () {
    final adjusted = planProfile(
      adaptiveKcal: -80,
      adaptiveWeek: lastWeek,
      adaptiveNote: 'lowered',
    );
    Entitlement endedDaysAgo(int days) => Entitlement(
      active: false,
      source: EntitlementSource.play,
      endedAt: DateTime(now.year, now.month, now.day - days, now.hour),
    );

    test('the adjustment is frozen for 2 weeks, with no Monday step', () async {
      await run(adjusted, entitlement: endedDaysAgo(9));
      expect(profiles.saved, isEmpty);
    });

    test('then it goes back to the plain plan', () async {
      await run(adjusted, entitlement: endedDaysAgo(14));
      final saved = profiles.saved.single;
      expect(saved.adaptiveKcal, 0);
      expect(saved.adaptiveNote, 'off');
      expect(
        saved.dailyCalorieTarget,
        AdaptiveFormula.planOf(adjusted, adaptiveKcal: 0).dailyCalorieTarget,
      );
      expect(summaryService.recomputed, [AdaptiveFormula.dateKey(now)]);
    });

    test('without an end date, at once', () async {
      await run(adjusted);
      expect(profiles.saved.single.adaptiveKcal, 0);
    });

    test('with no adjustment, nothing to do', () async {
      await run(planProfile(adaptiveWeek: lastWeek));
      expect(profiles.saved, isEmpty);
    });
  });
}
