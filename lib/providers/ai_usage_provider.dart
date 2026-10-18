import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

final aiUsageRepositoryProvider = Provider<AiUsageRepository>((ref) {
  return AiUsageRepository(FirebaseFirestore.instance);
});

final calorieEstimateServiceProvider = Provider<CalorieEstimateService>((ref) {
  final profile = ref.watch(
    userProfileProvider.select((value) => value.valueOrNull),
  );
  return CalorieEstimateService(
    ref.watch(aiUsageRepositoryProvider),
    country: profile?.country ?? defaultCountry,
    usualFood: profile?.usualFood ?? '',
  );
});

/// Streams today's AI estimate usage count for the current user.
/// Emits 0 while loading or if the user is unauthenticated.
final aiUsageTodayProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.watch(aiUsageRepositoryProvider).watchCount(uid, today);
});
