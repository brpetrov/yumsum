import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/screens/dashboard/helpers/day_off_dialog.dart';

void main() {
  bool? result;

  Future<void> open(WidgetTester tester, {required bool isOff}) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await confirmDayOff(context, isOff: isOff),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains a day off and confirms it', (tester) async {
    await open(tester, isOff: false);
    expect(find.text('Take today off?'), findsOneWidget);
    expect(find.textContaining('today just isn\'t judged'), findsOneWidget);

    await tester.tap(find.text('Take the day off'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('going back on plan can be cancelled', (tester) async {
    await open(tester, isOff: true);
    expect(find.text('Back on plan?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
