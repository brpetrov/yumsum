import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/widgets/estimate_choice_dialog.dart';

const _large = EstimateItem(
  name: 'large cappuccino',
  grams: 350,
  kcal: 200,
  protein: 11,
);

const _cappuccino = EstimateItem(
  name: 'cappuccino with semi-skimmed milk',
  grams: 250,
  kcal: 110,
  protein: 7,
  options: [
    EstimateItem(
      name: 'cappuccino with whole milk',
      grams: 250,
      kcal: 150,
      protein: 8,
    ),
    _large,
  ],
);

void main() {
  late Future<EstimateItem?> asked;

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => asked = showEstimateChoice(context, _cappuccino),
            child: const Text('Ask'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the version the AI went with, ticked, then the others, '
      'each with its calories', (tester) async {
    await open(tester);
    for (final text in [
      'Which did you have?',
      'We went with the first.',
      'Cappuccino with semi-skimmed milk',
      '110 kcal',
      'Cappuccino with whole milk',
      '150 kcal',
      'Large cappuccino',
      '200 kcal',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('a tap answers with that version; the first keeps it; '
      'dismissing answers nothing', (tester) async {
    await open(tester);
    await tester.tap(find.text('Large cappuccino'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(await asked, _large);

    await open(tester);
    await tester.tap(find.text('Cappuccino with semi-skimmed milk'));
    await tester.pumpAndSettle();
    final kept = await asked;
    expect(kept, _cappuccino.settled);
    expect(kept!.options, isEmpty);

    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(await asked, isNull);
  });
}
