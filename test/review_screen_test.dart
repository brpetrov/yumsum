import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/review/review_screen.dart';
import 'package:lean_streak/screens/review/weekly_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

final _lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);

Future<Widget> _app(
  DateTime? firstDay, {
  Entitlement? entitlement = _plus,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUidProvider.overrideWithValue('test'),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
      firstLoggedDayProvider.overrideWith((ref) async => firstDay),
      reviewSummariesProvider.overrideWith((ref, range) => Stream.value({})),
      weeklyReviewProvider.overrideWith(
        (ref, monday) async => const [
          (text: 'Weekdays were steady.', good: false),
        ],
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const ReviewScreen()),
  );
}

IconButton _previous(WidgetTester tester) => tester.widget<IconButton>(
  find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
);

void main() {
  testWidgets('nothing logged: no earlier months to page back to', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(null));
    await tester.pumpAndSettle();

    expect(_previous(tester).onPressed, isNull);
  });

  testWidgets('pages back to the month of the first logged day, no further', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(await _app(DateTime(now.year, now.month - 2, 15)));
    await tester.pumpAndSettle();

    for (var month = 0; month < 2; month++) {
      expect(_previous(tester).onPressed, isNotNull);
      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();
    }
    expect(_previous(tester).onPressed, isNull);
  });

  testWidgets('the phone\'s bottom inset adds no gap under the calendar', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 120);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await _app(null));
    await tester.pumpAndSettle();

    final lastRow = tester.getBottomLeft(
      find
          .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
          .last,
    );
    final keyTop = tester.getTopLeft(find.byType(Wrap)).dy;
    expect(keyTop - lastRow.dy, 16);
  });

  testWidgets('with Star, AI Coach in both views', (tester) async {
    await tester.pumpWidget(await _app(_lastMonth));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();

    // Last month shows its latest week that ended in it.
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month, 0);
    final monday = DateTime(
      lastDay.year,
      lastDay.month,
      lastDay.day - lastDay.weekday % 7 - 6,
    );
    final card = tester.widget<WeeklyNotesCard>(find.byType(WeeklyNotesCard));
    expect(card.monday, monday);
    expect(
      find.text('Week of ${DateFormat('d MMMM').format(monday)}'),
      findsOneWidget,
    );

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your notes on this week come on Monday.'),
      findsOneWidget,
    );
  });

  testWidgets('without Star, the AI Coach prompt in both views', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(null, entitlement: null));
    await tester.pumpAndSettle();
    expect(find.byType(CoachPrompt), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.byType(CoachPrompt), findsOneWidget);
  });

  testWidgets('AI Coach on a finished week', (tester) async {
    final now = DateTime.now();
    final lastMonday = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday) - 7,
    );
    await tester.pumpWidget(await _app(lastMonday));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();

    final card = tester.widget<WeeklyNotesCard>(find.byType(WeeklyNotesCard));
    expect(card.monday, lastMonday);
    // Nothing logged in the override, so it says why there are no notes.
    expect(find.textContaining('Not enough logged this week'), findsOneWidget);
  });
}
