import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/day_off_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';

final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  return DailySummaryRepository(FirebaseFirestore.instance);
});

final dailySummaryServiceProvider = Provider<DailySummaryService>((ref) {
  return DailySummaryService(
    mealRepository: ref.watch(mealRepositoryProvider),
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    dailySummaryRepository: ref.watch(dailySummaryRepositoryProvider),
    dayOffRepository: ref.watch(dayOffRepositoryProvider),
  );
});

final dayOffRepositoryProvider = Provider<DayOffRepository>((ref) {
  return DayOffRepository(FirebaseFirestore.instance);
});

/// Whether [date] (yyyy-MM-dd) is a day off, known even before any meal
/// gives it a summary.
final dayOffProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  date,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(dayOffRepositoryProvider).watch(uid, date);
});

final dailySummaryForDateProvider = StreamProvider.autoDispose
    .family<DailySummary?, String>((ref, date) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return Stream.value(null);
      return ref.watch(dailySummaryRepositoryProvider).watchSummary(uid, date);
    });
