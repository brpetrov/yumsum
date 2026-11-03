import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';

import 'adaptive_fixtures.dart';

class _FakeProfiles extends Fake implements UserProfileRepository {
  UserProfile? saved;

  @override
  Future<void> createProfile(UserProfile profile) async => saved = profile;
}

class _FakeSummaryService extends Fake implements DailySummaryService {
  @override
  Future<void> recomputeForDate(String uid, String date) async {}
}

void main() {
  final profile = planProfile(
    adaptiveKcal: -80,
    adaptiveWeek: '2026-11-30',
    adaptiveNote: 'lowered',
  );
  late _FakeProfiles profiles;

  Future<UserProfile> save({
    double weightKg = 79.8,
    WeightLossPace pace = WeightLossPace.fast,
    TrainingFrequency training = TrainingFrequency.threeToFour,
    bool adaptiveOn = true,
  }) async {
    profiles = _FakeProfiles();
    final container = ProviderContainer(
      overrides: [
        currentUidProvider.overrideWithValue('user-1'),
        userProfileRepositoryProvider.overrideWithValue(profiles),
        dailySummaryServiceProvider.overrideWithValue(_FakeSummaryService()),
      ],
    );
    addTearDown(container.dispose);
    final saved = await container
        .read(profileControllerProvider.notifier)
        .saveProfile(
          currentProfile: profile,
          name: profile.name,
          age: profile.age,
          gender: profile.gender,
          heightCm: profile.heightCm,
          currentWeightKg: weightKg,
          targetWeightKg: profile.targetWeightKg,
          activityLevel: profile.activityLevel,
          trainingFrequency: training,
          weightLossPace: pace,
          country: profile.country,
          usualFood: profile.usualFood,
          trackProtein: profile.trackProtein,
          adaptiveOn: adaptiveOn,
        );
    expect(saved, isTrue);
    return profiles.saved!;
  }

  test('a new weight or pace keeps the adjustment and applies it', () async {
    final saved = await save(weightKg: 79, pace: WeightLossPace.moderate);
    expect(saved.adaptiveKcal, -80);
    expect(saved.adaptiveNote, 'lowered');
    expect(saved.adaptiveWeek, '2026-11-30');
    expect(
      saved.dailyCalorieTarget,
      closeTo(
        AdaptiveFormula.planOf(saved, adaptiveKcal: 0).dailyCalorieTarget - 80,
        1e-9,
      ),
    );
  });

  test('switching it off goes back to the plain plan', () async {
    final saved = await save(adaptiveOn: false);
    expect(saved.adaptiveOn, isFalse);
    expect(saved.adaptiveKcal, 0);
    expect(saved.adaptiveNote, 'off');
    expect(
      saved.dailyCalorieTarget,
      AdaptiveFormula.planOf(profile, adaptiveKcal: 0).dailyCalorieTarget,
    );
  });

  test('new training starts it again from today', () async {
    final saved = await save(training: TrainingFrequency.fivePlus);
    expect(saved.adaptiveKcal, 0);
    expect(saved.adaptiveNote, 'learning');
    expect(saved.adaptiveFrom, AdaptiveFormula.dateKey(DateTime.now()));
  });
}
