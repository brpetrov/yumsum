import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Picks [hour]:[minute] in the open time picker, typed in its text mode
/// (English Material texts), and confirms it.
Future<void> pickTime(WidgetTester tester, int hour, int minute) async {
  await tester.tap(find.byTooltip('Switch to text input mode'));
  await tester.pumpAndSettle();
  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.at(0), '$hour');
  await tester.enterText(fields.at(1), '$minute'.padLeft(2, '0'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}
