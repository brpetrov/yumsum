import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';

/// What each macro does for you and how its target is set, in three groups
/// that match how the rings are judged: aim for, keep in balance and keep
/// under. No figures: the rings have those. [withProtein] leaves protein
/// out where it isn't shown.
Future<void> showMacroGuide(BuildContext context, {bool withProtein = true}) {
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
          'At least 30 g a day, the UK advice for adults.',
        ),
      ],
    ),
    (
      'Keep in balance',
      AppColors.primary,
      [
        (
          'Carbs',
          'Your body\'s main fuel: bread, rice, pasta, potatoes and fruit.',
          'What\'s left of your calories after protein and fat.',
        ),
        (
          'Fat',
          'Energy, and it helps you absorb vitamins A, D, E and K.',
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
          'Added sugar brings calories without filling you up, and harms '
              'your teeth.',
          'At most 18% of your calories, the food-label guide. Keep added '
              'sugar under 30 g.',
        ),
        (
          'Saturates',
          'Too much raises your cholesterol: butter, cheese, fatty meat and '
              'cakes.',
          'At most 10% of your calories, the UK advice.',
        ),
        (
          'Salt',
          'Too much raises your blood pressure. Most is already in bread, '
              'cheese and ready meals.',
          'At most 6 g a day, about a teaspoon.',
        ),
      ],
    ),
  ];
  final body = TextStyle(
    fontSize: 13.5,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Your macros'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your targets come from your plan, so they change with it.',
              style: body,
            ),
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
              for (final (name, why, target) in items) ...[
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
              ],
            ],
            const SizedBox(height: 18),
            Text(
              'A ring turns amber, then red, when you go well over a balance '
              'target or past a limit. General guidance for adults, not '
              'medical advice.',
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
