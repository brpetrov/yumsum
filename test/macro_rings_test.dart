import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/widgets/macro_rings.dart';

Meal _meal(String name, double protein, Nutrients? macros) => Meal(
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
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.value(null),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );

  testWidgets('protein, fat and carbs first, against targets from the plan', (
    tester,
  ) async {
    await pump(
      tester,
      MacroRings(
        meals: [_wrap, _meal('Toast', 6, null)],
        calorieTarget: 1670,
        proteinTarget: 131,
        trackProtein: true,
      ),
    );
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('44 g'), findsOneWidget);
    expect(find.text('of 131 g'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('18 g'), findsOneWidget);
    expect(find.text('of 56 g'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('of 161 g'), findsOneWidget);
    expect(find.text('1 meal not counted (no macro info)'), findsOneWidget);

    // The rest scroll in from the right.
    await tester.dragUntilVisible(
      find.text('Salt'),
      find.byType(SingleChildScrollView),
      const Offset(-100, 0),
    );
    expect(find.text('2.1 g'), findsOneWidget);
    expect(find.text('max 6 g'), findsOneWidget);
  });

  testWidgets('without protein tracking, fat comes first', (tester) async {
    await pump(
      tester,
      MacroRings(
        meals: [_wrap],
        calorieTarget: 1670,
        proteinTarget: 131,
        trackProtein: false,
      ),
    );
    expect(find.text('Protein'), findsNothing);
    expect(find.text('Fat'), findsOneWidget);
  });

  testWidgets('nothing logged reads as nothing eaten yet', (tester) async {
    await pump(
      tester,
      const MacroRings(
        meals: [],
        calorieTarget: 1670,
        proteinTarget: 131,
        trackProtein: true,
      ),
    );
    // Every ring but salt, which has a decimal.
    expect(find.text('0 g'), findsNWidgets(6));
    expect(find.textContaining('not counted'), findsNothing);
  });

  testWidgets('the info button explains them', (tester) async {
    await pump(
      tester,
      MacroRings(
        meals: [_wrap],
        calorieTarget: 1670,
        proteinTarget: 131,
        trackProtein: true,
      ),
    );
    await tester.tap(find.byTooltip('About macros'));
    await tester.pumpAndSettle();
    expect(find.text('About your macros'), findsOneWidget);
    expect(find.textContaining('about 30% of your calories'), findsOneWidget);
  });

  testWidgets('without YumSum Star a tap opens it', (tester) async {
    var opened = 0;
    await pump(tester, MacroRingsTeaser(onTap: () => opened++));
    expect(find.text('Become a Star'), findsOneWidget);
    await tester.tap(find.text('Macros'));
    expect(opened, 1);
  });
}
