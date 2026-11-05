import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/repositories/billing_repository.dart';
import 'package:lean_streak/repositories/entitlement_repository.dart';
import 'package:lean_streak/services/billing_service.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository(FirebaseFirestore.instance);
});

/// Whether YumSum Star can be bought here: the Android app, through Google
/// Play. The website and an iPhone build only read the account's record.
bool get playBilling =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Google Play Billing; read only where [playBilling].
final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService(InAppPurchase.instance);
});

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(
    FirebaseFunctions.instanceFor(region: 'europe-west10'),
  );
});

/// YumSum Star's plans with Play's own prices, for the YumSum Star page.
final starPlansProvider = FutureProvider.autoDispose<List<StarPlan>>((
  ref,
) async {
  try {
    return await ref.watch(billingServiceProvider).loadPlans();
  } catch (error) {
    debugPrint('Could not load the plans: $error');
    rethrow;
  }
});

/// The account's own record, never a pretend one.
final realEntitlementProvider = StreamProvider<Entitlement?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(entitlementRepositoryProvider).watch(uid);
});

/// Whether Debug tools are on offer: in every debug build, and in any build
/// for a dev account. Read from the real record, so pretending to be
/// another account never hides them.
final debugToolsProvider = Provider<bool>((ref) {
  if (kDebugMode) return true;
  return ref.watch(realEntitlementProvider).valueOrNull?.dev ?? false;
});

/// The account's YumSum Star details (state, dates), or null if it never had it.
/// Debug tools can pretend to be another account.
final entitlementProvider = StreamProvider.autoDispose<Entitlement?>((ref) {
  final pretend = ref.watch(debugToolsProvider)
      ? ref.watch(debugAccountProvider)
      : DebugAccount.real;
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
