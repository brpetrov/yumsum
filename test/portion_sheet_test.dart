import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/screens/dashboard/helpers/portion_sheet.dart';
import 'package:lean_streak/widgets/pack_photo.dart';

/// A macros line as the app shows it, each figure held together.
String _line(String text) => text.replaceAllMapped(
  RegExp(r'(\w+) ([\d.]+) g'),
  (m) => '${m[1]}\u00A0${m[2]}\u00A0g',
);

const _wrap = (
  name: 'Chicken Tikka Wrap',
  brand: 'Tesco',
  kcalPer100g: 215,
  proteinPer100g: 9,
  macrosPer100g: Nutrients(fat: 8, carbs: 24, salt: 0.9),
  servingGrams: 220,
  imageUrl: null,
);

void main() {
  test('portionFor scales per-100 g figures and rounds', () {
    final portion = portionFor(_wrap, 150);
    expect(
      (portion.name, portion.kcal, portion.protein),
      ('Chicken Tikka Wrap', 323, 14),
    );
    expect(portion.macros!.fat, 12);
    expect(portion.macros!.carbs, 36);
    expect(portion.macros!.salt, closeTo(1.35, 1e-9));
    expect(portion.macros!.fibre, isNull);
    expect(portionFor(_wrap, 100).kcal, 215);

    const noProtein = (
      name: 'Cola',
      brand: null,
      kcalPer100g: 42,
      proteinPer100g: null,
      macrosPer100g: null,
      servingGrams: 330,
      imageUrl: null,
    );
    expect(portionFor(noProtein, 330), (
      name: 'Cola',
      kcal: 139,
      protein: null,
      macros: null,
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
    expect(
      (result?.name, result?.kcal, result?.protein),
      ('Chicken Tikka Wrap', 323, 14),
    );
    expect(result?.macros?.fat, 12);
  });

  testWidgets('the macros for the amount show for YumSum Star only', (
    tester,
  ) async {
    Future<void> open({required bool showMacros}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showPortionSheet(context, _wrap, showMacros: showMacros),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    await open(showMacros: true);
    // 220 g of the wrap.
    expect(
      find.text(_line('Fat 18 g · carbs 53 g · salt 2.0 g')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '100');
    await tester.pump();
    expect(
      find.text(_line('Fat 8 g · carbs 24 g · salt 0.9 g')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await open(showMacros: false);
    expect(find.textContaining('Fat'), findsNothing);
  });

  testWidgets('the sheet shows the pack photo when there is one', (
    tester,
  ) async {
    const withPhoto = (
      name: 'Chicken Tikka Wrap',
      brand: 'Tesco',
      kcalPer100g: 215,
      proteinPer100g: 9,
      macrosPer100g: null,
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

  // Android draws edge to edge, so the navigation bar overlaps the app.
  Future<void> openOverNavigationBar(
    WidgetTester tester, {
    double keyboard = 0,
  }) async {
    final ratio = tester.view.devicePixelRatio;
    tester.view.viewPadding = FakeViewPadding(bottom: 48 * ratio);
    // The engine takes the keyboard off padding, as on a phone.
    tester.view.padding = FakeViewPadding(
      bottom: (48 - keyboard).clamp(0, 48) * ratio,
    );
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard * ratio);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPortionSheet(context, _wrap),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Done sits above the navigation bar', (tester) async {
    await openOverNavigationBar(tester);

    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester.getRect(find.widgetWithText(FilledButton, 'Done')).bottom,
      lessThanOrEqualTo(height - 48),
    );
  });

  testWidgets('Done sits above the keyboard and still scrolls', (tester) async {
    await openOverNavigationBar(tester, keyboard: 400);

    final done = find.widgetWithText(FilledButton, 'Done');
    await tester.scrollUntilVisible(
      done,
      100,
      // The sheet's own, not the text field's.
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getRect(done).bottom, lessThanOrEqualTo(height - 400));
  });
}
