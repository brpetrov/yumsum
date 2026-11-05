import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';

/// What each macro does for you and how its target is set, in three groups
/// that match how the rings are judged: aim for, keep in balance and keep
/// under. No figures: the rings have those. [withProtein] leaves protein
/// out where it isn't shown; [withCalories] starts with the calorie target,
/// for Today's card.
Future<void> showMacroGuide(
  BuildContext context, {
  bool withProtein = true,
  bool withCalories = false,
}) {
  const calories = (
    'Calories',
    'The energy in food. Eat less than you burn and you lose weight.',
    'What you burn in a day, from your age, height, weight and activity, '
        'with a little taken off if you\'re losing weight.',
  );
  final groups = [
    (
      'Aim for',
      AppColors.veryGood,
      [
        if (withProtein)
          (
            'Protein',
            'Keeps you full and protects your muscle while you lose fat.',
            '1.2 to 2 g per kg of your goal weight, more the more you train.',
          ),
        (
          'Fibre',
          'Keeps you full and your gut healthy.',
          'At least 30 g a day.',
        ),
      ],
    ),
    (
      'Keep in balance',
      AppColors.primary,
      [
        (
          'Carbs',
          'Your main fuel: bread, rice, pasta, potatoes and fruit.',
          'What\'s left after protein and fat.',
        ),
        (
          'Fat',
          'Energy, and it helps you absorb vitamins.',
          'About 30% of your calories.',
        ),
      ],
    ),
    (
      'Keep under',
      AppColors.bad,
      [
        (
          'Sugars',
          'Calories that don\'t fill you up, and bad for your teeth.',
          'Under 18% of your calories.',
        ),
        (
          'Saturates',
          'Raises your cholesterol: butter, cheese, fatty meat and cakes.',
          'Under 10% of your calories.',
        ),
        (
          'Salt',
          'Raises your blood pressure. Most is hidden in bread, cheese and '
              'ready meals.',
          'Under 6 g a day, about a teaspoon.',
        ),
      ],
    ),
  ];
  // Under the Keep under heading: why, once for all three.
  const keepUnder =
      'Keep these under the amounts shown. Going over day after day is what '
      'harms your teeth, heart and blood pressure.';
  final body = TextStyle(
    fontSize: 13.5,
    height: 1.35,
    color: AppColors.textSecondary,
  );
  List<Widget> item((String, String, String) entry) {
    final (name, why, target) = entry;
    return [
      const SizedBox(height: 10),
      Text(
        name,
        style: AppTheme.display.copyWith(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 2),
      Text(why, style: body),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Target: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(text: target),
          ],
        ),
        style: body,
      ),
    ];
  }

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      // 150 shorter than the usual full height on a phone; the rest scrolls.
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 99),
      title: Text(withCalories ? 'Your targets' : 'Your macros'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your targets come from your plan, so they change with it.',
              style: body,
            ),
            if (withCalories) ...item(calories),
            for (final (group, color, items) in groups) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (group == 'Keep under') ...[
                const SizedBox(height: 6),
                Text(keepUnder, style: body),
              ],
              for (final entry in items) ...item(entry),
            ],
            const SizedBox(height: 18),
            Text(
              'General guidance for adults, not medical advice.',
              style: body.copyWith(fontSize: 12.5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
