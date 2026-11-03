import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/services/notification_service.dart';

/// Prefs keys: the How it works dialog shown once after subscribing, and
/// the end date whose lapse notice was shown.
const adaptiveIntroShownKey = 'adaptive.intro_shown';
const adaptiveLapseNoticeKey = 'adaptive.lapse_notice';

/// How the Adaptive formula works: once after subscribing, and from Plan
/// Settings and Weight & Progress. With YumSum Star it offers a weigh-in
/// reminder every morning on phones, unless there already is one; without
/// it, the YumSum Star page.
Future<void> showAdaptiveIntro(BuildContext context, WidgetRef ref) async {
  final plus = ref.read(plusProvider);
  final settings = ref.read(reminderSettingsProvider);
  final offerMorning =
      plus &&
      NotificationService.isSupported &&
      !(settings.weeklyWeight &&
          settings.weeklyDay == ReminderSettings.everyDay);
  final choice = await showDialog<_IntroChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How the Adaptive formula works'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Four short lines, to take in at a glance.
            for (final (i, (icon, line)) in [
              (
                Icons.insights_rounded,
                'Learns what you really burn from your weigh-ins and meals.',
              ),
              (
                Icons.calendar_month_outlined,
                'Adjusts your target each Monday, from your first week.',
              ),
              (
                Icons.trending_down_rounded,
                'Helps you keep losing when a fixed target would stall.',
              ),
              (
                Icons.monitor_weight_outlined,
                'Weigh in at least twice a week. Daily is best.',
              ),
            ].indexed) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(line)),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(plus ? 'Got it' : 'Close'),
        ),
        if (!plus)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_IntroChoice.star),
            child: const Text('See YumSum Star'),
          ),
        if (offerMorning)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_IntroChoice.morning),
            child: const Text('Remind me each morning'),
          ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (choice == _IntroChoice.star) {
    await showPlusPaywall(context);
    return;
  }
  final morning = choice == _IntroChoice.morning;
  if (morning != true || !context.mounted) return;
  final reminders = ref.read(reminderSettingsProvider.notifier);
  final on = await reminders.setWeeklyWeight(true);
  if (on) {
    await reminders.setWeeklySchedule(
      day: ReminderSettings.everyDay,
      time: const TimeOfDay(hour: 7, minute: 30),
    );
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        on
            ? 'Weigh-in reminder on for 07:30 every day. Change it under '
                  'Notifications in the menu.'
            : 'Allow notifications in your phone\'s Settings, then turn it on '
                  'under Notifications in the menu.',
      ),
    ),
  );
}

/// Once YumSum Star has ended with an adjustment in place: when the target
/// goes back to the standard plan.
Future<void> showAdaptiveLapse(BuildContext context, DateTime back) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Your YumSum Star has ended'),
      content: Text(
        'Your target goes back to your standard plan on '
        '${DateFormat('d MMMM').format(back)}.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

enum _IntroChoice { morning, star }
