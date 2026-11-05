import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/user_profile.dart';

final _now = DateTime(2026, 11, 2);
final _profile = UserProfile(
  uid: 'user-1',
  email: 'a@b.com',
  name: 'Test',
  age: 29,
  gender: Gender.male,
  heightCm: 170,
  currentWeightKg: 79.8,
  targetWeightKg: 73,
  activityLevel: ActivityLevel.lightlyActive,
  trainingFrequency: TrainingFrequency.threeToFour,
  activityScaleVersion: currentActivityScaleVersion,
  planCalculationVersion: currentPlanCalculationVersion,
  weightLossPace: WeightLossPace.fast,
  targetDate: _now,
  bmi: 27.6,
  bmr: 1720,
  tdee: 2495,
  dailyCalorieTarget: 1670,
  goalPaceKgPerWeek: 0.75,
  goalPaceLevel: GoalPaceLevel.caution,
  onboardingCompleted: true,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  test('a profile from before the Adaptive formula gets its defaults', () {
    final stored = _profile.toFirestore()
      ..removeWhere((key, _) => key.startsWith('adaptive'));
    final profile = UserProfile.fromMap(stored);
    expect(profile.adaptiveKcal, 0);
    expect(profile.adaptiveWeek, isNull);
    expect(profile.adaptiveNote, isNull);
    expect(profile.adaptiveFrom, isNull);
    expect(profile.adaptiveChanges, isEmpty);
  });

  test('the Adaptive formula\'s fields survive a save and a load', () {
    final adapted = _profile.copyWith(
      adaptiveKcal: -80,
      adaptiveWeek: '2026-11-30',
      adaptiveNote: 'lowered',
      adaptiveFrom: '2026-11-16',
      adaptiveChanges: [(week: '2026-11-30', from: 1648, to: 1568)],
    );
    final stored = adapted.toFirestore();
    final profile = UserProfile.fromMap(stored);
    expect(profile.adaptiveKcal, -80);
    expect(profile.adaptiveWeek, '2026-11-30');
    expect(profile.adaptiveNote, 'lowered');
    expect(profile.adaptiveFrom, '2026-11-16');
    expect(profile.adaptiveChanges, [
      (week: '2026-11-30', from: 1648, to: 1568),
    ]);
  });

  test('reads while a save waits for the server to stamp updatedAt', () {
    // Until the server replies, a server timestamp reads as null.
    final stored = _profile.toFirestore()..['updatedAt'] = null;
    final before = DateTime.now();
    final profile = UserProfile.fromMap(stored);
    expect(profile.name, 'Test');
    expect(profile.updatedAt.isBefore(before), isFalse);
  });

  test('unset dates and notes are left out of the document', () {
    final stored = _profile.toFirestore();
    expect(stored.containsKey('adaptiveWeek'), isFalse);
    expect(stored.containsKey('adaptiveNote'), isFalse);
    expect(stored.containsKey('adaptiveFrom'), isFalse);
  });
}
