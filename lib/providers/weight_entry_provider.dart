import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/weight_entry_repository.dart';
import 'package:lean_streak/services/weight_log_service.dart';

final weightEntryRepositoryProvider = Provider<WeightEntryRepository>((ref) {
  return WeightEntryRepository(FirebaseFirestore.instance);
});

final weightLogServiceProvider = Provider<WeightLogService>((ref) {
  return WeightLogService(
    weightEntryRepository: ref.watch(weightEntryRepositoryProvider),
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    dailySummaryService: ref.watch(dailySummaryServiceProvider),
  );
});

/// Real-time stream of the current user's weight history (oldest first).
final weightEntriesProvider = StreamProvider.autoDispose<List<WeightEntry>>((
  ref,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <WeightEntry>[]);
  return ref.watch(weightEntryRepositoryProvider).watchEntries(uid);
});

/// The newest weigh-in, for Today, without reading the whole history.
final latestWeightEntryProvider = StreamProvider.autoDispose<WeightEntry?>((
  ref,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(weightEntryRepositoryProvider).watchLatestEntry(uid);
});
