import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
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

DailySummary _logged(String date, {bool dayOff = false}) => DailySummary(
  date: date,
  totalCalories: 1900,
  targetCalories: 1900,
  calorieDelta: 0,
  mealCount: 3,
  status: DailyStatus.green,
  dayOff: dayOff,
  updatedAt: DateTime(2026, 11, 2),
);

void main() {
  late SharedPreferences prefs;
  late int reads;
  late Object? opened;

  /// [notes] is what each read of the notes gives, in turn; a [Completer]
  /// keeps it loading and an [Exception] fails it.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Entitlement? entitlement = _plus,
    List<Object> notes = const [_notes],
    Map<String, DailySummary> lastWeek = const {},
    Map<String, Object> saved = const {},
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    reads = 0;
    opened = null;
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
          reviewSummariesProvider.overrideWith((ref, range) async => lastWeek),
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
              GoRoute(
                path: AppRoutes.review,
                builder: (_, state) {
                  opened = state.extra;
                  return const Scaffold(body: Text('History'));
                },
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
    testWidgets('the notes and the footer, and Today\'s line can go', (
      tester,
    ) async {
      await pump(tester, card());
      expect(find.text('AI Coach'), findsOneWidget);
      for (final note in _notes) {
        expect(find.text(note), findsOneWidget);
      }
      expect(find.text('Written by AI from what you logged.'), findsOneWidget);
      expect(reads, 1);
      expect(prefs.getString(weeklyReviewSeenKey), '2026-10-26');
    });

    testWidgets('seen only moves on, never back to an older week', (
      tester,
    ) async {
      await pump(
        tester,
        card(),
        saved: const {weeklyReviewSeenKey: '2026-11-02'},
      );
      expect(prefs.getString(weeklyReviewSeenKey), '2026-11-02');
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
      expect(find.text(_notes.first), findsOneWidget);
    });

    testWidgets('a failure says so, and Try again asks again', (tester) async {
      await pump(tester, card(), notes: [Exception('busy'), _notes]);
      expect(
        find.text('Could not get this week\'s notes. Try again.'),
        findsOneWidget,
      );
      expect(prefs.getString(weeklyReviewSeenKey), isNull);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text(_notes.first), findsOneWidget);
    });
  });

  group('without YumSum Star', () {
    testWidgets('the AI Coach button opens the dialog, Enable the paywall', (
      tester,
    ) async {
      await pump(tester, card(), entitlement: null);
      expect(
        find.text(
          'Notes on your week every Monday: your patterns, your salt and '
          'fibre, and one easy tip.',
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
      await tester.tap(find.textContaining('Notes on your week'));
      await tester.pumpAndSettle();
      expect(find.text('Your week, read for you'), findsOneWidget);
    });

    testWidgets('nothing for a thin week', (tester) async {
      await pump(tester, card(judgedDays: 3), entitlement: null);
      expect(find.text('AI Coach'), findsNothing);
    });
  });

  group('Today\'s line', () {
    // Wednesday 4 November: last week is 26 October to 1 November.
    final line = WeeklyNotesLine(today: DateTime(2026, 11, 4));
    final fourDays = {
      for (final date in [
        '2026-10-26',
        '2026-10-27',
        '2026-10-28',
        '2026-10-30',
      ])
        date: _logged(date),
      '2026-10-31': _logged('2026-10-31', dayOff: true),
    };

    testWidgets('with 4 judged days last week; a tap opens that week', (
      tester,
    ) async {
      await pump(tester, line, lastWeek: fourDays);
      expect(find.text('Your notes on last week'), findsOneWidget);

      await tester.tap(find.text('AI Coach'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      expect(opened, _monday);
    });

    testWidgets('not with 3, as a day off doesn\'t count', (tester) async {
      await pump(tester, line, lastWeek: {...fourDays}..remove('2026-10-30'));
      expect(find.text('AI Coach'), findsNothing);
    });

    testWidgets('gone once last week\'s notes have been seen', (tester) async {
      await pump(
        tester,
        line,
        lastWeek: fourDays,
        saved: const {weeklyReviewSeenKey: '2026-10-26'},
      );
      expect(find.text('AI Coach'), findsNothing);
    });

    testWidgets('back on a new week, until those are seen', (tester) async {
      await pump(
        tester,
        line,
        lastWeek: fourDays,
        saved: const {weeklyReviewSeenKey: '2026-10-19'},
      );
      expect(find.text('AI Coach'), findsOneWidget);
    });

    testWidgets('never for free users', (tester) async {
      await pump(tester, line, entitlement: null, lastWeek: fourDays);
      expect(find.text('AI Coach'), findsNothing);
    });
  });
}
