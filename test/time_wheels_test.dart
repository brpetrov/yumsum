import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/widgets/time_wheels.dart';

import 'time_picker_fixtures.dart';

void main() {
  testWidgets('the wheels start at the time given, in 24 hours; Done answers '
      'the time turned to, and dismissing the sheet answers null', (
    tester,
  ) async {
    TimeOfDay? answer;
    var answered = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                answer = await showTimeWheels(
                  context,
                  initial: const TimeOfDay(hour: 16, minute: 35),
                  title: 'Time eaten',
                );
                answered = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Time eaten'), findsOneWidget);
    final wheels = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(wheels.use24hFormat, isTrue);
    expect(
      TimeOfDay.fromDateTime(wheels.initialDateTime),
      const TimeOfDay(hour: 16, minute: 35),
    );

    await pickTime(tester, 8, 5);
    expect(answer, const TimeOfDay(hour: 8, minute: 5));

    answered = false;
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(answered, isTrue);
    expect(answer, isNull);
  });
}
