import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/recipes/recipe_portions_sheet.dart';

/// Asks how many portions of [recipe] were eaten and logs them as today's
/// meal, with the recipe's own protein and macros (so no AI estimate is
/// needed). Says how it went in a snackbar.
Future<void> logRecipePortion(
  BuildContext context,
  WidgetRef ref,
  Recipe recipe,
) async {
  final portions = await showRecipePortionsSheet(
    context,
    recipe,
    showProtein: ref.read(trackProteinProvider),
  );
  if (portions == null || !context.mounted) return;

  await ref
      .read(logMealControllerProvider.notifier)
      .submit(
        name: recipe.mealName(portions, context.l10n),
        calories: recipe.kcalFor(portions).toDouble(),
        proteinGrams: recipe.proteinFor(portions).toDouble(),
        macros: recipe.macrosFor(portions),
      );
  if (!context.mounted) return;
  final failed = ref.read(logMealControllerProvider).hasError;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        failed
            ? context.l10n.recipesErrorLog
            : context.l10n.recipesLogged(
                recipe.mealName(portions, context.l10n),
              ),
      ),
    ),
  );
}
