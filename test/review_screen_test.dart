import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/period_review_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/screens/review/review_screen.dart';
import 'package:lean_streak/services/period_review_service.dart';

Widget _app(DateTime? firstDay) {
  return ProviderScope(
    overrides: [
      currentUidProvider.overrideWithValue('test'),
      firstLoggedDayProvider.overrideWith((ref) async => firstDay),
      reviewSummariesProvider.overrideWith((ref, range) async => {}),
      periodReviewProvider.overrideWith(
        (ref, range) async => PeriodReviewService().buildReview(
          startDate: range.startDate,
          endDate: range.endDate,
          summaries: const [],
        ),
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
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(_previous(tester).onPressed, isNull);
  });

  testWidgets('pages back to the month of the first logged day, no further', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(_app(DateTime(now.year, now.month - 2, 15)));
    await tester.pumpAndSettle();

    for (var month = 0; month < 2; month++) {
      expect(_previous(tester).onPressed, isNotNull);
      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();
    }
    expect(_previous(tester).onPressed, isNull);
  });
}
