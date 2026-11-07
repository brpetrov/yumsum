import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

final aiUsageRepositoryProvider = Provider<AiUsageRepository>((ref) {
  return AiUsageRepository(FirebaseFirestore.instance);
});

final calorieEstimateServiceProvider = Provider<CalorieEstimateService>((ref) {
  return CalorieEstimateService(
    ref.watch(aiUsageRepositoryProvider),
    FirebaseFunctions.instanceFor(region: 'europe-west10'),
    country: ref.watch(countryProvider),
    dailyLimit: ref.watch(aiDailyLimitProvider),
    plus: ref.watch(aiMacrosProvider),
    l10n: ref.watch(l10nProvider),
  );
});

/// Whether AI calls ask for macros: only when the app shows YumSum Star and
/// the account's real record has it, which is what the server checks. Debug
/// tools' pretend account changes what the app shows, never what it asks.
final aiMacrosProvider = Provider.autoDispose<bool>((ref) {
  final real = ref.watch(realEntitlementProvider).valueOrNull;
  return ref.watch(plusProvider) && (real?.isPlusAt(DateTime.now()) ?? false);
});

/// How many AI estimates the user gets a day; null for the owner's admin
/// account, which has no limit.
final aiDailyLimitProvider = Provider.autoDispose<int?>((ref) {
  return ref.watch(adminProvider) ? null : AiUsageRepository.dailyLimit;
});

/// Streams today's AI estimate usage count for the current user.
/// Emits 0 while loading or if the user is unauthenticated.
final aiUsageTodayProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.watch(aiUsageRepositoryProvider).watchCount(uid, today);
});
