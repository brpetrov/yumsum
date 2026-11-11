import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:lean_streak/core/config/crash_reports.dart';
import 'package:lean_streak/l10n/app_localizations.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/services/billing_service.dart';

/// What the YumSum Star page tells the person about a purchase.
enum PurchaseMessage {
  playUnreachable,
  notConfirmed,
  onAnotherAccount,
  nothingToRestore,
  paymentPending;

  String text(AppLocalizations l10n) => switch (this) {
    playUnreachable => l10n.starErrorPlay,
    notConfirmed => l10n.starErrorNotConfirmed,
    onAnotherAccount => l10n.starErrorOtherAccount,
    nothingToRestore => l10n.starNothingToRestore,
    paymentPending => l10n.starPaymentPending,
  };
}

/// Where buying YumSum Star is: [checking] the purchase with the server, or
/// a [message] for the YumSum Star page to show.
class PlusPurchase {
  const PlusPurchase({this.checking = false, this.message});

  final bool checking;
  final PurchaseMessage? message;
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
    } catch (error, stack) {
      reportError(error, stack, 'Start a purchase');
      _say(PurchaseMessage.playUnreachable);
    }
  }

  /// Restore purchase on the YumSum Star page.
  Future<void> restore() => _restore(quiet: false);

  Future<void> _restore({required bool quiet}) async {
    _restoring = quiet;
    try {
      await ref.read(billingServiceProvider).restore();
    } catch (error, stack) {
      _restoring = null;
      reportError(error, stack, 'Restore purchases');
      if (!quiet) _say(PurchaseMessage.playUnreachable);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final quiet = _restoring ?? false;
    if (_restoring == false && !purchases.any(_isOurs)) {
      _say(PurchaseMessage.nothingToRestore);
    }
    _restoring = null;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          if (_isOurs(purchase)) await _verify(purchase, quiet: quiet);
        case PurchaseStatus.pending:
          _say(PurchaseMessage.paymentPending);
        case PurchaseStatus.error:
          if (alreadyOwned(purchase)) {
            await restore();
          } else {
            reportError(
              purchase.error ?? 'No error from Play',
              null,
              'Purchase',
            );
            _say(PurchaseMessage.playUnreachable);
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
    } catch (error, stack) {
      final linked =
          error is FirebaseFunctionsException && error.code == 'already-exists';
      // Paid, but not confirmed: the one to look into first.
      if (!linked) reportError(error, stack, 'Purchase check');
      if (quiet) return;
      _say(
        linked
            ? PurchaseMessage.onAnotherAccount
            : PurchaseMessage.notConfirmed,
      );
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

  void _say(PurchaseMessage message) => state = PlusPurchase(message: message);
}
