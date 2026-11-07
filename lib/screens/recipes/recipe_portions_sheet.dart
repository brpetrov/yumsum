import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/widgets/recipe_photo.dart';

/// Asks how many portions of [recipe] were eaten, in halves from ½ to 10;
/// resolves to the number, or null if the sheet was dismissed.
Future<double?> showRecipePortionsSheet(
  BuildContext context,
  Recipe recipe, {
  bool showProtein = true,
}) => showModalBottomSheet<double>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  builder: (_) => _PortionsSheet(recipe: recipe, showProtein: showProtein),
);

class _PortionsSheet extends StatefulWidget {
  const _PortionsSheet({required this.recipe, required this.showProtein});

  final Recipe recipe;
  final bool showProtein;

  @override
  State<_PortionsSheet> createState() => _PortionsSheetState();
}

class _PortionsSheetState extends State<_PortionsSheet> {
  static const _min = 0.5;
  static const _max = 10.0;

  double _portions = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recipe = widget.recipe;
    final kcal = recipe.kcalFor(_portions);
    final protein = recipe.proteinFor(_portions);
    final muted = TextStyle(fontSize: 14, color: AppColors.textSecondary);

    Widget step(IconData icon, String tooltip, double by) {
      final next = _portions + by;
      return IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: next < _min || next > _max
            ? null
            : () => setState(() => _portions = next),
        icon: Icon(icon),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 72,
                  child: RecipePhoto(recipe),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.nameIn(l10n.localeName),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.recipesHowMany, style: muted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              step(Icons.remove_rounded, l10n.recipesLess, -0.5),
              SizedBox(
                width: 72,
                child: Text(
                  l10n.decimal(_portions, _portions % 1 == 0 ? 0 : 1),
                  key: const ValueKey('recipe-portions'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              step(Icons.add_rounded, l10n.recipesMore, 0.5),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              l10n.recipesKcal(kcal),
              if (widget.showProtein) l10n.recipesProtein(protein),
            ].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_portions),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(l10n.recipesLog),
          ),
        ],
      ),
    );
  }
}
