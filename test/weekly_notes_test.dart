import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/review/weekly_notes.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

final _monday = DateTime(2026, 10, 26);

const _notes = [
  'Weekdays were steady at about 1,890 kcal, but the weekend averaged 2,580.',
  'Your first meal of the day averaged 14 g of protein. A "Greek yoghurt '
      'berry bowl" gives 30 g for 332 kcal.',
  'Salt averaged 7.4 g against the 6 g guide.',
];

void main() {
  late int reads;

  /// [notes] is what each read of the notes gives, in turn; a [Completer]
  /// keeps it loading and an [Exception] fails it.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Entitlement? entitlement = _plus,
    List<Object> notes = const [_notes],
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    reads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          weeklyReviewProvider.overrideWith((ref, monday) async {
            final result = notes[reads++ % notes.length];
            return switch (result) {
              final Completer<List<String>> wait => wait.future,
              final Exception error => throw error,
              _ => result as List<String>,
            };
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [child],
                  ),
                ),
              ),
              GoRoute(
                path: AppRoutes.plus,
                builder: (_, _) => const Scaffold(body: Text('The paywall')),
              ),
            ],
          ),
        ),
      ),
    );
    // A spinner never settles; two frames bring the account and the notes.
    settle ? await tester.pumpAndSettle() : await tester.pump();
    await tester.pump();
  }

  Widget card({int judgedDays = 6}) =>
      WeeklyNotesCard(monday: _monday, judgedDays: judgedDays);

  group('with YumSum Star', () {
    testWidgets('the notes and the footer', (tester) async {
      await pump(tester, card());
      expect(find.text('AI Coach'), findsOneWidget);
      // Each number keeps its unit on its line.
      expect(
        find.text(
          'Weekdays were steady at about 1,890\u00A0kcal, but the weekend '
          'averaged 2,580.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your first meal of the day averaged 14\u00A0g of protein. A '
          '"Greek yoghurt berry bowl" gives 30\u00A0g for 332\u00A0kcal.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Salt averaged 7.4\u00A0g against the 6\u00A0g guide.'),
        findsOneWidget,
      );
      expect(find.text('Written by AI from what you logged.'), findsOneWidget);
      expect(reads, 1);
    });

    testWidgets('the info button explains it, with Close only', (tester) async {
      await pump(tester, card());
      await tester.tap(find.byTooltip('How it works'));
      await tester.pumpAndSettle();
      expect(find.text('Your week, read for you'), findsOneWidget);
      expect(find.text('Spots your patterns'), findsOneWidget);
      expect(find.text('Ready every Monday'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Enable'), findsNothing);
    });

    testWidgets('a thin week says why, and never asks for notes', (
      tester,
    ) async {
      await pump(tester, card(judgedDays: 3));
      expect(
        find.text(
          'Not enough logged this week for notes. They need 4 days logged, '
          'not counting days off.',
        ),
        findsOneWidget,
      );
      expect(reads, 0);
    });

    testWidgets('while it writes: Looking over your week', (tester) async {
      final wait = Completer<List<String>>();
      await pump(tester, card(), notes: [wait], settle: false);
      expect(find.text('Looking over your week'), findsOneWidget);
      wait.complete(_notes);
      await tester.pumpAndSettle();
      expect(find.textContaining('Weekdays were steady'), findsOneWidget);
    });

    testWidgets('a failure says so, and Try again asks again', (tester) async {
      await pump(tester, card(), notes: [Exception('busy'), _notes]);
      expect(
        find.text('Could not get this week\'s notes. Try again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.textContaining('Weekdays were steady'), findsOneWidget);
    });
  });

  group('without YumSum Star', () {
    testWidgets('the AI Coach button opens the dialog, Enable the paywall', (
      tester,
    ) async {
      await pump(tester, card(), entitlement: null);
      expect(
        find.text(
          'See what\'s working, what\'s holding you back, and one easy fix '
          'for next\u00A0week.',
        ),
        findsOneWidget,
      );
      expect(reads, 0);
      expect(find.byType(PlusStar), findsNothing);

      await tester.tap(find.text('AI Coach'));
      await tester.pumpAndSettle();
      expect(find.text('Looks past calories'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();
      expect(find.text('The paywall'), findsOneWidget);
    });

    testWidgets('the line under it opens the dialog too', (tester) async {
      await pump(tester, card(), entitlement: null);
      await tester.tap(find.textContaining('See what\'s working'));
      await tester.pumpAndSettle();
      expect(find.text('Your week, read for you'), findsOneWidget);
    });

    testWidgets('nothing for a thin week', (tester) async {
      await pump(tester, card(judgedDays: 3), entitlement: null);
      expect(find.text('AI Coach'), findsNothing);
    });
  });
}
