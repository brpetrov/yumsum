import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/widgets/estimate_breakdown.dart';

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
  assumed: 'semi-skimmed milk',
  options: [
    _whole,
    EstimateItem(name: 'cappuccino with syrup', grams: 250, kcal: 190),
  ],
);

const _sarmi = EstimateItem(
  name: 'sarmi with meat',
  grams: 300,
  kcal: 420,
  protein: 21,
  amount: '5 pieces',
  amounts: [(label: '3 pieces', grams: 180), (label: '8 pieces', grams: 480)],
);

const _croissant = EstimateItem(
  name: 'croissant',
  grams: 60,
  kcal: 270,
  protein: 5,
);

void main() {
  // What the breakdown handed back, latest last; the host passes each back
  // in, as the quick-log bar and the meal form do.
  late List<List<EstimateItem>> changes;
  late void Function(List<EstimateItem>) replace;

  Future<void> pump(
    WidgetTester tester,
    List<EstimateItem> start, {
    bool editable = true,
  }) async {
    changes = [];
    var items = start;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              replace = (next) => setState(() => items = next);
              return EstimateBreakdown(
                items: items,
                onChanged: editable
                    ? (next) {
                        changes.add(next);
                        setState(() => items = next);
                      }
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }

  final ticks = find.byIcon(Icons.check_rounded);

  testWidgets('opens with chips under the items that have choices only, the '
      'assumed ones ticked', (tester) async {
    await pump(tester, const [_cappuccino, _croissant]);

    // Each item's name heads its block; the kind chips say only what the
    // option changes.
    for (final text in [
      'Cappuccino with semi-skimmed milk',
      'Croissant',
      'Regular',
      'Small',
      'Large',
      'Semi-skimmed milk',
      'Whole milk',
      'Syrup',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(ticks, findsNWidgets(2));
    expect(changes, isEmpty);
  });

  testWidgets('without choices, or without onChanged, it stays one line', (
    tester,
  ) async {
    await pump(tester, const [_croissant]);
    expect(find.text('croissant 270'), findsOneWidget);

    await pump(tester, const [_cappuccino], editable: false);
    expect(find.text('cappuccino with semi-skimmed milk 110'), findsOneWidget);
    await tester.tap(find.byType(EstimateBreakdown));
    await tester.pump();
    expect(find.text('Small'), findsNothing);
  });

  testWidgets('an amount, then a kind, answers the combination', (
    tester,
  ) async {
    await pump(tester, const [_cappuccino, _croissant]);

    await tester.tap(find.text('Large'));
    await tester.pump();
    expect(changes.last, [answered(_cappuccino, grams: 350), _croissant]);
    expect(find.text('154 kcal · 10 g'), findsOneWidget);

    await tester.tap(find.text('Whole milk'));
    await tester.pump();
    final both = answered(_cappuccino, kind: _whole, grams: 350);
    expect(changes.last, [both, _croissant]);
    expect(find.text('210 kcal · 11 g'), findsOneWidget);
    expect(find.text('Cappuccino with whole milk'), findsOneWidget);
    // Still open, the picks ticked.
    expect(ticks, findsNWidgets(2));

    await tester.tap(find.text('Regular'));
    await tester.pump();
    expect(changes.last.first, answered(_cappuccino, kind: _whole));
  });

  testWidgets('an item with only amounts shows one row', (tester) async {
    await pump(tester, const [_sarmi]);
    for (final text in ['5 pieces', '3 pieces', '8 pieces']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // Its name, and no kind row.
    expect(find.text('Sarmi with meat'), findsOneWidget);
    expect(ticks, findsOneWidget);

    await tester.tap(find.text('8 pieces'));
    await tester.pump();
    expect(changes.last.single.kcal, 672);
  });

  testWidgets('a kind chip shows only what differs; without the AI\'s '
      'assumed kind, the first is the item\'s name', (tester) async {
    const takeaway = EstimateItem(
      name: 'takeaway chicken curry with rice',
      grams: 450,
      kcal: 820,
    );
    const curry = EstimateItem(
      name: 'chicken curry with rice',
      grams: 450,
      kcal: 550,
      assumed: 'homemade',
      options: [takeaway],
    );
    const withoutMeat = EstimateItem(
      name: 'sarmi without meat',
      grams: 300,
      kcal: 260,
    );
    const sarmi = EstimateItem(
      name: 'sarmi with meat',
      grams: 300,
      kcal: 420,
      options: [withoutMeat],
    );
    await pump(tester, const [curry, sarmi]);

    for (final text in ['Homemade', 'Takeaway', 'Without meat']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // The heading and the ticked chip.
    expect(find.text('Sarmi with meat'), findsNWidgets(2));

    await tester.tap(find.text('Takeaway'));
    await tester.pump();
    expect(changes.last, [takeaway, sarmi]);
    await tester.tap(find.text('Without meat'));
    await tester.pump();
    expect(changes.last, [takeaway, withoutMeat]);
  });

  testWidgets('a weight corrected by hand settles the item: its chips go', (
    tester,
  ) async {
    await pump(tester, const [_sarmi]);
    await tester.tap(find.text('300 g'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '400');
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();

    expect(changes.last.single, resized(_sarmi, 400));
    expect(find.text('3 pieces'), findsNothing);
    expect(ticks, findsNothing);
  });

  testWidgets('a new estimate starts its own choices afresh', (tester) async {
    await pump(tester, const [_cappuccino]);
    await tester.tap(find.text('Small'));
    await tester.pump();

    replace(const [_cappuccino]);
    await tester.pump();
    expect(find.text('110 kcal · 7 g'), findsOneWidget);
    expect(ticks, findsNWidgets(2));
    await tester.tap(find.text('Syrup'));
    await tester.pump();
    expect(
      changes.last.single,
      answered(_cappuccino, kind: _cappuccino.options[1]),
    );
  });
}
