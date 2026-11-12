import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/widgets/time_wheels.dart';

/// The reminders, Settings' Notifications section: each a switch with its
/// time, the evening meal reminder, the weigh-in (weekly, or every day) and
/// the daily creatine reminder. Turning one on asks the system for
/// permission; if that is refused it stays off.
class NotificationSettings extends ConsumerWidget {
  const NotificationSettings({super.key});

  /// For [notificationsWeeklyAt], by weekday number.
  static const _weekdays = [
    '',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // By weekday number; 0 is [ReminderSettings.everyDay]. 1 January 2024
    // was a Monday.
    final dayNames = [
      l10n.notificationsEveryDay,
      for (var day = 1; day <= 7; day++)
        capitalised(l10n.date(DateTime(2024, 1, day), 'EEEE')),
    ];
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    Future<void> apply(Future<bool> Function() change) async {
      final ok = await change();
      if (ok || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.notificationsDenied)));
    }

    Future<TimeOfDay?> pickTime(TimeOfDay initial, String title) =>
        showTimeWheels(context, initial: initial, title: title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationsMeal),
          subtitle: Text(l10n.notificationsMealTime('20:30')),
          value: settings.dailyMeal,
          onChanged: (on) => apply(() => notifier.setDailyMeal(on)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationsWeight),
          subtitle: Text(
            settings.weeklyDay == ReminderSettings.everyDay
                ? l10n.notificationsEveryDayAt(clockLabel(settings.weeklyTime))
                : l10n.notificationsWeeklyAt(
                    _weekdays[settings.weeklyDay],
                    clockLabel(settings.weeklyTime),
                  ),
          ),
          value: settings.weeklyWeight,
          onChanged: (on) => apply(() => notifier.setWeeklyWeight(on)),
        ),
        if (settings.weeklyWeight)
          // The time goes under the day where a long day name
          // leaves no room.
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<int>(
                value: settings.weeklyDay,
                underline: const SizedBox.shrink(),
                items: [
                  for (
                    var day = ReminderSettings.everyDay;
                    day <= DateTime.sunday;
                    day++
                  )
                    DropdownMenuItem(value: day, child: Text(dayNames[day])),
                ],
                onChanged: (day) {
                  if (day != null) {
                    notifier.setWeeklySchedule(
                      day: day,
                      time: settings.weeklyTime,
                    );
                  }
                },
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await pickTime(
                    settings.weeklyTime,
                    l10n.notificationsWeight,
                  );
                  if (picked != null) {
                    await notifier.setWeeklySchedule(
                      day: settings.weeklyDay,
                      time: picked,
                    );
                  }
                },
                icon: const Icon(Icons.schedule_rounded),
                label: Text(clockLabel(settings.weeklyTime)),
              ),
            ],
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationsCreatine),
          subtitle: Text(
            l10n.notificationsEveryDayAt(clockLabel(settings.creatineTime)),
          ),
          value: settings.creatine,
          onChanged: (on) => apply(() => notifier.setCreatine(on)),
        ),
        if (settings.creatine)
          TextButton.icon(
            onPressed: () async {
              final picked = await pickTime(
                settings.creatineTime,
                l10n.notificationsCreatine,
              );
              if (picked != null) {
                await notifier.setCreatineTime(picked);
              }
            },
            icon: const Icon(Icons.schedule_rounded),
            label: Text(clockLabel(settings.creatineTime)),
          ),
      ],
    );
  }
}
