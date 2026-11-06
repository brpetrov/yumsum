import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  ReviewPoint(
    title: 'Weekends run high',
    text:
        'Weekdays were steady at about 1,890 kcal, but the weekend averaged '
        '2,580.',
    good: false,
  ),
  ReviewPoint(
    title: 'A light first meal',
    text:
        'Your first meal of the day averaged 14 g of protein. A "Greek '
        'yoghurt berry bowl" gives 30 g for 332 kcal.',
    good: false,
  ),
  ReviewPoint(
    title: 'Salt over the guide',
    text: 'Salt averaged 7.4 g against the 6 g guide.',
    good: false,
    why: 'Too much salt pushes blood pressure up over time.',
    tips: [
      'Swap crisps for unsalted nuts or fruit between meals.',
      'Rinse tinned beans and go easy on stock cubes.',
    ],
    recipes: ['Lentil soup', 'Not in the library'],
  ),
  ReviewPoint(
    title: 'Fibre on track',
    text: 'Fibre met the guide all week.',
    good: true,
  ),
];

String _key(DateTime day) =>
    '${day.year}-${'${day.month}'.padLeft(2, '0')}-'
    '${'${day.day}'.padLeft(2, '0')}';

DateTime _days(DateTime from, int days) =>
    DateTime(from.year, from.month, from.day + days);

/// The week's dates as the page shows them.
String _dates(DateTime monday) =>
    weekLabel(monday, year: _days(monday, 6).year != DateTime.now().year);

/// The coach illustration, wherever it's shown.
final _coach = find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == 'assets/coach.webp',
);

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
  final latest = latestFinishedWeek(DateTime.now());
  late int reads;
  late List<DateTime> asked;

  /// The page on [week], the latest finished one unless given. [notes] is
  /// what each read of the notes gives, in turn; a [Completer] keeps it
  /// loading, an [Exception] fails it and null is a week never written.
  /// Every week has [judgedDays] logged, [recipes] is the library, and
  /// [kept] says whether any notes are saved, for an account without
  /// YumSum Star.
  Future<void> pump(
    WidgetTester tester, {
    String? week = '',
    Entitlement? entitlement = _plus,
    List<Object?> notes = const [_notes],
    int judgedDays = 6,
    List<Recipe> recipes = const [],
    bool kept = false,
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
          recipeImageProvider.overrideWithValue(pixelImage),
          hasWeeklyReviewsProvider.overrideWith((ref) async => kept),
          // A Wednesday, so the first week is two before the latest.
          firstLoggedDayProvider.overrideWith(
            (ref) async => _days(latest, -12),
          ),
          weeklyReviewProvider.overrideWith((ref, monday) async {
            asked.add(monday);
            final result = notes[reads++ % notes.length];
            return switch (result) {
              final Completer<List<ReviewPoint>> wait => wait.future,
              final Exception error => throw error,
              _ => result as List<ReviewPoint>?,
            };
          }),
          reviewSummariesProvider.overrideWith(
            (ref, range) => Stream.value({
              for (var day = 0; day < judgedDays; day++)
                if (_days(range.startDate, day) case final date)
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
            initialLocation: switch (week) {
              null => AppRoutes.coach,
              '' => '${AppRoutes.coach}?week=${_key(latest)}',
              _ => '${AppRoutes.coach}?week=$week',
            },
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
    // A spinner never settles; a few frames bring the account, the notes
    // and the library.
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    if (recipes.isNotEmpty) {
      // Recipe photos decode outside the fake clock; until they have, their
      // spinners keep pumpAndSettle busy.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
    }
    if (settle) await tester.pumpAndSettle();
  }

  test('the latest finished week is last week', () {
    expect(latestFinishedWeek(DateTime(2026, 11, 5)), DateTime(2026, 10, 26));
    expect(latestFinishedWeek(DateTime(2026, 11, 2)), DateTime(2026, 10, 26));
    expect(latestFinishedWeek(DateTime(2026, 11, 1)), DateTime(2026, 10, 19));
  });

  group('with YumSum Star', () {
    testWidgets('the notes, with their titles, under Last week and the coach', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Last week'), findsOneWidget);
      expect(find.text(_dates(latest)), findsOneWidget);
      expect(_coach, findsOneWidget);
      expect(find.text('Weekends run high'), findsOneWidget);
      // Each number keeps its unit on its line.
      expect(
        find.text(
          'Weekdays were steady at about 1,890\u00A0kcal, but the weekend '
          'averaged 2,580.',
        ),
        findsOneWidget,
      );
      expect(find.text('A light first meal'), findsOneWidget);
      expect(
        find.text(
          'Your first meal of the day averaged 14\u00A0g of protein. A '
          '"Greek yoghurt berry bowl" gives 30\u00A0g for 332\u00A0kcal.',
        ),
        findsOneWidget,
      );
      expect(find.text('Fibre on track'), findsOneWidget);
      expect(find.text('Fibre met the guide all week.'), findsOneWidget);
      expect(reads, 1);
      expect(asked, [latest]);
    });

    testWidgets('a note written in pieces shows why it matters, its tips '
        'under Try this, and the recipes it names as chips that open '
        'them', (tester) async {
      await pump(tester, recipes: [testRecipe('Lentil soup')]);
      expect(
        find.text('Too much salt pushes blood pressure up over time.'),
        findsOneWidget,
      );
      expect(find.text('Try this'), findsOneWidget);
      expect(find.text('Keep going'), findsNothing);
      expect(
        find.text('Swap crisps for unsalted nuts or fruit between meals.'),
        findsOneWidget,
      );
      expect(find.text('Not in the library'), findsNothing);

      // The chip's own InkWell, inside the row of chips, not the card's.
      final chip = find.descendant(
        of: find.byType(Wrap),
        matching: find.widgetWithText(InkWell, 'Lentil soup'),
      );
      expect(chip, findsOneWidget);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text('Recipe lentil-soup'), findsOneWidget);
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

    testWidgets('the info button explains it beside the coach, with Close '
        'only', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('How it works'));
      await tester.pumpAndSettle();
      expect(find.text(coachSubtitle), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: _coach),
        findsOneWidget,
      );
      expect(find.text('Spot what\'s holding you back'), findsOneWidget);
      expect(find.text('Start every week with direction'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Become a Star'), findsNothing);
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

    testWidgets('a week never written says so', (tester) async {
      await pump(tester, notes: [null]);
      expect(
        find.text(
          'No notes on this week. AI Coach writes them during the week '
          'after, when you open this page.',
        ),
        findsOneWidget,
      );
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

    testWidgets('Previous and Next page through the finished weeks by their '
        'dates, back to the first logged one', (tester) async {
      await pump(tester);

      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('Last week'), findsNothing);
      expect(find.text(_dates(_days(latest, -7))), findsOneWidget);
      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();
      expect(find.text(_dates(_days(latest, -14))), findsOneWidget);
      expect(_enabled(tester, _previous), isFalse);
      expect(asked, [latest, _days(latest, -7), _days(latest, -14)]);
      expect(find.text('Latest'), findsNothing);

      await tester.tap(find.byTooltip('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Last week'), findsOneWidget);
      expect(_enabled(tester, _next), isFalse);
      expect(_enabled(tester, _previous), isTrue);
    });

    testWidgets('the weeks go back only to the one YumSum Star began in', (
      tester,
    ) async {
      await pump(
        tester,
        entitlement: Entitlement(
          active: true,
          source: EntitlementSource.play,
          startedAt: _days(latest, 2),
        ),
      );
      expect(find.text('Last week'), findsOneWidget);
      expect(find.text('Weekends run high'), findsOneWidget);
      expect(_enabled(tester, _previous), isFalse);
    });

    testWidgets('a new subscriber is told when the first notes come, with '
        'nothing to page through', (tester) async {
      final now = DateTime.now();
      await pump(
        tester,
        entitlement: Entitlement(
          active: true,
          source: EntitlementSource.play,
          startedAt: now,
        ),
      );
      expect(find.text('Your first notes come on Monday'), findsOneWidget);
      final days = 8 - now.weekday;
      expect(
        find.text(days == 1 ? '1 day to go' : '$days days to go'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'On Monday ${DateFormat('d MMMM').format(_days(now, days))} '
          'it\'ll tell you what went well',
        ),
        findsOneWidget,
      );
      expect(_coach, findsOneWidget);
      expect(find.byTooltip('Previous'), findsNothing);
      expect(find.text('Last week'), findsNothing);
      expect(reads, 0);
    });

    testWidgets('an unknown or unfinished week opens the latest', (
      tester,
    ) async {
      await pump(tester, week: 'not a date');
      expect(find.text('Last week'), findsOneWidget);

      await pump(tester, week: _key(_days(latest, 7)));
      expect(find.text('Last week'), findsOneWidget);

      await pump(tester, week: null);
      expect(find.text('Last week'), findsOneWidget);
    });
  });

  group('without YumSum Star', () {
    testWidgets('what it does, and Become a Star opens the paywall', (
      tester,
    ) async {
      await pump(tester, entitlement: null);
      expect(_coach, findsOneWidget);
      expect(find.text(coachSubtitle), findsOneWidget);
      expect(find.text('Spot what\'s holding you back'), findsOneWidget);
      expect(find.text('Build a more balanced diet'), findsOneWidget);
      expect(find.text('Get advice you can put into practice'), findsOneWidget);
      expect(find.text('Start every week with direction'), findsOneWidget);
      expect(find.byTooltip('How it works'), findsNothing);
      expect(find.byTooltip('Previous'), findsNothing);
      expect(reads, 0);

      await tester.ensureVisible(find.text('Become a Star'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Become a Star'));
      await tester.pumpAndSettle();
      expect(find.text('The paywall'), findsOneWidget);
    });

    final ended = Entitlement(
      active: false,
      source: EntitlementSource.play,
      state: 'expired',
      expiresAt: _days(DateTime.now(), -3),
    );

    testWidgets('once it has ended, the notes stay, with Become a Star', (
      tester,
    ) async {
      await pump(tester, entitlement: ended, kept: true);
      expect(
        find.text(
          'YumSum Star has ended, so no new notes are written. The ones you '
          'have stay.',
        ),
        findsOneWidget,
      );
      expect(find.text('Last week'), findsOneWidget);
      expect(find.text('Weekends run high'), findsOneWidget);
      expect(find.byTooltip('How it works'), findsNothing);

      await tester.tap(find.text('Become a Star'));
      await tester.pumpAndSettle();
      expect(find.text('The paywall'), findsOneWidget);
    });

    testWidgets('a week without notes, once it has ended, says only that', (
      tester,
    ) async {
      await pump(tester, entitlement: ended, kept: true, notes: [null]);
      expect(find.text('No notes on this week.'), findsOneWidget);
    });

    testWidgets('ended with nothing saved: what it does', (tester) async {
      await pump(tester, entitlement: ended);
      expect(find.text(coachSubtitle), findsOneWidget);
      expect(find.text('Spot what\'s holding you back'), findsOneWidget);
      expect(find.text('Last week'), findsNothing);
    });
  });
}
