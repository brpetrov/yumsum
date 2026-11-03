import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/recipes/log_recipe_portion.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/macro_totals.dart';
import 'package:lean_streak/widgets/recipe_photo.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// One recipe: photo, nutrition per portion, prep and cooking time,
/// ingredients and steps, and a button to log a portion. [recipe] is given
/// when it isn't in the library (a suggestion); otherwise it's found there
/// by [recipeId].
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
              child: Align(
                heightFactor: 1,
                child: ConstrainedBox(
                  // Phone-sized on a tablet, not a bar across the screen.
                  constraints: const BoxConstraints(maxWidth: 480),
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
              ),
            ),
    );
  }
}

/// Wide enough to put the photo beside the title and the ingredients
/// beside the steps: a tablet, a phone on its side, or the web.
const _sideBySideWidth = 600.0;

class _RecipeBody extends ConsumerWidget {
  const _RecipeBody({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showProtein = ref.watch(trackProteinProvider);
    final showMacros = ref.watch(showMacrosProvider);
    final fits = fitsRemaining(
      recipe,
      ref.watch(remainingCaloriesTodayProvider),
    );
    final muted = TextStyle(fontSize: 14.5, color: AppColors.textSecondary);

    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: AspectRatio(aspectRatio: 4 / 3, child: RecipePhoto(recipe)),
    );
    final about = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          recipe.name,
          style: AppTheme.display.copyWith(
            fontSize: 26,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text([recipe.cuisine, ?recipe.description].join(' · '), style: muted),
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
        if (showMacros) ...[
          const SizedBox(height: 2),
          Text(macrosLine(recipe.macrosPerPortion), style: muted),
        ],
        if (fits) ...[
          const SizedBox(height: 2),
          Text(
            'Fits what\'s left today',
            style: muted.copyWith(color: AppColors.veryGood),
          ),
        ],
        const SizedBox(height: 16),
        _Facts(recipe: recipe),
      ],
    );
    final ingredients = _Ingredients(recipe: recipe);
    final steps = _Steps(recipe: recipe);

    return SingleChildScrollView(
      child: ResponsivePage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth < _sideBySideWidth
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    photo,
                    const SizedBox(height: 18),
                    about,
                    const SizedBox(height: 16),
                    ingredients,
                    const SizedBox(height: 16),
                    steps,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 5, child: photo),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: about),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: ingredients),
                        const SizedBox(width: 16),
                        Expanded(flex: 7, child: steps),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

TextStyle get _heading =>
    AppTheme.display.copyWith(fontSize: 19, color: AppColors.textPrimary);

/// Prep, cooking and portions at a glance.
class _Facts extends StatelessWidget {
  const _Facts({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    Widget fact(IconData icon, String value, String label) => Expanded(
      child: Column(
        children: [
          IconBubble(icon, size: 36),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.display.copyWith(
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fact(Icons.timer_outlined, '${recipe.prepMinutes} min', 'Prep'),
          fact(
            Icons.local_fire_department_outlined,
            recipe.cookMinutes == 0 ? 'None' : '${recipe.cookMinutes} min',
            'Cook',
          ),
          fact(Icons.people_outline_rounded, '${recipe.servings}', 'Serves'),
        ],
      ),
    );
  }
}

final _numberSpace = RegExp(r'(\d) ');

class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingredients', style: _heading),
          Text(
            recipe.servings == 1
                ? 'For 1 portion'
                : 'For ${recipe.servings} portions',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          for (final (i, ingredient) in recipe.ingredients.indexed) ...[
            if (i > 0) Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      // A number stays with its unit: "2 tins" / "(800 g)",
                      // never "(800" / "g)".
                      ingredient.amount.replaceAllMapped(
                        _numberSpace,
                        (m) => '${m[1]} ',
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient.item,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Times and oven temperatures in a step: "5 minutes", "10 to 12 minutes",
/// "220°C (200°C fan)".
final _timeOrHeat = RegExp(
  r'\d+(?: to \d+)? (?:minutes?|seconds?|hours?)|\d+°C(?: \(\d+°C fan\))?',
);

class _Steps extends StatelessWidget {
  const _Steps({required this.recipe});

  final Recipe recipe;

  /// [step] with its times and temperatures in bold, so they stand out.
  static TextSpan _spans(String step) {
    final strong = TextStyle(
      fontWeight: FontWeight.w800,
      color: AppColors.onPrimaryContainer,
    );
    final spans = <TextSpan>[];
    var at = 0;
    for (final match in _timeOrHeat.allMatches(step)) {
      spans
        ..add(TextSpan(text: step.substring(at, match.start)))
        ..add(TextSpan(text: match[0], style: strong));
      at = match.end;
    }
    spans.add(TextSpan(text: step.substring(at)));
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to make it', style: _heading),
          const SizedBox(height: 14),
          for (final (i, step) in recipe.steps.indexed)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == recipe.steps.length - 1 ? 0 : 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text.rich(
                        _spans(step),
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
