import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/repositories/entitlement_repository.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository(FirebaseFirestore.instance);
});

/// The account's YumSum+ details (state, dates), or null if it never had it.
final entitlementProvider = StreamProvider.autoDispose<Entitlement?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(entitlementRepositoryProvider).watch(uid);
});

/// Whether the signed-in account has YumSum+ now. Gates read it as
/// `ref.watch(plusProvider).valueOrNull ?? false`, so they stay shut while
/// it loads.
final plusProvider = StreamProvider.autoDispose<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return ref
      .watch(entitlementRepositoryProvider)
      .watch(uid)
      .map((e) => e?.isPlusAt(DateTime.now()) ?? false);
});
