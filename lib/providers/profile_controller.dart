import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> saveProfile({
    required UserProfile currentProfile,
    required String name,
    required int age,
    required Gender gender,
    required double heightCm,
    required double currentWeightKg,
    required double? targetWeightKg,
    required ActivityLevel activityLevel,
    required TrainingFrequency trainingFrequency,
    required WeightLossPace weightLossPace,
    required String country,
    required String usualFood,
    required bool trackProtein,
  }) async {
    state = const AsyncLoading();

    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      // The Adaptive formula: new details or activity start its learning
      // again from today, so an old correction never double-counts or
      // fights a real change.
      var adaptiveKcal = currentProfile.adaptiveKcal;
      var adaptiveNote = currentProfile.adaptiveNote;
      var adaptiveFrom = currentProfile.adaptiveFrom;
      final detailsChanged =
          age != currentProfile.age ||
          gender != currentProfile.gender ||
          heightCm != currentProfile.heightCm ||
          activityLevel != currentProfile.activityLevel ||
          trainingFrequency != currentProfile.trainingFrequency;
      if (detailsChanged) {
        adaptiveKcal = 0;
        adaptiveNote = AdaptiveNote.learning.value;
        if (adaptiveFrom == null || adaptiveFrom.compareTo(today) < 0) {
          adaptiveFrom = today;
        }
      }
      final plan = HealthCalculator.calculatePlan(
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        heightCm: heightCm,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        trainingFrequency: trainingFrequency,
        weightLossPace: weightLossPace,
        adaptiveKcal: adaptiveKcal.toDouble(),
      );

      final updatedProfile = currentProfile.copyWith(
        name: name.trim(),
        country: country.trim(),
        usualFood: usualFood.trim(),
        trackProtein: trackProtein,
        age: age,
        gender: gender,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        targetWeightKg: plan.targetWeightKg,
        activityLevel: activityLevel,
        trainingFrequency: trainingFrequency,
        activityScaleVersion: currentActivityScaleVersion,
        planCalculationVersion: currentPlanCalculationVersion,
        weightLossPace: weightLossPace,
        targetDate: plan.targetDate,
        bmi: plan.bmi,
        bmr: plan.bmr,
        tdee: plan.tdee,
        dailyCalorieTarget: plan.dailyCalorieTarget,
        goalPaceKgPerWeek: plan.goalPaceKgPerWeek,
        goalPaceLevel: plan.goalPaceLevel,
        adaptiveKcal: adaptiveKcal,
        adaptiveNote: adaptiveNote,
        adaptiveFrom: adaptiveFrom,
        updatedAt: now,
      );

      await ref
          .read(userProfileRepositoryProvider)
          .createProfile(updatedProfile);

      await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, today);

      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);
