import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';

/// Explains a day off before taking today off, or confirms going back on
/// plan when it already is one; true when confirmed.
Future<bool> confirmDayOff(BuildContext context, {required bool isOff}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isOff ? 'Back on plan?' : 'Take today off?'),
      content: isOff
          ? const Text('Today will be measured against your target again.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('For holidays and nights out.'),
                const SizedBox(height: 6),
                for (final (icon, line) in [
                  (Icons.restaurant_outlined, 'Log your meals as usual.'),
                  (Icons.circle_outlined, 'No green, yellow or red today.'),
                  (
                    Icons.calendar_month_outlined,
                    'Left out of History scores.',
                  ),
                  (Icons.undo_rounded, 'Tap the umbrella to undo.'),
                ]) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(icon, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(line)),
                    ],
                  ),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(isOff ? 'Back on plan' : 'Take day off'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
