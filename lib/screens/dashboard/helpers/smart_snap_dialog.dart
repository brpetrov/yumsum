import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Smart Snap (photo logging) in one line, under its name in the dialog.
const smartSnapSubtitle = 'Make food logging as easy as taking a photo.';

/// Sells Smart Snap to someone without YumSum Star, from the bar's photo
/// button. It is simple, so the dialog is small: the bowl with its camera
/// (assets/smart_snap.webp, trimmed and shrunk to 720 px) over the name and
/// the line, two promises, and Become a Star, which opens the YumSum Star
/// page.
Future<void> showSmartSnapIntro(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        children: [
          Image.asset(
            'assets/smart_snap.webp',
            width: 120,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(height: 10),
          const Text('Smart Snap'),
          const SizedBox(height: 4),
          Text(
            smartSnapSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      content: const FeaturePromises([
        (
          Icons.auto_awesome_rounded,
          'Skip the manual entry',
          'Snap your meal and let AI identify the food, with estimated '
              'calories and macros for each item.',
        ),
        (
          Icons.fact_check_rounded,
          'You\'re always in control',
          'Review your meal, make any changes and save when you\'re happy.',
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Maybe later'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const PlusStar(size: 24),
          label: const Text('Become a Star'),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) await showPlusPaywall(context);
}
