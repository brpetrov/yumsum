import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/screens/dashboard/helpers/portion_sheet.dart';
import 'package:lean_streak/widgets/pack_photo.dart';

const _wrap = (
  name: 'Chicken Tikka Wrap',
  brand: 'Tesco',
  kcalPer100g: 215,
  proteinPer100g: 9,
  servingGrams: 220,
  imageUrl: null,
);

void main() {
  test('portionFor scales per-100 g figures and rounds', () {
    expect(portionFor(_wrap, 150), (
      name: 'Chicken Tikka Wrap',
      kcal: 323,
      protein: 14,
    ));
    expect(portionFor(_wrap, 100).kcal, 215);

    const noProtein = (
      name: 'Cola',
      brand: null,
      kcalPer100g: 42,
      proteinPer100g: null,
      servingGrams: 330,
      imageUrl: null,
    );
    expect(portionFor(noProtein, 330), (
      name: 'Cola',
      kcal: 139,
      protein: null,
    ));
  });

  testWidgets('the sheet starts at the serving, recalculates and returns', (
    tester,
  ) async {
    Portion? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showPortionSheet(context, _wrap),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Chicken Tikka Wrap'), findsOneWidget);
    expect(find.text('Tesco'), findsOneWidget);
    expect(find.byType(PackPhoto), findsNothing);
    expect(
      find.text('215 kcal · 9 g protein per 100 g · Open Food Facts'),
      findsOneWidget,
    );
    expect(find.text('473 kcal · 20 g protein'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '150');
    await tester.pump();
    expect(find.text('323 kcal · 14 g protein'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result, (name: 'Chicken Tikka Wrap', kcal: 323, protein: 14));
  });

  testWidgets('the sheet shows the pack photo when there is one', (
    tester,
  ) async {
    const withPhoto = (
      name: 'Chicken Tikka Wrap',
      brand: 'Tesco',
      kcalPer100g: 215,
      proteinPer100g: 9,
      servingGrams: 220,
      imageUrl: 'https://images.openfoodfacts.org/w.200.jpg',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPortionSheet(context, withPhoto),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<PackPhoto>(find.byType(PackPhoto)).url,
      'https://images.openfoodfacts.org/w.200.jpg',
    );
  });
}
