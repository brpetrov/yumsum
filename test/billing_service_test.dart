import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:lean_streak/services/billing_service.dart';

PricingPhaseWrapper _phase(String period, int micros, String price) =>
    PricingPhaseWrapper(
      billingCycleCount: micros == 0 ? 1 : 0,
      billingPeriod: period,
      formattedPrice: price,
      priceAmountMicros: micros,
      priceCurrencyCode: 'GBP',
      recurrenceMode: micros == 0
          ? RecurrenceMode.finiteRecurring
          : RecurrenceMode.infiniteRecurring,
    );

SubscriptionOfferDetailsWrapper _offer(
  String basePlan,
  String? offerId,
  List<PricingPhaseWrapper> phases,
) => SubscriptionOfferDetailsWrapper(
  basePlanId: basePlan,
  offerId: offerId,
  offerTags: const [],
  offerIdToken: '$basePlan-${offerId ?? 'base'}',
  pricingPhases: phases,
);

/// Play's answer for yumsum_plus, as the plugin splits it: one entry per
/// base plan and per offer the account can have.
List<GooglePlayProductDetails> _play(
  List<SubscriptionOfferDetailsWrapper> offers,
) => GooglePlayProductDetails.fromProductDetails(
  ProductDetailsWrapper(
    description: '',
    name: 'YumSum Star',
    productId: plusProductId,
    productType: ProductType.subs,
    subscriptionOfferDetails: offers,
    title: 'YumSum Star',
  ),
);

void main() {
  final monthly = _phase('P1M', 2990000, '£2.99');
  final annual = _phase('P1Y', 17990000, '£17.99');
  final freeWeek = _phase('P1W', 0, 'Free');

  test('a new account gets each plan with its free week, yearly first', () {
    final plans = starPlansFrom(
      _play([
        _offer('monthly', null, [monthly]),
        _offer('monthly', 'monthly-trial', [freeWeek, monthly]),
        _offer('annual', null, [annual]),
        _offer('annual', 'annual-trial', [_phase('P7D', 0, 'Free'), annual]),
      ]),
    );

    expect([for (final p in plans) p.yearly], [true, false]);
    expect([for (final p in plans) p.price], ['£17.99', '£2.99']);
    expect([for (final p in plans) p.micros], [17990000, 2990000]);
    expect([for (final p in plans) p.trialDays], [7, 7]);
    // Buying it buys the trial offer.
    expect(
      [
        for (final p in plans)
          (p.product as GooglePlayProductDetails).offerToken,
      ],
      ['annual-annual-trial', 'monthly-monthly-trial'],
    );
  });

  test('an account that had the trial gets the base plans', () {
    final plans = starPlansFrom(
      _play([
        _offer('annual', null, [annual]),
        _offer('monthly', null, [monthly]),
      ]),
    );

    expect([for (final p in plans) p.trialDays], [null, null]);
    expect(
      [
        for (final p in plans)
          (p.product as GooglePlayProductDetails).offerToken,
      ],
      ['annual-base', 'monthly-base'],
    );
  });

  test('a missing plan is left out', () {
    final plans = starPlansFrom(
      _play([
        _offer('monthly', null, [monthly]),
      ]),
    );
    expect(plans.single.yearly, isFalse);
  });
}
