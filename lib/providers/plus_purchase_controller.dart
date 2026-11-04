import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/services/billing_service.dart';

const playUnreachable =
    'Could not reach Google Play. Check your connection and try again.';
const purchaseNotConfirmed =
    'Could not confirm your purchase. Try Restore purchase in a few '
    'minutes. If it still fails, Google Play refunds you automatically '
    'within 3 days.';
const purchaseOnAnotherAccount =
    'This Google Play subscription is linked to another YumSum account. '
    'Sign in with that account to use it.';
const nothingToRestore =
    'No YumSum Star subscription found on this Google account.';
const paymentPending =
    'Google Play is waiting for your payment. YumSum Star switches on once '
    'it goes through.';

/// Where buying YumSum Star is: [checking] the purchase with the server, or
/// a [message] for the YumSum Star page to show.
class PlusPurchase {
  const PlusPurchase({this.checking = false, this.message});

  final bool checking;
  final String? message;
}

/// Buys and restores YumSum Star on Android, and hands every purchase Play
/// reports to the server to check (`BillingRepository.verify`); YumSum Star
/// then switches on through the account's record. It listens for the app's
/// whole life (started from `LeanStreakApp`), as the plugin asks, so a
/// payment that goes through later is still picked up.
final plusPurchaseControllerProvider =
    NotifierProvider<PlusPurchaseController, PlusPurchase>(
      PlusPurchaseController.new,
    );

class PlusPurchaseController extends Notifier<PlusPurchase> {
  /// A restore waiting for Play's list: true for the quiet one at start-up,
  /// false for Restore purchase.
  bool? _restoring;
  String? _restoredFor;

  @override
  PlusPurchase build() {
    if (!playBilling) return const PlusPurchase();
    final purchases = ref
        .watch(billingServiceProvider)
        .purchases
        .listen(_onPurchases);
    ref.onDispose(purchases.cancel);
    // Once per account, signed in without YumSum Star, a quiet restore
    // picks up a purchase whose check never finished (the app closed
    // straight after paying, or the signal dropped) within Play's 3 days.
    ref.listen(realEntitlementProvider, (_, next) {
      final uid = ref.read(currentUidProvider);
      if (uid == null || uid == _restoredFor || next.isLoading) return;
      if (!next.hasValue || (next.value?.isPlusAt(DateTime.now()) ?? false)) {
        return;
      }
      _restoredFor = uid;
      _restore(quiet: true);
    }, fireImmediately: true);
    return const PlusPurchase();
  }

  /// Opens Play's purchase sheet; what happens next arrives as a purchase.
  Future<void> buy(StarPlan plan) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    state = const PlusPurchase();
    try {
      // Play asks for a hash rather than the account's own ID.
      await ref
          .read(billingServiceProvider)
          .buy(plan, account: sha256.convert(utf8.encode(uid)).toString());
    } catch (error) {
      debugPrint('Could not start the purchase: $error');
      _say(playUnreachable);
    }
  }

  /// Restore purchase on the YumSum Star page.
  Future<void> restore() => _restore(quiet: false);

  Future<void> _restore({required bool quiet}) async {
    _restoring = quiet;
    try {
      await ref.read(billingServiceProvider).restore();
    } catch (error) {
      _restoring = null;
      debugPrint('Could not restore purchases: $error');
      if (!quiet) _say(playUnreachable);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final quiet = _restoring ?? false;
    if (_restoring == false && !purchases.any(_isOurs)) {
      _say(nothingToRestore);
    }
    _restoring = null;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          if (_isOurs(purchase)) await _verify(purchase, quiet: quiet);
        case PurchaseStatus.pending:
          _say(paymentPending);
        case PurchaseStatus.error:
          debugPrint('Purchase failed: ${purchase.error}');
          if (alreadyOwned(purchase)) {
            await restore();
          } else {
            _say(playUnreachable);
          }
        case PurchaseStatus.canceled:
          state = const PlusPurchase();
      }
    }
  }

  bool _isOurs(PurchaseDetails purchase) =>
      purchase.productID == plusProductId &&
      (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored);

  Future<void> _verify(PurchaseDetails purchase, {required bool quiet}) async {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) return;
    if (!quiet) state = const PlusPurchase(checking: true);
    try {
      await ref.read(billingRepositoryProvider).verify(token);
    } catch (error) {
      debugPrint('Could not check the purchase: $error');
      if (quiet) return;
      final linked =
          error is FirebaseFunctionsException && error.code == 'already-exists';
      _say(linked ? purchaseOnAnotherAccount : purchaseNotConfirmed);
      return;
    }
    if (!quiet) state = const PlusPurchase();
    if (purchase.pendingCompletePurchase) {
      await ref
          .read(billingServiceProvider)
          .complete(purchase)
          .catchError(
            (Object error) => debugPrint('Could not complete it: $error'),
          );
    }
  }

  void _say(String message) => state = PlusPurchase(message: message);
}
