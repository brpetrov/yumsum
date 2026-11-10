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

const _whole = EstimateItem(
  name: 'cappuccino with whole milk',
  grams: 250,
  kcal: 150,
  protein: 8,
);

const _cappuccino = EstimateItem(
  name: 'cappuccino with semi-skimmed milk',
  grams: 250,
  kcal: 110,
  protein: 7,
  amount: 'regular',
  amounts: [(label: 'small', grams: 150), (label: 'large', grams: 350)],
  options: [_whole, _large],
);

const _sarmi = EstimateItem(
  name: 'sarmi with meat',
  grams: 300,
  kcal: 420,
  protein: 21,
  amount: '5 pieces',
  amounts: [(label: '3 pieces', grams: 180), (label: '8 pieces', grams: 480)],
);

void main() {
  late Future<EstimateItem?> asked;

  Future<void> open(
    WidgetTester tester, [
    EstimateItem item = _cappuccino,
  ]) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => asked = showEstimateChoice(context, item),
            child: const Text('Ask'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the amount and kind rows with the assumed chips ticked, '
      'and the total', (tester) async {
    await open(tester);
    for (final text in [
      'Quick question',
      'How big a portion?',
      'Regular',
      'Small',
      'Large',
      'Which kind?',
      'Cappuccino with semi-skimmed milk',
      'Cappuccino with whole milk',
      'Large cappuccino',
      '110 kcal',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.text('How many?'), findsNothing);
  });

  testWidgets('a count reads How many?', (tester) async {
    await open(tester, _sarmi);
    expect(find.text('How many?'), findsOneWidget);
    expect(find.text('5 pieces'), findsOneWidget);
  });

  testWidgets('tapping chips updates the total and Done answers the '
      'combination', (tester) async {
    await open(tester);
    await tester.tap(find.text('Large'));
    await tester.pump();
    expect(find.text('${resized(_cappuccino, 350).kcal} kcal'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));

    await tester.tap(find.text('Cappuccino with whole milk'));
    await tester.pump();
    final both = answered(_cappuccino, kind: _whole, grams: 350);
    expect(both.kcal, 210);
    expect(find.text('210 kcal'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(await asked, both);
  });

  testWidgets('Done with nothing tapped keeps the assumed; Cancel and '
      'dismissing answer null', (tester) async {
    await open(tester);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final kept = await asked;
    expect(kept, _cappuccino.settled);
    expect(kept!.options, isEmpty);
    expect(kept.amounts, isEmpty);

    await open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await asked, isNull);

    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(await asked, isNull);
  });

  testWidgets('an item with only amounts shows one row, under its name', (
    tester,
  ) async {
    await open(tester, _sarmi);
    expect(find.text('Which kind?'), findsNothing);
    expect(find.text('Sarmi with meat'), findsOneWidget);
    await tester.tap(find.text('8 pieces'));
    await tester.pump();
    expect(find.text('672 kcal'), findsOneWidget);
  });

  testWidgets('what the user typed goes under the title, and a one-item meal '
      'skips the item\'s name', (tester) async {
    late Future<List<EstimateItem>?> offered;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => offered = offerEstimateChoices(context, const [
              _sarmi,
            ], said: 'sarmi for lunch'),
            child: const Text('Ask'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    expect(find.text('Quick question'), findsOneWidget);
    expect(find.text('Sarmi for lunch'), findsOneWidget);
    expect(find.text('Sarmi with meat'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect((await offered)!.single, _sarmi.settled);
  });

  testWidgets('asks the two items with the widest spread, settles the rest', (
    tester,
  ) async {
    const narrow = EstimateItem(
      name: 'tea',
      grams: 250,
      kcal: 20,
      options: [EstimateItem(name: 'tea with sugar', grams: 250, kcal: 52)],
    );
    late Future<List<EstimateItem>?> offered;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => offered = offerEstimateChoices(context, const [
              narrow,
              _cappuccino,
              _sarmi,
            ]),
            child: const Text('Ask'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    // The meal's order: the cappuccino, then the sarmi; never the tea.
    expect(find.text('Cappuccino with semi-skimmed milk'), findsOneWidget);
    await tester.tap(find.text('Small'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Sarmi with meat'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    expect(await offered, [
      narrow.settled,
      resized(_cappuccino, 150),
      _sarmi.settled,
    ]);
  });
}
