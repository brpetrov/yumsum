import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/reminder_provider.dart';

/// Offers the daily creatine reminder (off unless taken up here or on the
/// Notifications page); either way, says where it lives.
Future<void> offerCreatineReminder(BuildContext context, WidgetRef ref) async {
  final time = clockLabel(ref.read(reminderSettingsProvider).creatineTime);
  final l10n = context.l10n;
  final wanted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.homeCreatineTitle),
      content: Text(l10n.homeCreatineBody(time)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.homeCreatineNo),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.homeCreatineYes),
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
        (_, true) => l10n.homeCreatineOn(time),
        (true, false) => l10n.homeCreatineBlocked,
        _ => l10n.homeCreatineLater,
      }),
    ),
  );
}
