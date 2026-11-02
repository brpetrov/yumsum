import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, Entitlement? entitlement) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            entitlementProvider.overrideWith(
              (ref) => Stream.value(entitlement),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const PlusScreen()),
        ),
      );

  testWidgets('lists what YumSum+ adds, not on sale yet', (tester) async {
    await pumpScreen(tester, null);
    await tester.pumpAndSettle();
    expect(find.text('Logging stays free. YumSum+ adds:'), findsOneWidget);
    expect(find.text('Log a meal from a photo of your plate'), findsOneWidget);
    expect(find.textContaining('Adaptive formula'), findsOneWidget);
    expect(find.text('YumSum+ isn\'t on sale yet.'), findsOneWidget);
  });

  testWidgets('shows the account\'s own YumSum+ once it has it', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const Entitlement(active: true, source: EntitlementSource.manual),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your YumSum+'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
    expect(find.text('YumSum+ isn\'t on sale yet.'), findsNothing);
  });
}
