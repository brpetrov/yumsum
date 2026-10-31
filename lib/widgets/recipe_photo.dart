import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/recipe_provider.dart';

/// A recipe's photo from the website, filling its box: a spinner until it
/// arrives (kept on the phone after the first time), a plain box if it
/// can't be had, e.g. offline before it was ever seen.
class RecipePhoto extends ConsumerWidget {
  const RecipePhoto(this.recipe, {super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget box(Widget child) => ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(child: child),
    );
    return Image(
      image: ref.watch(recipeImageProvider)(recipe.photoUrl),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (_, image, frame, synchronous) =>
          synchronous || frame != null
          ? image
          : box(
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
      errorBuilder: (_, _, _) =>
          box(Icon(Icons.restaurant_outlined, color: AppColors.textSecondary)),
    );
  }
}
