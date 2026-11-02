import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, Entitlement? entitlement) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const PlusScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers the free week on both plans', (tester) async {
    await pumpScreen(tester, null);
    expect(find.text('Smart Snap'), findsOneWidget);
    expect(
      find.text('Log in a snap. Learn what works for you.'),
      findsOneWidget,
    );
    expect(find.text('£17.99'), findsOneWidget);
    expect(find.text('Save 50%'), findsOneWidget);
    expect(find.text('£1.50 a month'), findsOneWidget);
    expect(find.textContaining('then £17.99 a year'), findsOneWidget);
    await tester.ensureVisible(find.text('Monthly'));
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.textContaining('then £2.99 a month'), findsOneWidget);
  });

  testWidgets("it isn't on sale yet, so starting says so", (tester) async {
    await pumpScreen(tester, null);
    await tester.ensureVisible(find.text('Start 7 days free'));
    await tester.tap(find.text('Start 7 days free'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsNothing);
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
