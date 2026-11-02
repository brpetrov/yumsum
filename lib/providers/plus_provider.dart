import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/repositories/entitlement_repository.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository(FirebaseFirestore.instance);
});

/// The account's YumSum Star details (state, dates), or null if it never had it.
/// A debug build can pretend to be another account (the debug tools).
final entitlementProvider = StreamProvider.autoDispose<Entitlement?>((ref) {
  final pretend = ref.watch(debugAccountProvider);
  if (pretend != DebugAccount.real) {
    return Stream.value(pretend.entitlementAt(DateTime.now()));
  }
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(entitlementRepositoryProvider).watch(uid);
});

/// Whether the signed-in account has YumSum Star now. False while the record
/// loads, so a gate never flashes open.
final plusProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(entitlementProvider).valueOrNull?.isPlusAt(DateTime.now()) ??
      false;
});

/// The owner's account, which has every YumSum Star feature and no daily
/// limits. False until the record loads, so the limits hold meanwhile.
final adminProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(entitlementProvider).valueOrNull?.admin ?? false;
});
