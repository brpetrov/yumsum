import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/coach/coach_screen.dart';
import 'package:lean_streak/widgets/period_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recipe_fixtures.dart';

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

const _notes = <ReviewPoint>[
  (
    title: 'Weekends run high',
    text:
        'Weekdays were steady at about 1,890 kcal, but the weekend averaged '
        '2,580.',
    good: false,
  ),
  (
    title: 'A light first meal',
    text:
        'Your first meal of the day averaged 14 g of protein. A "Greek '
        'yoghurt berry bowl" gives 30 g for 332 kcal.',
    good: false,
  ),
  (
    title: 'Salt over the guide',
    text: 'Salt averaged 7.4 g against the 6 g guide.',
    good: false,
  ),
  (title: 'Fibre on track', text: 'Fibre met the guide all week.', good: true),
];

String _key(DateTime day) =>
    '${day.year}-${'${day.month}'.padLeft(2, '0')}-'
    '${'${day.day}'.padLeft(2, '0')}';

/// The dots before the notes, by colour.
Finder _dots(Color color) => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).color == color,
);

bool _enabled(WidgetTester tester, IconData icon) =>
    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, icon))
        .onPressed !=
    null;

const _previous = Icons.chevron_left_rounded;
const _next = Icons.chevron_right_rounded;

void main() {
  late int reads;
  late List<DateTime> asked;

  /// The page on [week]. [notes] is what each read of the notes gives, in
  /// turn; a [Completer] keeps it loading and an [Exception] fails it.
  /// Every week has [judgedDays] logged, and [recipes] is the library.
  Future<void> pump(
    WidgetTester tester, {
    String? week = '2026-10-26',
    Entitlement? entitlement = _plus,
    List<Object> notes = const [_notes],
    int judgedDays = 6,
    List<Recipe> recipes = const [],
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    reads = 0;
    asked = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          recipesProvider.overrideWith((ref) async => recipes),
          // A Wednesday, so the first week is the one of 12 October.
          firstLoggedDayProvider.overrideWith(
            (ref) async => DateTime(2026, 10, 14),
          ),
          weeklyReviewProvider.overrideWith((ref, monday) async {
            asked.add(monday);
            final result = notes[reads++ % notes.length];
            return switch (result) {
              final Completer<List<ReviewPoint>> wait => wait.future,
              final Exception error => throw error,
              _ => result as List<ReviewPoint>,
            };
          }),
          reviewSummariesProvider.overrideWith(
            (ref, range) => Stream.value({
              for (var day = 0; day < judgedDays; day++)
                if (DateTime(
                      range.startDate.year,
                      range.startDate.month,
                      range.startDate.day + day,
                    )
                    case final date)
                  _key(date): DailySummary(
                    date: _key(date),
                    totalCalories: 1900,
                    targetCalories: 1900,
                    calorieDelta: 0,
                    mealCount: 3,
                    status: DailyStatus.green,
                    updatedAt: date,
                  ),
            }),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: week == null
                ? AppRoutes.coach
                : '${AppRoutes.coach}?week=$week',
            routes: [
              GoRoute(
                path: AppRoutes.coach,
                builder: (_, state) =>
                    CoachScreen(week: state.uri.queryParameters['week']),
              ),
              GoRoute(
                path: AppRoutes.plus,
                builder: (_, _) => const Scaffold(body: Text('The paywall')),
              ),
              GoRoute(
                path: AppRoutes.recipe,
                builder: (_, state) => Scaffold(
                  body: Text('Recipe ${state.pathParameters['id']}'),
                ),
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

  test('the latest finished week is last week', () {
    expect(latestFinishedWeek(DateTime(2026, 11, 5)), DateTime(2026, 10, 26));
    expect(latestFinishedWeek(DateTime(2026, 11, 2)), DateTime(2026, 10, 26));
    expect(latestFinishedWeek(DateTime(2026, 11, 1)), DateTime(2026, 10, 19));
  });

  group('with YumSum Star', () {
    testWidgets('the notes, with their titles', (tester) async {
      await pump(tester);
      expect(find.text('26 Oct – 1 Nov 2026'), findsOneWidget);
      expect(find.text('Weekends run high'), findsOneWidget);
      // Each number keeps its unit on its line.
      expect(
        find.text(
          'Weekdays were steady at about 1,890 kcal, but the weekend '
          'averaged 2,580.',
        ),
        findsOneWidget,
      );
      expect(find.text('A light first meal'), findsOneWidget);
      expect(
        find.text(
          'Your first meal of the day averaged 14 g of protein. A '
          '"Greek yoghurt berry bowl" gives 30 g for 332 kcal.',
        ),
        findsOneWidget,
      );
      expect(find.text('Fibre on track'), findsOneWidget);
      expect(find.text('Fibre met the guide all week.'), findsOneWidget);
      expect(reads, 1);
      expect(asked, [DateTime(2026, 10, 26)]);
    });

    testWidgets('a note on something that went well has a green dot', (
      tester,
    ) async {
      await pump(tester);
      expect(_dots(AppColors.veryGood), findsOneWidget);
      expect(_dots(AppColors.primary), findsNWidgets(3));
    });

    testWidgets('a recipe in a note is an underlined link to it, without '
        'the quotes', (tester) async {
      await pump(tester, recipes: [testRecipe('Greek yoghurt berry bowl')]);
      // The AI's quotes round the name are gone.
      expect(
        find.textContaining('A Greek yoghurt berry bowl gives'),
        findsOneWidget,
      );
      expect(find.textContaining('"Greek'), findsNothing);

      TextSpan? link;
      tester
          .widget<Text>(find.textContaining('Greek yoghurt berry bowl'))
          .textSpan!
          .visitChildren((span) {
            if (span is TextSpan && span.text == 'Greek yoghurt berry bowl') {
              link = span;
            }
            return true;
          });
      expect(link!.style!.decoration, TextDecoration.underline);

      await tester.tapOnText(
        find.textRange.ofSubstring('Greek yoghurt berry bowl'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recipe greek-yoghurt-berry-bowl'), findsOneWidget);
    });

    testWidgets('the info button explains it, with Close only', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('How it works'));
      await tester.pumpAndSettle();
      expect(find.text('Your week, read for you'), findsOneWidget);
      expect(find.text('Detects your patterns'), findsOneWidget);
      expect(find.text('Fresh every Monday'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Enable'), findsNothing);
    });

    testWidgets('a thin week says why, and never asks for notes', (
      tester,
    ) async {
      await pump(tester, judgedDays: 3);
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
      final wait = Completer<List<ReviewPoint>>();
      await pump(tester, notes: [wait], settle: false);
      expect(find.text('Looking over your week'), findsOneWidget);
      wait.complete(_notes);
      await tester.pumpAndSettle();
      expect(find.text('Weekends run high'), findsOneWidget);
    });

    testWidgets('a failure says so, and Try again asks again', (tester) async {
      await pump(tester, notes: [Exception('busy'), _notes]);
      expect(
        find.text('Could not get this week\'s notes. Try again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('Weekends run high'), findsOneWidget);
    });

    testWidgets('Previous and Next page through the finished weeks, back to '
        'the first logged one; Latest returns', (tester) async {
      await pump(tester);
      final latest = latestFinishedWeek(DateTime.now());

      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('19 – 25 Oct 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('12 – 18 Oct 2026'), findsOneWidget);
      expect(_enabled(tester, _previous), isFalse);
      expect(asked, [
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 12),
      ]);

      await tester.tap(find.text('Latest'));
      await tester.pumpAndSettle();
      expect(find.text(weekLabel(latest)), findsOneWidget);
      expect(find.text('Latest'), findsNothing);
      expect(_enabled(tester, _next), isFalse);
      expect(_enabled(tester, _previous), isTrue);
    });

    testWidgets('an unknown or unfinished week opens the latest', (
      tester,
    ) async {
      final latest = latestFinishedWeek(DateTime.now());
      await pump(tester, week: 'not a date');
      expect(find.text(weekLabel(latest)), findsOneWidget);

      final thisMonday = DateTime(latest.year, latest.month, latest.day + 7);
      await pump(tester, week: _key(thisMonday));
      expect(find.text(weekLabel(latest)), findsOneWidget);

      await pump(tester, week: null);
      expect(find.text(weekLabel(latest)), findsOneWidget);
    });
  });

  group('without YumSum Star', () {
    testWidgets('what it does, and Enable opens the paywall', (tester) async {
      await pump(tester, entitlement: null);
      expect(find.text('Your week, read for you'), findsOneWidget);
      expect(find.text('Detects your patterns'), findsOneWidget);
      expect(find.text('Looks past calories'), findsOneWidget);
      expect(find.text('Tips written for you'), findsOneWidget);
      expect(find.text('Fresh every Monday'), findsOneWidget);
      expect(find.byTooltip('How it works'), findsNothing);
      expect(find.byTooltip('Previous'), findsNothing);
      expect(reads, 0);

      await tester.ensureVisible(find.text('Enable'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();
      expect(find.text('The paywall'), findsOneWidget);
    });
  });
}
