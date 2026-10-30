import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/app/app.dart';
import 'package:lean_streak/core/theme/app_theme.dart';

void main() {
  testWidgets('a tap on nothing in particular lets go of the box', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: appShellBuilder,
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: focus),
              TextButton(onPressed: () => pressed++, child: const Text('Go')),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    // A button keeps its tap.
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(pressed, 1);

    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });
}
