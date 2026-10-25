import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/providers/reminder_provider.dart';

/// Offers the daily creatine reminder (off unless taken up here or on the
/// Notifications page); either way, says where it lives.
Future<void> offerCreatineReminder(BuildContext context, WidgetRef ref) async {
  final time = clockLabel(ref.read(reminderSettingsProvider).creatineTime);
  final wanted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Take creatine?'),
      content: Text(
        'Get a daily reminder at $time. You can change the time later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No thanks'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remind me'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  final on =
      wanted == true &&
      await ref.read(reminderSettingsProvider.notifier).setCreatine(true);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(switch ((wanted == true, on)) {
        (_, true) =>
          'Creatine reminder on for $time. Change it under Notifications in '
              'the menu.',
        (true, false) =>
          'Allow notifications in your phone\'s Settings, then turn it on '
              'under Notifications in the menu.',
        _ => 'You can turn it on any time under Notifications in the menu.',
      }),
    ),
  );
}
