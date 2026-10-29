import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/contribute_sheet.dart';

// A 1×1 PNG, so the photo thumbnails decode.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

void main() {
  testWidgets('Contribute sits above the navigation bar', (tester) async {
    // Android draws edge to edge, so the navigation bar overlaps the app.
    final ratio = tester.view.devicePixelRatio;
    tester.view.viewPadding = FakeViewPadding(bottom: 48 * ratio);
    tester.view.padding = FakeViewPadding(bottom: 48 * ratio);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        // Signed out, so the label is left for the user to fill in.
        overrides: [currentUidProvider.overrideWithValue(null)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showContributeSheet(
                  context,
                  barcode: '5000000000000',
                  photos: [XFile.fromData(_png), XFile.fromData(_png)],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Scroll the form to its end.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    final height = tester.view.physicalSize.height / ratio;
    // FilledButton.icon builds a subclass, which widgetWithText won't match.
    final contribute = find.ancestor(
      of: find.text('Contribute'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(tester.getRect(contribute).bottom, lessThanOrEqualTo(height - 48));
  });
}
