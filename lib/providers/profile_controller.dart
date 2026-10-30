import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

      final plan = HealthCalculator.calculatePlan(
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        heightCm: heightCm,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        trainingFrequency: trainingFrequency,
        weightLossPace: weightLossPace,
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
        updatedAt: DateTime.now(),
      );

      await ref
          .read(userProfileRepositoryProvider)
          .createProfile(updatedProfile);

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
