import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/l10n/l10n.dart';

/// Explains a day off before taking today off, or confirms going back on
/// plan when it already is one; true when confirmed.
Future<bool> confirmDayOff(BuildContext context, {required bool isOff}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isOff ? l10n.homeDayOffBackTitle : l10n.homeDayOffTakeTitle),
      content: isOff
          ? Text(l10n.homeDayOffBackBody)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeDayOffIntro),
                const SizedBox(height: 6),
                for (final (icon, line) in [
                  (Icons.restaurant_outlined, l10n.homeDayOffLog),
                  (Icons.circle_outlined, l10n.homeDayOffNoColours),
                  (Icons.calendar_month_outlined, l10n.homeDayOffHistory),
                  (Icons.undo_rounded, l10n.homeDayOffUndo),
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
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            isOff ? l10n.homeDayOffBackButton : l10n.homeDayOffTakeButton,
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
