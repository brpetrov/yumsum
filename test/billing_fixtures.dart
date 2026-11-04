import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lean_streak/repositories/billing_repository.dart';
import 'package:lean_streak/services/billing_service.dart';

/// YumSum Star's two plans as Play would list them in the UK, with the free
/// week when [trial].
List<StarPlan> starPlans({bool trial = true}) => [
  StarPlan(
    yearly: true,
    price: '£17.99',
    micros: 17990000,
    currency: 'GBP',
    product: _product('annual'),
    trialDays: trial ? 7 : null,
  ),
  StarPlan(
    yearly: false,
    price: '£2.99',
    micros: 2990000,
    currency: 'GBP',
    product: _product('monthly'),
    trialDays: trial ? 7 : null,
  ),
];

ProductDetails _product(String basePlan) => ProductDetails(
  id: plusProductId,
  title: basePlan,
  description: '',
  price: '',
  rawPrice: 0,
  currencyCode: 'GBP',
);

/// A purchase as the plugin reports it.
PurchaseDetails purchase(
  PurchaseStatus status, {
  String token = 'token-1',
  String product = plusProductId,
  bool complete = true,
}) => PurchaseDetails(
  purchaseID: 'GPA.1',
  productID: product,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: token,
    source: 'google_play',
  ),
  transactionDate: null,
  status: status,
)..pendingCompletePurchase = complete;

/// Google Play: the plans it lists, and what was bought, restored and
/// completed. Purchases are sent with [send]; a restore sends [restorable],
/// as one list even when empty, like the plugin.
class FakeBillingService extends Fake implements BillingService {
  FakeBillingService({List<StarPlan>? plans, this.fails = false})
    : plans = plans ?? starPlans();

  final List<StarPlan> plans;
  List<PurchaseDetails> restorable = [];

  /// Play can't be reached.
  bool fails;

  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final bought = <(StarPlan, String)>[];
  final completed = <PurchaseDetails>[];
  int restores = 0;

  void send(List<PurchaseDetails> purchases) => _purchases.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchases => _purchases.stream;

  @override
  Future<List<StarPlan>> loadPlans() async {
    if (fails) throw const BillingUnavailable('offline');
    return plans;
  }

  @override
  Future<void> buy(StarPlan plan, {required String account}) async =>
      bought.add((plan, account));

  @override
  Future<void> restore() async {
    restores++;
    _purchases.add(restorable);
  }

  @override
  Future<void> complete(PurchaseDetails purchase) async =>
      completed.add(purchase);
}

/// The billing functions: the tokens checked, and an error to throw.
class FakeBillingRepository extends Fake implements BillingRepository {
  final verified = <String>[];
  Object? error;
  int deletes = 0;

  @override
  Future<void> verify(String purchaseToken) async {
    verified.add(purchaseToken);
    if (error case final error?) throw error;
  }

  @override
  Future<void> deleteBillingData() async => deletes++;
}
