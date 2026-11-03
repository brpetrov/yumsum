import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

/// What each macro is for and the UK's daily guide for adults, beside the
/// day's [total]: the info button on the macros summary. The saturates guide follows
/// the profile's gender.
Future<void> showMacroGuide(BuildContext context, Nutrients total) {
  return showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final gender = ref.watch(userProfileProvider).valueOrNull?.gender;
        final saturates = switch (gender) {
          Gender.male => 'No more than 30 g a day for men.',
          Gender.female => 'No more than 20 g a day for women.',
          _ => 'No more than 30 g a day for men, 20 g for women.',
        };
        final rows = [
          (
            'Fat',
            total.fat,
            'Energy, and it helps you take in some vitamins. Food labels '
                'use 70 g a day as a guide for an adult.',
          ),
          (
            'Saturates',
            total.saturates,
            'The fat to watch for your heart: butter, cheese, fatty meat, '
                'pastry and cakes. $saturates',
          ),
          (
            'Carbs',
            total.carbs,
            'Your body\'s main fuel: bread, rice, pasta, potatoes and fruit. '
                'Food labels use 260 g a day as a guide.',
          ),
          (
            'Sugars',
            total.sugars,
            'All sugars, the ones in fruit and milk too. Of the added kind '
                '(sweets, fizzy drinks, honey, juice), no more than 30 g a '
                'day.',
          ),
          (
            'Fibre',
            total.fibre,
            'Keeps you full and your gut healthy: wholegrains, beans, '
                'lentils, vegetables and fruit. Aim for at least 30 g a day.',
          ),
          (
            'Salt',
            total.salt,
            'Too much raises your blood pressure. No more than 6 g a day, '
                'about a teaspoon. Most of it is already in bread, cheese, '
                'ready meals and sauces.',
          ),
        ];
        final muted = TextStyle(
          fontSize: 13.5,
          height: 1.4,
          color: AppColors.textSecondary,
        );

        return AlertDialog(
          title: const Text('About your macros'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (name, grams, about) in rows) ...[
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
                          '${name == 'Salt' ? grams.toStringAsFixed(1) : grams.round()} g',
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
                  'The UK\'s guides for adults, not personal targets. The '
                  'figures count only the meals with macro info.',
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
