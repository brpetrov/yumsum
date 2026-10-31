import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/recipes/log_recipe_portion.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/recipe_photo.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// One recipe: photo, nutrition per portion, ingredients and method, and a
/// button to log a portion. [recipe] is given when it isn't in the library
/// (a suggestion); otherwise it's found there by [recipeId].
class RecipeScreen extends ConsumerWidget {
  const RecipeScreen({super.key, required this.recipeId, this.recipe});

  final String recipeId;
  final Recipe? recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(recipesProvider);
    final found =
        recipe ??
        library.valueOrNull?.where((r) => r.id == recipeId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recipe')),
      body: found != null
          ? _RecipeBody(recipe: found)
          : library.isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Center(
              child: Text(
                'Could not load the recipe.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
      bottomNavigationBar: found == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: FilledButton.icon(
                  onPressed: () => logRecipePortion(context, ref, found),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Log a portion'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
    );
  }
}

class _RecipeBody extends ConsumerWidget {
  const _RecipeBody({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showProtein = ref.watch(trackProteinProvider);
    final fits = fitsRemaining(
      recipe,
      ref.watch(remainingCaloriesTodayProvider),
    );
    final muted = TextStyle(fontSize: 14.5, color: AppColors.textSecondary);
    final heading = AppTheme.display.copyWith(
      fontSize: 19,
      color: AppColors.textPrimary,
    );

    return SingleChildScrollView(
      child: ResponsivePage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: RecipePhoto(recipe),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              recipe.name,
              style: AppTheme.display.copyWith(
                fontSize: 26,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [recipe.cuisine, ?recipe.description].join(' · '),
              style: muted,
            ),
            const SizedBox(height: 12),
            Text(
              showProtein
                  ? '${recipe.kcalPerPortion} kcal · '
                        '${recipe.proteinPerPortion} g protein per portion'
                  : '${recipe.kcalPerPortion} kcal per portion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${recipe.minutes} min · serves ${recipe.servings}',
              style: muted,
            ),
            if (fits) ...[
              const SizedBox(height: 2),
              Text(
                'Fits what\'s left today',
                style: muted.copyWith(color: AppColors.veryGood),
              ),
            ],
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingredients', style: heading),
                  Text('For ${recipe.servings} portions', style: muted),
                  const SizedBox(height: 10),
                  for (final ingredient in recipe.ingredients)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 96,
                            child: Text(ingredient.amount, style: muted),
                          ),
                          Expanded(
                            child: Text(
                              ingredient.item,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Method', style: heading),
                  const SizedBox(height: 10),
                  for (final (i, step) in recipe.steps.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${i + 1}.',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
