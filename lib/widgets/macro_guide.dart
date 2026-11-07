import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';

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
  final l10n = context.l10n;
  final calories = (
    l10n.macroGuideCalories,
    l10n.macroGuideCaloriesWhy,
    l10n.macroGuideCaloriesTarget,
  );
  // Each group with its heading, its colour, a note under the heading (why,
  // once for all of Keep under) and its macros.
  final groups = [
    (
      l10n.macroGuideAimFor,
      AppColors.veryGood,
      null,
      [
        if (withProtein)
          (
            l10n.macroProtein,
            l10n.macroGuideProteinWhy,
            l10n.macroGuideProteinTarget,
          ),
        (l10n.macroFibre, l10n.macroGuideFibreWhy, l10n.macroGuideFibreTarget),
      ],
    ),
    (
      l10n.macroGuideBalance,
      AppColors.primary,
      null,
      [
        (l10n.macroCarbs, l10n.macroGuideCarbsWhy, l10n.macroGuideCarbsTarget),
        (l10n.macroFat, l10n.macroGuideFatWhy, l10n.macroGuideFatTarget),
      ],
    ),
    (
      l10n.macroGuideKeepUnder,
      AppColors.bad,
      l10n.macroGuideKeepUnderNote,
      [
        (
          l10n.macroSugars,
          l10n.macroGuideSugarsWhy,
          l10n.macroGuideSugarsTarget,
        ),
        (
          l10n.macroSaturates,
          l10n.macroGuideSaturatesWhy,
          l10n.macroGuideSaturatesTarget,
        ),
        (l10n.macroSalt, l10n.macroGuideSaltWhy, l10n.macroGuideSaltTarget),
      ],
    ),
  ];
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
              text: l10n.macroGuideTarget,
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
      title: Text(
        withCalories ? l10n.macroGuideTargets : l10n.macroGuideMacros,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.macroGuideIntro, style: body),
            if (withCalories) ...item(calories),
            for (final (group, color, note, items) in groups) ...[
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
              if (note != null) ...[
                const SizedBox(height: 6),
                Text(note, style: body),
              ],
              for (final entry in items) ...item(entry),
            ],
            const SizedBox(height: 18),
            Text(
              l10n.macroGuideDisclaimer,
              style: body.copyWith(fontSize: 12.5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonOk),
        ),
      ],
    ),
  );
}
