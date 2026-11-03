import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/widgets/macro_totals.dart';

/// A macros line as the app shows it, each figure held together.
String _line(String text) => text.replaceAllMapped(
  RegExp(r'(\w+) ([\d.]+) g'),
  (m) => '${m[1]}\u00A0${m[2]}\u00A0g',
);

Meal _meal(String name, Nutrients? macros) => Meal(
  id: name,
  date: '2026-11-03',
  timestamp: DateTime(2026, 11, 3, 12),
  name: name,
  calories: 500,
  macros: macros,
  createdAt: DateTime(2026, 11, 3, 12),
  updatedAt: DateTime(2026, 11, 3, 12),
);

void main() {
  Future<void> pump(WidgetTester tester, List<Meal> meals) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: MacroTotals(meals: meals)),
    ),
  );

  final wrap = _meal(
    'Chicken wrap',
    const Nutrients(
      fat: 18,
      saturates: 6,
      carbs: 52,
      sugars: 5,
      fibre: 4,
      salt: 2.1,
    ),
  );
  // A packet without fibre, as UK labels allow.
  final crisps = _meal(
    'Crisps',
    const Nutrients(
      fat: 8.4,
      saturates: 0.7,
      carbs: 15,
      sugars: 0.2,
      salt: 0.4,
    ),
  );

  test(
    'macrosLine gives whole grams, salt to one decimal, known ones only',
    () {
      expect(
        macrosLine(wrap.macros!),
        'Fat\u00A018\u00A0g · saturates\u00A06\u00A0g · '
        'carbs\u00A052\u00A0g · sugars\u00A05\u00A0g · '
        'fibre\u00A04\u00A0g · salt\u00A02.1\u00A0g',
      );
      expect(
        macrosLine(const Nutrients(carbs: 12.6, salt: 0.04)),
        _line('Carbs 13 g · salt 0.0 g'),
      );
    },
  );

  testWidgets('a closed line of fat, carbs and salt opens to all six', (
    tester,
  ) async {
    await pump(tester, [wrap, crisps, _meal('Toast', null)]);

    expect(
      find.text(_line('Fat 26 g · carbs 67 g · salt 2.5 g')),
      findsOneWidget,
    );
    expect(find.text('Saturates'), findsNothing);

    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.text('Saturates'), findsOneWidget);
    expect(find.text('26\u00A0g'), findsOneWidget);
    expect(find.text('7\u00A0g'), findsOneWidget);
    expect(find.text('67\u00A0g'), findsOneWidget);
    expect(find.text('5\u00A0g'), findsOneWidget);
    // The crisps don't say, so the fibre is a floor.
    expect(find.text('at least 4\u00A0g'), findsOneWidget);
    expect(find.text('2.5\u00A0g'), findsOneWidget);
    expect(
      find.text('Aim for 30 g of fibre a day, and no more than 6 g of salt.'),
      findsOneWidget,
    );
    expect(find.text('1 meal not counted (no macro info)'), findsOneWidget);
    expect(find.text('Tap a meal to see its macros.'), findsOneWidget);

    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.text('Saturates'), findsNothing);
  });

  testWidgets('every meal counted needs no note', (tester) async {
    await pump(tester, [wrap]);
    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.textContaining('not counted'), findsNothing);
    expect(find.text('4\u00A0g'), findsOneWidget);
  });

  testWidgets('says so when no meal has macros, and doesn\'t open', (
    tester,
  ) async {
    await pump(tester, [_meal('Toast', null)]);
    expect(find.text('No macro info for today\'s meals'), findsOneWidget);
    await tester.tap(find.byType(MacroTotals));
    await tester.pump();
    expect(find.text('Fat'), findsNothing);
  });

  testWidgets('nothing at all with nothing logged', (tester) async {
    await pump(tester, const []);
    expect(find.byType(Text), findsNothing);
  });
}
