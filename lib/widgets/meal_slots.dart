import 'dart:math';

import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';

/// The part of the day a meal was eaten in.
enum MealSlot { morning, afternoon, evening }

/// Morning before 12:00, afternoon from 12:00 to 16:59, evening from 17:00.
MealSlot mealSlotOf(DateTime time) => time.hour < 12
    ? MealSlot.morning
    : time.hour < 17
    ? MealSlot.afternoon
    : MealSlot.evening;

/// [meals] by slot, in slot order and each slot's by time, leaving out the
/// slots with none.
Map<MealSlot, List<Meal>> mealsBySlot(List<Meal> meals) {
  final sorted = [...meals]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final bySlot = {for (final slot in MealSlot.values) slot: <Meal>[]};
  for (final meal in sorted) {
    bySlot[mealSlotOf(meal.timestamp)]!.add(meal);
  }
  return bySlot..removeWhere((_, inSlot) => inSlot.isEmpty);
}

/// The calories of [meals], each rounded as its row shows it, and their
/// protein, null when none of them has any.
({int kcal, int? protein}) mealTotals(List<Meal> meals) {
  final proteins = meals.map((meal) => meal.proteinGrams).nonNulls;
  return (
    kcal: meals.fold(0, (sum, meal) => sum + meal.calories.round()),
    protein: proteins.isEmpty
        ? null
        : proteins.fold<double>(0, (sum, grams) => sum + grams).round(),
  );
}

/// A day's meals in morning, afternoon and evening, each under a header row
/// with its name, how many it holds while folded, and its calories (and
/// protein, by the rule a [MealRow] follows). A tap on a header opens or
/// folds it; under an open one are its meals, as [mealRow] builds them.
///
/// With [now] (Home), the slot holding it starts open and the earlier ones
/// folded; when every slot with meals is earlier, the latest of them starts
/// open. Without it (History), every slot starts open.
class MealSlots extends StatefulWidget {
  const MealSlots({
    super.key,
    required this.meals,
    required this.mealRow,
    required this.showProtein,
    this.now,
  });

  final List<Meal> meals;
  final Widget Function(Meal meal) mealRow;
  final bool showProtein;
  final DateTime? now;

  @override
  State<MealSlots> createState() => _MealSlotsState();
}

class _MealSlotsState extends State<MealSlots> {
  /// The slots the user opened or folded; the rest start as [MealSlots.now]
  /// says.
  final _open = <MealSlot, bool>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slots = mealsBySlot(widget.meals);
    final now = widget.now;
    // Slots from this one on start open.
    final openFrom = now == null || slots.isEmpty
        ? 0
        : min(mealSlotOf(now).index, slots.keys.last.index);

    final children = <Widget>[];
    for (final MapEntry(key: slot, value: meals) in slots.entries) {
      final open = _open[slot] ?? slot.index >= openFrom;
      final totals = mealTotals(meals);
      children.add(const SizedBox(height: 6));
      children.add(
        _SlotHeader(
          key: ValueKey(slot),
          name: switch (slot) {
            MealSlot.morning => l10n.homeSlotMorning,
            MealSlot.afternoon => l10n.homeSlotAfternoon,
            MealSlot.evening => l10n.homeSlotEvening,
          },
          count: l10n.homeSlotItems(meals.length),
          totals: widget.showProtein && totals.protein != null
              ? l10n.homeSlotTotal(totals.kcal, totals.protein!)
              : l10n.commonKcal(totals.kcal),
          open: open,
          onTap: () => setState(() => _open[slot] = !open),
        ),
      );
      if (!open) continue;
      for (final (index, meal) in meals.indexed) {
        if (index > 0) {
          children.add(const Divider(height: 1, indent: 12, endIndent: 14));
        }
        children.add(
          Padding(
            key: ValueKey(meal.id),
            padding: const EdgeInsets.only(left: 12),
            child: widget.mealRow(meal),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// A slot's name, its count while folded, its totals and a chevron, all one
/// tap target on a tinted band, so it reads apart from the meals under it.
class _SlotHeader extends StatelessWidget {
  const _SlotHeader({
    super.key,
    required this.name,
    required this.count,
    required this.totals,
    required this.open,
    required this.onTap,
  });

  final String name;
  final String count;
  final String totals;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      expanded: open,
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.display.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!open)
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // A big slot's totals shrink a little on a narrow phone, rather
                // than break the name or wrap.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      totals,
                      style: AppTheme.display.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                // As wide as a row's menu, so the chevrons line up with the ⋮s.
                SizedBox(
                  width: 48,
                  child: Icon(
                    open
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
