import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Turns the open time wheels (showTimeWheels) to [hour]:[minute] and
/// confirms with Done.
Future<void> pickTime(WidgetTester tester, int hour, int minute) async {
  tester
      .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
      .onDateTimeChanged(DateTime(2000, 1, 1, hour, minute));
  await tester.tap(find.byKey(const ValueKey('time-wheels-done')));
  await tester.pumpAndSettle();
}
