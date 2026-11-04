import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// YumSum Star's subscription in Play Console.
const plusProductId = 'yumsum_plus';

/// One way to buy YumSum Star: a base plan, with its free trial when Play
/// offers one to this Google account (once per account).
class StarPlan {
  const StarPlan({
    required this.yearly,
    required this.price,
    required this.micros,
    required this.currency,
    required this.product,
    this.trialDays,
  });

  final bool yearly;

  /// The renewing price, formatted by Play in the buyer's currency: "£2.99".
  final String price;
  final int micros;
  final String currency;

  /// What to buy: the trial offer when there is one, else the base plan.
  final ProductDetails product;

  /// How long the free trial is, when this account can have one.
  final int? trialDays;
}

/// The yearly and monthly plans in Play's answer, yearly first. Play lists
/// each base plan and each offer the account is eligible for; an offer whose
/// first phase is free is the trial.
List<StarPlan> starPlansFrom(Iterable<GooglePlayProductDetails> offers) {
  StarPlan? plan(String basePlan) {
    StarPlan? best;
    for (final product in offers) {
      final offer = product
          .productDetails
          .subscriptionOfferDetails?[product.subscriptionIndex!];
      if (offer == null || offer.basePlanId != basePlan) continue;
      final phases = offer.pricingPhases;
      final renewing = phases.last;
      final trial = phases.length > 1 && phases.first.priceAmountMicros == 0
          ? _days(phases.first.billingPeriod)
          : null;
      if (best != null && (best.trialDays != null || trial == null)) continue;
      best = StarPlan(
        yearly: basePlan == 'annual',
        price: renewing.formattedPrice,
        micros: renewing.priceAmountMicros,
        currency: renewing.priceCurrencyCode,
        product: product,
        trialDays: trial,
      );
    }
    return best;
  }

  return [?plan('annual'), ?plan('monthly')];
}

/// Days in an ISO 8601 period of days or weeks ("P7D", "P1W").
int? _days(String period) {
  final match = RegExp(r'^P(\d+)([DW])$').firstMatch(period);
  if (match == null) return null;
  final count = int.parse(match[1]!);
  return match[2] == 'W' ? count * 7 : count;
}

/// A thin wrapper round Google Play Billing (`in_app_purchase`), Android
/// only: the plans, buying, restoring and the purchase stream. Whether a
/// purchase counts is the server's call (`BillingRepository.verify`).
class BillingService {
  BillingService(this._iap);

  final InAppPurchase _iap;

  /// Every purchase update: new purchases, restored ones, and errors.
  Stream<List<PurchaseDetails>> get purchases => _iap.purchaseStream;

  /// The plans, yearly first. Throws when Play can't be reached or doesn't
  /// list them.
  Future<List<StarPlan>> loadPlans() async {
    if (!await _iap.isAvailable()) {
      throw const BillingUnavailable('Play Billing is not available');
    }
    final response = await _iap.queryProductDetails({plusProductId});
    if (response.error case final error?) {
      throw BillingUnavailable(error.message);
    }
    final plans = starPlansFrom(
      response.productDetails.whereType<GooglePlayProductDetails>(),
    );
    if (plans.length < 2) {
      throw BillingUnavailable('Play listed ${plans.length} plans');
    }
    return plans;
  }

  /// Opens Play's purchase sheet. [account] is a hash of the YumSum
  /// account, which Play uses to spot fraud.
  Future<void> buy(StarPlan plan, {required String account}) =>
      _iap.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: plan.product,
          applicationUserName: account,
        ),
      );

  /// Asks Play for the account's active purchases; they arrive on
  /// [purchases] as restored, as one list (empty when there are none).
  Future<void> restore() => _iap.restorePurchases();

  /// Tells the plugin a purchase is dealt with. The server has acknowledged
  /// it with Play already.
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

/// Play can't be reached, or doesn't list YumSum Star's plans.
class BillingUnavailable implements Exception {
  const BillingUnavailable(this.detail);

  final String detail;

  @override
  String toString() => 'BillingUnavailable: $detail';
}

/// Whether [purchase] failed because the account already has YumSum Star
/// in Play, which a restore picks up instead.
bool alreadyOwned(PurchaseDetails purchase) =>
    purchase.error?.message == BillingResponse.itemAlreadyOwned.toString();
