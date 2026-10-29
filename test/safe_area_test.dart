import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/period_review_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/quick_log_bar.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/screens/review/day_meals_sheet.dart';
import 'package:lean_streak/screens/review/review_screen.dart';
import 'package:lean_streak/services/period_review_service.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_frame.dart';

/// Phones draw apps behind the navigation bar (edge-to-edge), so nothing
/// the user needs may end up inside the bottom inset.
const _screen = Size(400, 800);
const _navBar = 48.0;
const _safeBottom = 800 - _navBar;

void _phoneWithNavBar(WidgetTester tester, {Size screen = _screen}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = screen;
  tester.view.padding = const FakeViewPadding(bottom: _navBar);
  tester.view.viewPadding = const FakeViewPadding(bottom: _navBar);
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) {
  return ProviderScope(
    overrides: [
      currentUidProvider.overrideWithValue('test'),
      mealsForDateProvider.overrideWith((ref, date) => Stream.value([])),
      dailySummaryForDateProvider.overrideWith(
        (ref, date) => Stream.value(null),
      ),
      dayEditsThisMonthProvider.overrideWith((ref) => Stream.value(0)),
      firstLoggedDayProvider.overrideWith((ref) async => null),
      reviewSummariesProvider.overrideWith((ref, range) async => {}),
      periodReviewProvider.overrideWith(
        (ref, range) async => PeriodReviewService().buildReview(
          startDate: range.startDate,
          endDate: range.endDate,
          summaries: const [],
        ),
      ),
    ],
    child: MaterialApp(home: home),
  );
}

Widget _opener(Future<void> Function(BuildContext context) open) {
  return Scaffold(
    body: Builder(
      builder: (context) =>
          TextButton(onPressed: () => open(context), child: const Text('open')),
    ),
  );
}

void main() {
  testWidgets('Today\'s log bar sits above the navigation bar', (tester) async {
    _phoneWithNavBar(tester);
    await tester.pumpWidget(
      _app(
        const AppFrame(
          title: 'Today',
          body: SizedBox.expand(),
          bottom: QuickLogBar(),
        ),
      ),
    );

    expect(tester.getRect(find.byType(TextField)).bottom, lessThan(_safeBottom));
    expect(
      tester.getRect(find.byTooltip('Speak')).bottom,
      lessThanOrEqualTo(_safeBottom),
    );
  });

  testWidgets('the meal form\'s Save button clears the navigation bar', (
    tester,
  ) async {
    _phoneWithNavBar(tester);
    await tester.pumpWidget(_app(_opener((context) => showLogMealSheet(context))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.widgetWithText(ElevatedButton, 'Save meal')).bottom,
      lessThanOrEqualTo(_safeBottom),
    );
  });

  testWidgets('the day view\'s Add meal button clears the navigation bar', (
    tester,
  ) async {
    _phoneWithNavBar(tester);
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showDayMealsSheet(context, DateTime(2020, 3, 10)),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.widgetWithText(ElevatedButton, 'Add meal')).bottom,
      lessThanOrEqualTo(_safeBottom),
    );
  });

  testWidgets('the end of Review scrolls clear of the navigation bar', (
    tester,
  ) async {
    // A short screen so the page has to scroll all the way to its end.
    const screen = Size(400, 520);
    _phoneWithNavBar(tester, screen: screen);
    await tester.pumpWidget(_app(const ReviewScreen()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final lastCard = find.byType(AppCard).last;
    expect(
      tester.getRect(lastCard).bottom,
      lessThan(screen.height - _navBar),
    );
  });
}
