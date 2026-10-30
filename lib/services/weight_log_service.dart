import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';
import 'package:lean_streak/repositories/weight_entry_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';

/// Outcome of logging a weight — carries the saved profile and the calorie
/// target before/after recalculation so the UI can tell the user what changed.
class WeightLogResult {
  const WeightLogResult({
    required this.profile,
    required this.previousCalorieTarget,
    required this.newCalorieTarget,
  });

  final UserProfile profile;
  final int previousCalorieTarget;
  final int newCalorieTarget;

  bool get targetChanged => previousCalorieTarget != newCalorieTarget;
}

/// Records a weight reading and automatically recomputes the user's plan
/// (calorie target, BMR/TDEE, target date) from the new weight; deleting the
/// newest one takes the plan back to the one before.
class WeightLogService {
  WeightLogService({
    required WeightEntryRepository weightEntryRepository,
    required UserProfileRepository userProfileRepository,
    required DailySummaryService dailySummaryService,
  }) : _weightEntryRepository = weightEntryRepository,
       _userProfileRepository = userProfileRepository,
       _dailySummaryService = dailySummaryService;

  final WeightEntryRepository _weightEntryRepository;
  final UserProfileRepository _userProfileRepository;
  final DailySummaryService _dailySummaryService;

  Future<WeightLogResult> logWeight({
    required UserProfile profile,
    required double weightKg,
    required WeightSource source,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    await _weightEntryRepository.upsertEntry(
      profile.uid,
      WeightEntry(
        dateKey: dateKey,
        weightKg: weightKg,
        loggedAt: now,
        source: source,
      ),
    );
    return _replan(profile, weightKg, now);
  }

  /// Deletes one weigh-in from [entries] (oldest first). When it was the
  /// newest and an older one is left, the plan goes back to that weight and
  /// the change is returned; otherwise the plan stays and this returns null.
  Future<WeightLogResult?> deleteEntry({
    required UserProfile profile,
    required List<WeightEntry> entries,
    required WeightEntry entry,
    DateTime? at,
  }) async {
    await _weightEntryRepository.deleteEntry(profile.uid, entry.dateKey);
    if (entries.length < 2 || entries.last.dateKey != entry.dateKey) {
      return null;
    }
    final previous = entries[entries.length - 2];
    return _replan(profile, previous.weightKg, at ?? DateTime.now());
  }

  Future<WeightLogResult> _replan(
    UserProfile profile,
    double weightKg,
    DateTime now,
  ) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    // Recalculate the plan from the new weight, keeping every other input
    // (height, age, gender, activity, pace) as the user last set it.
    final plan = HealthCalculator.calculatePlan(
      currentWeightKg: weightKg,
      targetWeightKg: profile.targetWeightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      gender: profile.gender,
      activityLevel: profile.activityLevel,
      trainingFrequency: profile.trainingFrequency,
      weightLossPace: profile.weightLossPace,
      now: now,
    );

    final previousTarget = profile.dailyCalorieTarget.round();

    final updatedProfile = profile.copyWith(
      currentWeightKg: weightKg,
      targetWeightKg: plan.targetWeightKg,
      targetDate: plan.targetDate,
      bmi: plan.bmi,
      bmr: plan.bmr,
      tdee: plan.tdee,
      dailyCalorieTarget: plan.dailyCalorieTarget,
      goalPaceKgPerWeek: plan.goalPaceKgPerWeek,
      goalPaceLevel: plan.goalPaceLevel,
      updatedAt: now,
    );

    await _userProfileRepository.createProfile(updatedProfile);

    // The target may have shifted, so refresh today's status.
    await _dailySummaryService.recomputeForDate(profile.uid, dateKey);

    return WeightLogResult(
      profile: updatedProfile,
      previousCalorieTarget: previousTarget,
      newCalorieTarget: plan.dailyCalorieTarget.round(),
    );
  }
}
