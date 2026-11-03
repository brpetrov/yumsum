import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/widgets/macro_rings.dart';

Meal _meal(String name, double? protein, Nutrients? macros) => Meal(
  id: name,
  date: '2026-11-04',
  timestamp: DateTime(2026, 11, 4, 12),
  name: name,
  calories: 500,
  proteinGrams: protein,
  macros: macros,
  createdAt: DateTime(2026, 11, 4, 12),
  updatedAt: DateTime(2026, 11, 4, 12),
);

Meal _withCarbs(double carbs) => _meal(
  'Pasta',
  20,
  Nutrients(fat: 10, saturates: 2, carbs: carbs, sugars: 5, fibre: 4, salt: 1),
);

final _wrap = _meal(
  'Chicken wrap',
  38,
  const Nutrients(
    fat: 18,
    saturates: 6,
    carbs: 52,
    sugars: 5,
    fibre: 4,
    salt: 2.1,
  ),
);

void main() {
  var unlocked = 0;

  Future<void> pump(
    WidgetTester tester,
    List<Meal> meals, {
    bool full = true,
    bool trackProtein = true,
  }) {
    unlocked = 0;
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(null),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MacroRings(
              meals: meals,
              calorieTarget: 1670,
              proteinTarget: 131,
              trackProtein: trackProtein,
              full: full,
              onUnlock: () => unlocked++,
            ),
          ),
        ),
      ),
    );
  }

  /// The colour the ring around [figure] is drawn in.
  Color ringColor(WidgetTester tester, String figure) {
    final paint = tester.widget<CustomPaint>(
      find
          .ancestor(of: find.text(figure), matching: find.byType(CustomPaint))
          .first,
    );
    return (paint.painter as dynamic).color as Color;
  }

  testWidgets('protein first, then carbs and fat, against the plan', (
    tester,
  ) async {
    await pump(tester, [_wrap, _meal('Toast', 6, null)]);
    final names = [
      for (final name in ['Protein', 'Carbs', 'Fat'])
        tester.getTopLeft(find.text(name)).dx,
    ];
    expect(names, orderedEquals([...names]..sort()));
    expect(find.text('44 g'), findsOneWidget);
    expect(find.text('of 131 g'), findsOneWidget);
    expect(find.text('of 161 g'), findsOneWidget);
    expect(find.text('of 56 g'), findsOneWidget);
    expect(find.text('Macros'), findsNothing);
    expect(find.text('1 meal not counted (no macro info)'), findsOneWidget);

    // Then fibre, and the limits, scrolling in from the right.
    await tester.dragUntilVisible(
      find.text('Salt'),
      find.byType(SingleChildScrollView),
      const Offset(-100, 0),
    );
    expect(find.text('2.1 g'), findsOneWidget);
    expect(find.text('max 6 g'), findsOneWidget);
  });

  testWidgets('carbs go amber past 10% over, red past 20%', (tester) async {
    await pump(tester, [_withCarbs(175)]);
    expect(ringColor(tester, '175 g'), AppColors.veryGood);
    await pump(tester, [_withCarbs(185)]);
    expect(ringColor(tester, '185 g'), AppColors.bad);
    await pump(tester, [_withCarbs(200)]);
    expect(ringColor(tester, '200 g'), AppColors.veryBad);
  });

  testWidgets('more protein than the target stays green', (tester) async {
    await pump(tester, [_meal('Steak', 160, null)]);
    expect(ringColor(tester, '160 g'), AppColors.veryGood);
  });

  testWidgets('without protein tracking, carbs come first', (tester) async {
    await pump(tester, [_wrap], trackProtein: false);
    expect(find.text('Protein'), findsNothing);
    expect(find.text('Carbs'), findsOneWidget);
  });

  testWidgets('nothing logged reads as nothing eaten yet', (tester) async {
    await pump(tester, const []);
    // Every ring but salt, which has a decimal.
    expect(find.text('0 g'), findsNWidgets(6));
    expect(find.textContaining('not counted'), findsNothing);
  });

  testWidgets('a ring or the info button explains them', (tester) async {
    await pump(tester, [_wrap]);
    await tester.tap(find.text('Fat'));
    await tester.pumpAndSettle();
    expect(find.text('About your macros'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('About macros'));
    await tester.pumpAndSettle();
    expect(find.textContaining('about 30% of your calories'), findsOneWidget);
  });

  testWidgets('without YumSum Star, protein alone is live', (tester) async {
    await pump(tester, [_wrap], full: false);
    expect(find.text('38 g'), findsOneWidget);
    expect(find.text('of 131 g'), findsOneWidget);
    // The rest are there to see, with no figures, under the chip.
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('52 g'), findsNothing);
    expect(find.textContaining('no macro info'), findsNothing);

    await tester.tap(find.text('Unlock full macros'));
    expect(unlocked, 1);
    await tester.tap(find.text('Carbs'));
    expect(unlocked, 2);
  });
}
