import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';
import 'package:lean_streak/repositories/weight_entry_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';
import 'package:lean_streak/services/weight_log_service.dart';

class _FakeWeightEntryRepository extends Fake implements WeightEntryRepository {
  WeightEntry? saved;
  String? deleted;

  @override
  Future<void> upsertEntry(String uid, WeightEntry entry) async {
    saved = entry;
  }

  @override
  Future<void> deleteEntry(String uid, String dateKey) async {
    deleted = dateKey;
  }
}

WeightEntry _entry(String day, double kg) => WeightEntry(
  dateKey: day,
  weightKg: kg,
  loggedAt: DateTime.parse(day),
  source: WeightSource.manual,
);

class _FakeUserProfileRepository extends Fake implements UserProfileRepository {
  UserProfile? saved;

  @override
  Future<void> createProfile(UserProfile profile) async {
    saved = profile;
  }
}

class _FakeDailySummaryService extends Fake implements DailySummaryService {
  final List<String> recomputed = [];

  @override
  Future<void> recomputeForDate(String uid, String date) async {
    recomputed.add(date);
  }
}

UserProfile _profile() {
  final now = DateTime(2026, 6, 7);
  final plan = HealthCalculator.calculatePlan(
    currentWeightKg: 90,
    targetWeightKg: 80,
    heightCm: 180,
    age: 30,
    gender: Gender.male,
    activityLevel: ActivityLevel.lightlyActive,
    trainingFrequency: TrainingFrequency.oneToTwo,
    weightLossPace: WeightLossPace.moderate,
    now: now,
  );

  return UserProfile(
    uid: 'user-1',
    email: 'a@b.com',
    name: 'Test',
    age: 30,
    gender: Gender.male,
    heightCm: 180,
    currentWeightKg: 90,
    targetWeightKg: 80,
    activityLevel: ActivityLevel.lightlyActive,
    trainingFrequency: TrainingFrequency.oneToTwo,
    activityScaleVersion: currentActivityScaleVersion,
    planCalculationVersion: currentPlanCalculationVersion,
    weightLossPace: WeightLossPace.moderate,
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
}

void main() {
  group('WeightLogService', () {
    late _FakeWeightEntryRepository weightRepo;
    late _FakeUserProfileRepository profileRepo;
    late _FakeDailySummaryService summaryService;
    late WeightLogService service;

    setUp(() {
      weightRepo = _FakeWeightEntryRepository();
      profileRepo = _FakeUserProfileRepository();
      summaryService = _FakeDailySummaryService();
      service = WeightLogService(
        weightEntryRepository: weightRepo,
        userProfileRepository: profileRepo,
        dailySummaryService: summaryService,
      );
    });

    test('stores the entry with the given source and date key', () async {
      await service.logWeight(
        profile: _profile(),
        weightKg: 88,
        source: WeightSource.checkIn,
        at: DateTime(2026, 6, 7, 9, 30),
      );

      expect(weightRepo.saved, isNotNull);
      expect(weightRepo.saved!.dateKey, '2026-06-07');
      expect(weightRepo.saved!.weightKg, 88);
      expect(weightRepo.saved!.source, WeightSource.checkIn);
    });

    test('recalculates the plan and saves the updated profile', () async {
      final profile = _profile();
      final result = await service.logWeight(
        profile: profile,
        weightKg: 85,
        source: WeightSource.manual,
        at: DateTime(2026, 6, 7),
      );

      final expected = HealthCalculator.calculatePlan(
        currentWeightKg: 85,
        targetWeightKg: 80,
        heightCm: 180,
        age: 30,
        gender: Gender.male,
        activityLevel: ActivityLevel.lightlyActive,
        trainingFrequency: TrainingFrequency.oneToTwo,
        weightLossPace: WeightLossPace.moderate,
        now: DateTime(2026, 6, 7),
      );

      expect(profileRepo.saved, isNotNull);
      expect(profileRepo.saved!.currentWeightKg, 85);
      expect(
        profileRepo.saved!.dailyCalorieTarget,
        expected.dailyCalorieTarget,
      );
      expect(result.previousCalorieTarget, profile.dailyCalorieTarget.round());
      expect(result.newCalorieTarget, expected.dailyCalorieTarget.round());
    });

    test('refreshes the daily summary for the logged day', () async {
      await service.logWeight(
        profile: _profile(),
        weightKg: 86,
        source: WeightSource.manual,
        at: DateTime(2026, 6, 7),
      );

      expect(summaryService.recomputed, ['2026-06-07']);
    });

    test('a lower weight lowers the calorie target', () async {
      final result = await service.logWeight(
        profile: _profile(),
        weightKg: 80,
        source: WeightSource.manual,
        at: DateTime(2026, 6, 7),
      );

      expect(result.newCalorieTarget, lessThan(result.previousCalorieTarget));
      expect(result.targetChanged, isTrue);
    });

    group('deleting a weigh-in', () {
      final entries = [_entry('2026-06-01', 85), _entry('2026-06-07', 90)];

      test('the newest takes the plan back to the one before', () async {
        final result = await service.deleteEntry(
          profile: _profile(),
          entries: entries,
          entry: entries.last,
          at: DateTime(2026, 6, 8),
        );

        expect(weightRepo.deleted, '2026-06-07');
        expect(profileRepo.saved!.currentWeightKg, 85);
        expect(
          result!.newCalorieTarget,
          lessThan(result.previousCalorieTarget),
        );
        expect(summaryService.recomputed, ['2026-06-08']);
      });

      test('an older one leaves the plan alone', () async {
        final result = await service.deleteEntry(
          profile: _profile(),
          entries: entries,
          entry: entries.first,
        );

        expect(weightRepo.deleted, '2026-06-01');
        expect(result, isNull);
        expect(profileRepo.saved, isNull);
        expect(summaryService.recomputed, isEmpty);
      });

      test('the only one leaves the plan alone', () async {
        final result = await service.deleteEntry(
          profile: _profile(),
          entries: [entries.last],
          entry: entries.last,
        );

        expect(weightRepo.deleted, '2026-06-07');
        expect(result, isNull);
        expect(profileRepo.saved, isNull);
      });
    });
  });
}
