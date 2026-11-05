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
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/review/weekly_notes.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recipe_fixtures.dart';

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

final _monday = DateTime(2026, 10, 26);

const _notes = <ReviewPoint>[
  (
    text:
        'Weekdays were steady at about 1,890 kcal, but the weekend averaged '
        '2,580.',
    good: false,
  ),
  (
    text:
        'Your first meal of the day averaged 14 g of protein. A "Greek '
        'yoghurt berry bowl" gives 30 g for 332 kcal.',
    good: false,
  ),
  (text: 'Salt averaged 7.4 g against the 6 g guide.', good: false),
  (text: 'Fibre met the guide all week.', good: true),
];

/// The dots before the notes, by colour.
Finder _dots(Color color) => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).color == color,
);

void main() {
  late int reads;

  /// [notes] is what each read of the notes gives, in turn; a [Completer]
  /// keeps it loading and an [Exception] fails it. The week has
  /// [judgedDays] logged, and [recipes] is the library.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          recipesProvider.overrideWith((ref) async => recipes),
          weeklyReviewProvider.overrideWith((ref, monday) async {
            final result = notes[reads++ % notes.length];
            return switch (result) {
              final Completer<List<ReviewPoint>> wait => wait.future,
              final Exception error => throw error,
              _ => result as List<ReviewPoint>,
            };
          }),
          reviewSummariesProvider.overrideWith(
            (ref, range) async => {
              for (var day = 0; day < judgedDays; day++)
                '2026-10-${26 + day}': DailySummary(
                  date: '2026-10-${26 + day}',
                  totalCalories: 1900,
                  targetCalories: 1900,
                  calorieDelta: 0,
                  mealCount: 3,
                  status: DailyStatus.green,
                  updatedAt: DateTime(2026, 11, 2),
                ),
            },
          ),
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

  Widget card({bool named = false}) =>
      WeeklyNotesCard(monday: _monday, named: named);

  group('with YumSum Star', () {
    testWidgets('the notes', (tester) async {
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
      expect(find.text('Fibre met the guide all week.'), findsOneWidget);
      expect(reads, 1);
    });

    testWidgets('a note on something that went well has a green dot', (
      tester,
    ) async {
      await pump(tester, card());
      expect(_dots(AppColors.veryGood), findsOneWidget);
      expect(_dots(AppColors.primary), findsNWidgets(3));
    });

    testWidgets('a recipe in a note is an underlined link to it, without '
        'the quotes', (tester) async {
      await pump(
        tester,
        card(),
        recipes: [testRecipe('Greek yoghurt berry bowl')],
      );
      expect(
        find.text(
          'Your first meal of the day averaged 14 g of protein. A '
          'Greek yoghurt berry bowl gives 30 g for 332 kcal.',
        ),
        findsOneWidget,
      );

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
      await pump(tester, card());
      await tester.tap(find.byTooltip('How it works'));
      await tester.pumpAndSettle();
      expect(find.text('Your week, read for you'), findsOneWidget);
      expect(find.text('Spots your patterns'), findsOneWidget);
      expect(find.text('Fresh every Monday'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Enable'), findsNothing);
    });

    testWidgets('a thin week says why, and never asks for notes', (
      tester,
    ) async {
      await pump(tester, card(), judgedDays: 3);
      expect(
        find.text(
          'Not enough logged this week for notes. They need 4 days logged, '
          'not counting days off.',
        ),
        findsOneWidget,
      );
      expect(reads, 0);
    });

    testWidgets('a week still going says when its notes come', (tester) async {
      final now = DateTime.now();
      final thisMonday = DateTime(
        now.year,
        now.month,
        now.day - now.weekday + 1,
      );
      await pump(tester, WeeklyNotesCard(monday: thisMonday));
      expect(
        find.text('Your notes on this week come on Monday.'),
        findsOneWidget,
      );
      expect(reads, 0);
    });

    testWidgets('in the month view it says which week', (tester) async {
      await pump(tester, card(named: true));
      expect(find.text('Week of 26 October'), findsOneWidget);
      expect(find.textContaining('Weekdays were steady'), findsOneWidget);
    });

    testWidgets('while it writes: Looking over your week', (tester) async {
      final wait = Completer<List<ReviewPoint>>();
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
          'See what\'s working, what\'s holding you back, and get personal '
          'tips on how to\u00A0improve.',
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

    testWidgets('there for a thin week too', (tester) async {
      await pump(tester, card(), entitlement: null, judgedDays: 0);
      expect(find.text('AI Coach'), findsOneWidget);
    });
  });
}
