import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

/// What each macro is for and how its target is set, beside the day's
/// [total] and [protein] (null when protein isn't tracked): the info button
/// on the macros. Targets come from the profile's plan
/// ([HealthCalculator.macroTargets]).
Future<void> showMacroGuide(
  BuildContext context,
  Nutrients? total, {
  double? protein,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(userProfileProvider).valueOrNull;
        final proteinTarget = profile == null
            ? null
            : HealthCalculator.proteinTargetGrams(
                targetWeightKg: profile.targetWeightKg,
                trainingFrequency: profile.trainingFrequency,
              );
        final targets = profile == null
            ? null
            : HealthCalculator.macroTargets(
                calories: profile.dailyCalorieTarget.round(),
                proteinGrams: proteinTarget!,
              );
        final rows = [
          if (protein != null)
            (
              'Protein',
              protein,
              proteinTarget,
              false,
              'Keeps you full and holds on to muscle while you lose fat. '
                  'Your target comes from your goal weight and how often you '
                  'train.',
            ),
          (
            'Fat',
            total?.fat,
            targets?.fat,
            false,
            'Energy, and it helps you take in some vitamins. Your target is '
                'about 30% of your calories.',
          ),
          (
            'Carbs',
            total?.carbs,
            targets?.carbs,
            false,
            'Your body\'s main fuel: bread, rice, pasta, potatoes and fruit. '
                'Your target is what\'s left of your calories after protein '
                'and fat.',
          ),
          (
            'Saturates',
            total?.saturates,
            targets?.saturates,
            true,
            'The fat to watch for your heart: butter, cheese, fatty meat, '
                'pastry and cakes. UK advice is no more than a tenth of your '
                'calories.',
          ),
          (
            'Sugars',
            total?.sugars,
            targets?.sugars,
            true,
            'All sugars, the ones in fruit and milk too: the food-label '
                'guide, for your calories. Of the added kind (sweets, fizzy '
                'drinks, honey, juice), keep to under 30 g.',
          ),
          (
            'Fibre',
            total?.fibre,
            targets?.fibre,
            false,
            'Keeps you full and your gut healthy: wholegrains, beans, '
                'lentils, vegetables and fruit. At least 30 g a day for every '
                'adult.',
          ),
          (
            'Salt',
            total?.salt,
            targets?.salt,
            true,
            'Too much raises your blood pressure. No more than 6 g a day, '
                'about a teaspoon, for every adult. Most of it is already in '
                'bread, cheese, ready meals and sauces.',
          ),
        ];
        final muted = TextStyle(
          fontSize: 13.5,
          height: 1.4,
          color: AppColors.textSecondary,
        );

        String figure(String name, double grams, int? target, bool limit) {
          final eaten = name == 'Salt'
              ? grams.toStringAsFixed(1)
              : '${grams.round()}';
          if (target == null) return '$eaten g';
          return limit ? '$eaten g, max $target g' : '$eaten of $target g';
        }

        return AlertDialog(
          title: const Text('About your macros'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (name, grams, target, limit, about) in rows) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTheme.display.copyWith(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (grams != null)
                        Text(
                          figure(name, grams, target, limit),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(about, style: muted),
                  const SizedBox(height: 14),
                ],
                Text(
                  'Fat, carbs, saturates and sugars follow your daily '
                  'calories, so they adjust with your plan. Guides from UK '
                  'advice for adults, not medical advice. The figures count '
                  'only the meals with macro info.',
                  style: muted.copyWith(fontSize: 12.5),
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
        );
      },
    ),
  );
}
