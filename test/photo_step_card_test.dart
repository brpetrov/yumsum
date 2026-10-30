import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_camera_page.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: card)),
    ),
  );

  testWidgets('a step of several says which, what to take and how', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const PhotoStepCard(step: nutritionTableStep, number: 2, total: 2),
    );
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Take a photo of the nutrition table'), findsOneWidget);
    expect(find.textContaining('every number can be read'), findsOneWidget);
  });

  testWidgets('a single photo has no step count', (tester) async {
    await pumpCard(
      tester,
      const PhotoStepCard(step: (title: 'Point at the barcode', tip: null)),
    );
    expect(find.textContaining('Step'), findsNothing);
    expect(find.text('Point at the barcode'), findsOneWidget);
  });
}
