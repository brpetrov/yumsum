import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/plus_purchase_controller.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';

import 'billing_fixtures.dart';

void main() {
  late FakeBillingService play;
  late FakeBillingRepository server;
  late StreamController<Entitlement?> record;

  /// The YumSum Star page over a plain page, so closing it can be seen.
  Future<void> pumpScreen(
    WidgetTester tester,
    Entitlement? entitlement, {
    FakeBillingService? billing,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    play = billing ?? FakeBillingService();
    server = FakeBillingRepository();
    record = StreamController<Entitlement?>.broadcast();
    addTearDown(record.close);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUidProvider.overrideWithValue('u1'),
          billingServiceProvider.overrideWithValue(play),
          billingRepositoryProvider.overrideWithValue(server),
          realEntitlementProvider.overrideWith(
            (ref) => Stream.value(entitlement),
          ),
          entitlementProvider.overrideWith((ref) async* {
            yield entitlement;
            yield* record.stream;
          }),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const PlusScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("offers the free week on both plans, at Play's prices", (
    tester,
  ) async {
    await pumpScreen(tester, null);
    expect(find.text('Smart Snap'), findsOneWidget);
    expect(find.text('AI Coach'), findsOneWidget);
    expect(find.text('Shine bright with these smart perks.'), findsOneWidget);
    expect(find.text('£17.99'), findsOneWidget);
    expect(find.text('Save 50%'), findsOneWidget);
    expect(find.text('£1.50 a month'), findsOneWidget);
    expect(find.text('Start 7 days free'), findsOneWidget);
    expect(
      find.textContaining('7 days free, then £17.99 a year'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Monthly'));
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.textContaining('then £2.99 a month'), findsOneWidget);
  });

  testWidgets('without a free week left, it says Subscribe', (tester) async {
    await pumpScreen(
      tester,
      null,
      billing: FakeBillingService(plans: starPlans(trial: false)),
    );
    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.textContaining('days free'), findsNothing);
    expect(
      find.text(
        '£17.99 a year. Renews every year until you cancel. Cancel any '
        'time in Google Play.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('starting buys the chosen plan, then closes once on', (
    tester,
  ) async {
    await pumpScreen(tester, null);
    await tester.ensureVisible(find.text('Monthly'));
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start 7 days free'));
    await tester.pumpAndSettle();
    expect(play.bought.single.$1.yearly, isFalse);

    // Play says paid; the server checks it and writes the record.
    play.send([purchase(PurchaseStatus.purchased)]);
    await tester.pump();
    expect(server.verified, ['token-1']);
    record.add(
      Entitlement(
        active: true,
        source: EntitlementSource.play,
        inTrial: true,
        expiresAt: DateTime(2026, 11, 11),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlusScreen), findsNothing);
    expect(
      find.text('YumSum Star is on. Your free week ends on 11 November.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed check is explained', (tester) async {
    await pumpScreen(tester, null);
    server.error = Exception('down');
    play.send([purchase(PurchaseStatus.purchased)]);
    await tester.pumpAndSettle();
    expect(find.text(purchaseNotConfirmed), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text(purchaseNotConfirmed), findsNothing);
    expect(find.byType(PlusScreen), findsOneWidget);
  });

  testWidgets('Restore purchase asks Play, and says when it finds none', (
    tester,
  ) async {
    await pumpScreen(tester, null);
    final atStart = play.restores;
    await tester.ensureVisible(find.text('Restore purchase'));
    await tester.tap(find.text('Restore purchase'));
    await tester.pumpAndSettle();
    expect(play.restores, atStart + 1);
    expect(find.text(nothingToRestore), findsOneWidget);
  });

  testWidgets("says so when Play can't be reached, and tries again", (
    tester,
  ) async {
    await pumpScreen(tester, null, billing: FakeBillingService(fails: true));
    expect(find.text(playUnreachable), findsOneWidget);
    expect(find.text('Start 7 days free'), findsNothing);

    play.fails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Start 7 days free'), findsOneWidget);
  });

  testWidgets("on an iPhone it can't be bought yet", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpScreen(tester, null);
    expect(
      find.text('YumSum Star can\'t be bought on iPhone yet.'),
      findsOneWidget,
    );
    expect(find.text('Restore purchase'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets("shows the account's own YumSum Star once it has it", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const Entitlement(active: true, source: EntitlementSource.manual),
    );
    expect(find.text('You\'re already a bright YumSum Star'), findsOneWidget);
    expect(find.text('Everything here is yours.'), findsOneWidget);
    expect(find.text('On'), findsNothing);
    expect(find.text('Start 7 days free'), findsNothing);
  });

  testWidgets('says when a dated YumSum Star ends', (tester) async {
    await pumpScreen(
      tester,
      Entitlement(
        active: true,
        source: EntitlementSource.manual,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
    );
    expect(find.textContaining('On until'), findsOneWidget);
  });
}
