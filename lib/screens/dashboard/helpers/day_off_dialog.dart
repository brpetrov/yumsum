import 'package:flutter/material.dart';

/// Explains a day off before taking today off, or confirms going back on
/// plan when it already is one; true when confirmed.
Future<bool> confirmDayOff(BuildContext context, {required bool isOff}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isOff ? 'Back on plan?' : 'Take today off?'),
      content: Text(
        isOff
            ? 'Today will be measured against your target again.'
            : 'For holidays, birthdays and nights out. Log what you eat as '
                  'usual; today just isn\'t judged. It won\'t show as over '
                  'target in History or count against you in your reviews.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(isOff ? 'Back on plan' : 'Take the day off'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
