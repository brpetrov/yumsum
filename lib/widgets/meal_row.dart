import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';

/// One meal as a plain row: name and time, calories and protein, and a menu
/// with Edit and Delete.
class MealRow extends StatelessWidget {
  const MealRow({
    super.key,
    required this.meal,
    required this.onEdit,
    required this.onDelete,
    this.showProtein = true,
  });

  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showProtein;

  @override
  Widget build(BuildContext context) {
    final name = (meal.name?.trim().isNotEmpty ?? false)
        ? meal.name!.trim()
        : 'Unnamed meal';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
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
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
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
              if (showProtein && meal.proteinGrams != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${meal.proteinGrams!.round()} g protein',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          PopupMenuButton<_MealAction>(
            tooltip: 'Meal options',
            onSelected: (action) => switch (action) {
              _MealAction.edit => onEdit(),
              _MealAction.delete => onDelete(),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _MealAction.edit, child: Text('Edit')),
              PopupMenuItem(value: _MealAction.delete, child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

enum _MealAction { edit, delete }
