import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
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
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      final email = ref.read(authStateProvider).valueOrNull?.email ?? '';
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

      final now = DateTime.now();
      final profile = UserProfile(
        uid: uid,
        email: email,
        name: name.trim(),
        country: country.trim(),
        usualFood: usualFood.trim(),
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
        onboardingCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(userProfileRepositoryProvider).createProfile(profile);
    });
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);
