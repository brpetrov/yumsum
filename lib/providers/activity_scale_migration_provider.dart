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

  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return;
  final activityScaleCurrent =
      profile.activityScaleVersion >= currentActivityScaleVersion;
  final planCalculationCurrent =
      profile.planCalculationVersion >= currentPlanCalculationVersion;
  if (activityScaleCurrent && planCalculationCurrent) return;

  final migratedProfile = _migrateProfile(profile);
  await ref.read(userProfileRepositoryProvider).createProfile(migratedProfile);

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, today);
});

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
