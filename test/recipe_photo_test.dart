import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/widgets/recipe_photo.dart';

import 'recipe_fixtures.dart';

void main() {
  Future<void> pumpPhoto(WidgetTester tester, ImageProvider image) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [recipeImageProvider.overrideWithValue((_) => image)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: RecipePhoto(testRecipe('Pasta bolognese')),
              ),
            ),
          ),
        ),
      );

  Future<void> letItLoad(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }

  testWidgets('a spinner until the photo arrives, then the photo', (
    tester,
  ) async {
    await pumpPhoto(tester, MemoryImage(testPixel));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await letItLoad(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.restaurant_outlined), findsNothing);
  });

  testWidgets('a plain box when the photo can\'t be had', (tester) async {
    await pumpPhoto(tester, MemoryImage(Uint8List.fromList([1, 2, 3])));
    await letItLoad(tester);
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
  });
}
