import 'package:cloud_functions/cloud_functions.dart';

/// The billing Cloud Functions (`functions/`), which check purchases with
/// Google Play and write `entitlements/{uid}`, a record the app can only
/// read.
class BillingRepository {
  BillingRepository(this._functions);

  final FirebaseFunctions _functions;

  /// Has the server check a Play purchase with Google and write the
  /// account's record, which switches YumSum Star on. Throws a
  /// [FirebaseFunctionsException], `already-exists` when the purchase
  /// belongs to another account.
  Future<void> verify(String purchaseToken) => _functions
      .httpsCallable('verifyPurchase')
      .call<Object?>({'purchaseToken': purchaseToken});

  /// Deletes the account's YumSum Star record and its Play purchase links,
  /// before the account itself goes. It doesn't cancel the subscription.
  Future<void> deleteBillingData() =>
      _functions.httpsCallable('deleteBillingData').call<Object?>({});
}
