import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

final activityScaleMigrationProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;

  final cached = await ref.watch(userProfileProvider.future);
  if (cached == null || _isCurrent(cached)) return;
  // The stream's first value can be this phone's cached copy, and the write
  // replaces the whole profile, so migrate the server's.
  final profile = await ref
      .read(userProfileRepositoryProvider)
      .fetchProfile(uid);
  if (profile == null || _isCurrent(profile)) return;

  final migratedProfile = _migrateProfile(profile);
  await ref.read(userProfileRepositoryProvider).createProfile(migratedProfile);

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, today);
});

bool _isCurrent(UserProfile profile) =>
    profile.activityScaleVersion >= currentActivityScaleVersion &&
    profile.planCalculationVersion >= currentPlanCalculationVersion;

UserProfile _migrateProfile(UserProfile profile) {
  final plan = HealthCalculator.calculatePlan(
    currentWeightKg: profile.currentWeightKg,
    targetWeightKg: profile.targetWeightKg,
    heightCm: profile.heightCm,
    age: profile.age,
    gender: profile.gender,
    activityLevel: profile.activityLevel,
    trainingFrequency: profile.trainingFrequency,
    weightLossPace: profile.weightLossPace,
    adaptiveKcal: profile.adaptiveKcal.toDouble(),
  );

  return profile.copyWith(
    targetWeightKg: plan.targetWeightKg,
    trainingFrequency: profile.trainingFrequency,
    activityScaleVersion: currentActivityScaleVersion,
    planCalculationVersion: currentPlanCalculationVersion,
    targetDate: plan.targetDate,
    bmi: plan.bmi,
    bmr: plan.bmr,
    tdee: plan.tdee,
    dailyCalorieTarget: plan.dailyCalorieTarget,
    goalPaceKgPerWeek: plan.goalPaceKgPerWeek,
    goalPaceLevel: plan.goalPaceLevel,
    updatedAt: DateTime.now(),
  );
}
