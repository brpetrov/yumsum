import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/widgets/macro_totals.dart';

/// One meal as a plain row: name and time, calories and protein, and a menu
/// with Edit and Delete. With [showMacros] (YumSum Star), a tap on the row
/// shows the meal's macros under it.
class MealRow extends StatefulWidget {
  const MealRow({
    super.key,
    required this.meal,
    required this.onEdit,
    required this.onDelete,
    this.showProtein = true,
    this.showMacros = false,
  });

  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showProtein;
  final bool showMacros;

  @override
  State<MealRow> createState() => _MealRowState();
}

class _MealRowState extends State<MealRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final name = (meal.name?.trim().isNotEmpty ?? false)
        ? meal.name!.trim()
        : 'Unnamed meal';

    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('HH:mm').format(meal.timestamp),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${meal.calories.round()} kcal',
              style: AppTheme.display.copyWith(
                fontSize: 16.5,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.showProtein && meal.proteinGrams != null) ...[
              const SizedBox(height: 3),
              Text(
                '${meal.proteinGrams!.round()} g protein',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        PopupMenuButton<_MealAction>(
          tooltip: 'Meal options',
          onSelected: (action) => switch (action) {
            _MealAction.edit => widget.onEdit(),
            _MealAction.delete => widget.onDelete(),
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _MealAction.edit, child: Text('Edit')),
            PopupMenuItem(value: _MealAction.delete, child: Text('Delete')),
          ],
        ),
      ],
    );
    if (!widget.showMacros) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: row,
      );
    }

    // Only the menu was tappable before, so a tap anywhere else is free.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row,
            if (_open)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 14),
                child: Text(
                  meal.macros == null
                      ? 'No macro info for this meal.'
                      : macrosLine(meal.macros!),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _MealAction { edit, delete }
