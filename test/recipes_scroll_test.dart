import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/recipes/recipes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recipe_fixtures.dart';

void main() {
  testWidgets('scrolling the recipes does not rebuild the tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final recipes = [
      for (final category in RecipeCategory.values)
        for (var i = 0; i < 6; i++)
          testRecipe('${category.label} $i', category: category),
    ];
    // Each tile asks for its photo when it builds.
    var photoBuilds = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipesProvider.overrideWith((ref) async => recipes),
          recipeImageProvider.overrideWithValue((url) {
            photoBuilds++;
            return pixelImage(url);
          }),
          recentMealsProvider.overrideWith((ref) => Stream.value([])),
          dailySummaryForDateProvider.overrideWith(
            (ref, date) => Stream.value(null),
          ),
          currentUidProvider.overrideWithValue('user-1'),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const RecipesScreen()),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    photoBuilds = 0;
    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3));
      await tester.pump();
    }
    expect(photoBuilds, 0);
  });
}
