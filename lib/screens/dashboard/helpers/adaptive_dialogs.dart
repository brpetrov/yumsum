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
  final muted = TextStyle(
    fontSize: 13.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  final choice = await showDialog<_IntroChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How the Adaptive formula works'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your plan starts from a formula, a good guess at what you '
              'burn. Everyone is a little different, so the Adaptive formula '
              'learns your real number and adjusts your target to it.',
            ),
            for (final (icon, line) in [
              (
                Icons.insights_rounded,
                'It compares what you log with how your weight trend moves. '
                    'Eating 1,800 kcal a day and losing 0.4 kg a week means '
                    'you burn about 2,240.',
              ),
              (
                Icons.calendar_month_outlined,
                'Each Monday it moves your target a small step towards that: '
                    'at most 5% a week and 15% in all. It only lowers it once '
                    'two Mondays in a row agree.',
              ),
              (
                Icons.shield_outlined,
                'It never goes below your safe minimum, and never plans a '
                    'faster loss than the pace you chose.',
              ),
              (
                Icons.monitor_weight_outlined,
                'Its first change comes after about 3 weeks of weigh-ins, '
                    'with at least 4 days a week logged. Weigh in at least 3 '
                    'times a week, first thing in the morning. More often '
                    'helps it learn faster.',
              ),
              (
                Icons.water_drop_outlined,
                'Water weight from salt, a big meal or your period is '
                    'smoothed out by the trend, and a weigh-in that looks '
                    'like a typo is set aside.',
              ),
            ]) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(line, style: muted)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            const Text('The longer you use it, the better it knows you.'),
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
