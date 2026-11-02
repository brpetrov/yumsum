import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/plus_prompt_card.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> pumpCard(
    WidgetTester tester, {
    Entitlement? entitlement,
    Map<String, Object> saved = const {},
  }) async {
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: PlusPromptCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what YumSum Star adds to someone without it', (tester) async {
    await pumpCard(tester);
    expect(find.byType(PlusMark), findsOneWidget);
    expect(find.textContaining('Photo logging'), findsOneWidget);
  });

  testWidgets('not for someone who has YumSum Star', (tester) async {
    await pumpCard(
      tester,
      entitlement: const Entitlement(
        active: true,
        source: EntitlementSource.manual,
      ),
    );
    expect(find.byType(PlusMark), findsNothing);
  });

  testWidgets('the cross hides it for two weeks', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byTooltip('Hide for now'));
    await tester.pumpAndSettle();
    expect(find.byType(PlusMark), findsNothing);
    final until = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(plusPromptHiddenKey)!,
    );
    expect(until.difference(DateTime.now()).inDays, 13);

    await pumpCard(
      tester,
      saved: {plusPromptHiddenKey: until.millisecondsSinceEpoch},
    );
    expect(find.byType(PlusMark), findsNothing);
  });
}
