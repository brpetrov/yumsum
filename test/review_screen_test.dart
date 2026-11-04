import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/period_review_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/review/review_screen.dart';
import 'package:lean_streak/screens/review/weekly_notes.dart';
import 'package:lean_streak/services/period_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

Future<Widget> _app(DateTime? firstDay, {DateTime? initialWeek}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUidProvider.overrideWithValue('test'),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      entitlementProvider.overrideWith((ref) => Stream.value(_plus)),
      firstLoggedDayProvider.overrideWith((ref) async => firstDay),
      reviewSummariesProvider.overrideWith((ref, range) async => {}),
      periodReviewProvider.overrideWith(
        (ref, range) async => PeriodReviewService().buildReview(
          startDate: range.startDate,
          endDate: range.endDate,
          summaries: const [],
        ),
      ),
      weeklyReviewProvider.overrideWith(
        (ref, monday) async => const ['Weekdays were steady.'],
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: ReviewScreen(initialWeek: initialWeek),
    ),
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

  testWidgets('no AI Coach in the month view, or for the week in progress', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(null));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyNotesCard), findsNothing);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyNotesCard), findsNothing);
  });

  testWidgets('initialWeek opens the week view on that week, with AI Coach', (
    tester,
  ) async {
    final now = DateTime.now();
    final lastMonday = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday) - 7,
    );
    await tester.pumpWidget(await _app(null, initialWeek: lastMonday));
    await tester.pumpAndSettle();

    final card = tester.widget<WeeklyNotesCard>(find.byType(WeeklyNotesCard));
    expect(card.monday, lastMonday);
    // Nothing logged in the override, so it says why there are no notes.
    expect(find.textContaining('Not enough logged this week'), findsOneWidget);
  });
}
