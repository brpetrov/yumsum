import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/recipes/log_recipe_portion.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/bowl_note.dart';
import 'package:lean_streak/widgets/recipe_photo.dart';

/// The recipe library: a search box, what was cooked lately, a filter by
/// meal, and photo tiles under a heading per meal. A tile opens its recipe;
/// its + logs a portion straight away.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _search = TextEditingController();
  RecipeCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      title: 'Recipes',
      body: ref
          .watch(recipesProvider)
          .when(
            data: _buildLibrary,
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: BowlNote('Could not load the recipes.'),
            ),
          ),
    );
  }

  Widget _buildLibrary(List<Recipe> recipes) {
    final meals = ref.watch(recentMealsProvider).valueOrNull ?? const <Meal>[];
    final cooked = recentlyCookedRecipes(recipes, meals, DateTime.now());
    final query = _search.text.trim();
    final found = searchRecipes(recipes, query);
    final sections = {
      for (final category in RecipeCategory.values)
        if (_category == null || category == _category)
          category: [
            for (final recipe in found)
              if (recipe.category == category) recipe,
          ],
    }..removeWhere((_, shown) => shown.isEmpty);
    final label = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    );

    Widget row(List<Widget> children) => SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search recipes or ingredients',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ),
              if (cooked.isNotEmpty && query.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Text('Cooked recently', style: label),
                ),
                row([
                  for (final recipe in cooked)
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: Text(recipe.name),
                      onPressed: () => logRecipePortion(context, ref, recipe),
                    ),
                ]),
              ],
              const SizedBox(height: 12),
              row([
                for (final category in [null, ...RecipeCategory.values])
                  ChoiceChip(
                    label: Text(category?.label ?? 'All'),
                    selected: _category == category,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ]),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (sections.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BowlNote(
                query.isEmpty
                    ? 'No recipes here yet.'
                    : 'No recipes match that. Try other words.',
              ),
            ),
          )
        else
          for (final MapEntry(key: category, value: shown)
              in sections.entries) ...[
            // A heading per meal, unless one meal is picked above.
            if (_category == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Text(
                    category.label,
                    style: AppTheme.display.copyWith(
                      fontSize: 19,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            _grid(shown),
          ],
        // Clear of the phone's navigation bar at the end.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ),
      ],
    );
  }

  Widget _grid(List<Recipe> shown) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
    sliver: SliverGrid(
      gridDelegate: const _TileGrid(),
      delegate: SliverChildBuilderDelegate(
        (_, i) => _RecipeTile(recipe: shown[i]),
        childCount: shown.length,
      ),
    ),
  );
}

/// Two tiles a row on a phone, three on a wider screen, each a 4:3 photo
/// over a fixed block for the words. Worked out at layout, which a scroll
/// repeats every frame, so the tiles themselves aren't rebuilt.
class _TileGrid extends SliverGridDelegate {
  const _TileGrid();

  static const _spacing = 14.0;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width = constraints.crossAxisExtent;
    final columns = width < 520 ? 2 : 3;
    final tile = (width - _spacing * (columns - 1)) / columns;
    final height = tile * 3 / 4 + _RecipeTile.textHeight;
    return SliverGridRegularTileLayout(
      crossAxisCount: columns,
      mainAxisStride: height + _spacing,
      crossAxisStride: tile + _spacing,
      childMainAxisExtent: height,
      childCrossAxisExtent: tile,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_TileGrid oldDelegate) => false;
}

class _RecipeTile extends ConsumerWidget {
  const _RecipeTile({required this.recipe});

  static const textHeight = 112.0;

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showProtein = ref.watch(trackProteinProvider);
    final fits = fitsRemaining(
      recipe,
      ref.watch(remainingCaloriesTodayProvider),
    );
    final muted = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(AppRoutes.recipePath(recipe.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RecipePhoto(recipe),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: IconButton.filled(
                    tooltip: 'Log a portion',
                    onPressed: () => logRecipePortion(context, ref, recipe),
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      fixedSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    '${recipe.kcalPerPortion} kcal',
                    if (showProtein) '${recipe.proteinPerPortion} g protein',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${recipe.minutes} min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ),
                    if (fits)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.veryGood.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Fits today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.veryGood,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
