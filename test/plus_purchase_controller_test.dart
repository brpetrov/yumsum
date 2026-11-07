import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/plus_purchase_controller.dart';

import 'billing_fixtures.dart';

void main() {
  late FakeBillingService play;
  late FakeBillingRepository server;

  /// The controller for account `u1`, with [entitlement] as its record and
  /// [restorable] in Play.
  ProviderContainer start({
    Entitlement? entitlement,
    String? uid = 'u1',
    List<PurchaseDetails> restorable = const [],
  }) {
    play = FakeBillingService()..restorable = restorable;
    server = FakeBillingRepository();
    final container = ProviderContainer(
      overrides: [
        billingServiceProvider.overrideWithValue(play),
        billingRepositoryProvider.overrideWithValue(server),
        currentUidProvider.overrideWithValue(uid),
        realEntitlementProvider.overrideWith(
          (ref) => Stream.value(entitlement),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(plusPurchaseControllerProvider, (_, _) {});
    return container;
  }

  PlusPurchase stateOf(ProviderContainer c) =>
      c.read(plusPurchaseControllerProvider);

  /// Lets the purchase stream and the checks run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a purchase is checked by the server, then completed', () async {
    final c = start();
    await settle();
    play.send([purchase(PurchaseStatus.purchased)]);
    await settle();

    expect(server.verified, ['token-1']);
    expect(play.completed, hasLength(1));
    expect(stateOf(c).checking, isFalse);
    expect(stateOf(c).message, isNull);
  });

  test('says checking while the server looks', () async {
    final c = start();
    await settle();
    final states = <bool>[];
    c.listen(plusPurchaseControllerProvider, (_, next) {
      states.add(next.checking);
    });
    play.send([purchase(PurchaseStatus.purchased)]);
    await settle();
    expect(states, [true, false]);
  });

  test('a failed check says so and leaves the purchase for Play', () async {
    final c = start();
    await settle();
    server.error = Exception('down');
    play.send([purchase(PurchaseStatus.purchased)]);
    await settle();

    expect(stateOf(c).message, PurchaseMessage.notConfirmed);
    expect(play.completed, isEmpty);
  });

  test("a purchase on another account says so", () async {
    final c = start();
    await settle();
    server.error = FirebaseFunctionsException(
      message: 'linked',
      code: 'already-exists',
    );
    play.send([purchase(PurchaseStatus.purchased)]);
    await settle();

    expect(stateOf(c).message, PurchaseMessage.onAnotherAccount);
  });

  test('a pending payment grants nothing yet', () async {
    final c = start();
    await settle();
    play.send([purchase(PurchaseStatus.pending)]);
    await settle();

    expect(server.verified, isEmpty);
    expect(stateOf(c).message, PurchaseMessage.paymentPending);
  });

  test('buying hashes the account for Play', () async {
    final c = start();
    await settle();
    await c.read(plusPurchaseControllerProvider.notifier).buy(starPlans()[0]);

    final (plan, account) = play.bought.single;
    expect(plan.yearly, isTrue);
    expect(account, sha256.convert(utf8.encode('u1')).toString());
    expect(account, hasLength(64));
  });

  test('Restore purchase checks what Play finds', () async {
    final c = start(
      entitlement: const Entitlement(
        active: true,
        source: EntitlementSource.manual,
      ),
      restorable: [purchase(PurchaseStatus.restored)],
    );
    await settle();
    await c.read(plusPurchaseControllerProvider.notifier).restore();
    await settle();

    expect(server.verified, ['token-1']);
    expect(stateOf(c).message, isNull);
  });

  test('Restore purchase says when Play finds nothing', () async {
    final c = start();
    await settle();
    await c.read(plusPurchaseControllerProvider.notifier).restore();
    await settle();

    expect(stateOf(c).message, PurchaseMessage.nothingToRestore);
  });

  test('already owned in Play restores instead', () async {
    final c = start(
      entitlement: const Entitlement(
        active: true,
        source: EntitlementSource.manual,
      ),
      restorable: [purchase(PurchaseStatus.restored)],
    );
    await settle();
    play.send([
      purchase(PurchaseStatus.error, product: '')
        ..error = IAPError(
          source: 'google_play',
          code: 'purchase_error',
          message: 'BillingResponse.itemAlreadyOwned',
        ),
    ]);
    await settle();

    expect(play.restores, 1);
    expect(server.verified, ['token-1']);
    expect(stateOf(c).message, isNull);
  });

  test('closing Play\'s sheet says nothing', () async {
    final c = start();
    await settle();
    play.send([purchase(PurchaseStatus.canceled, product: '')]);
    await settle();

    expect(stateOf(c).message, isNull);
    expect(server.verified, isEmpty);
  });

  group('at start-up', () {
    test('restores quietly once, without YumSum Star', () async {
      final c = start(restorable: [purchase(PurchaseStatus.restored)]);
      // A purchase found whose check fails stays quiet.
      server.error = Exception('down');
      await settle();

      expect(play.restores, 1);
      expect(server.verified, ['token-1']);
      expect(stateOf(c).message, isNull);
      expect(stateOf(c).checking, isFalse);
    });

    test('says nothing when the quiet restore finds nothing', () async {
      final c = start();
      await settle();
      expect(play.restores, 1);
      expect(stateOf(c).message, isNull);
    });

    test('leaves it alone with YumSum Star, or signed out', () async {
      start(
        entitlement: const Entitlement(
          active: true,
          source: EntitlementSource.manual,
        ),
      );
      await settle();
      expect(play.restores, 0);

      start(uid: null);
      await settle();
      expect(play.restores, 0);
    });
  });
}
