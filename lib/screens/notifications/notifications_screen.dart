import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// The reminders, each a switch with its time: the evening meal reminder,
/// the weekly weigh-in and the daily creatine reminder. Turning one on asks
/// the system for permission; if that is refused it stays off.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _dayNames = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    Future<void> apply(Future<bool> Function() change) async {
      final ok = await change();
      if (ok || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allow notifications for YumSum in system settings.'),
        ),
      );
    }

    Future<TimeOfDay?> pickTime(TimeOfDay initial) => showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePage(
            maxWidth: 560,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily meal reminder'),
                  subtitle: const Text('Every evening at 20:30'),
                  value: settings.dailyMeal,
                  onChanged: (on) => apply(() => notifier.setDailyMeal(on)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weekly weigh-in reminder'),
                  subtitle: Text(
                    '${_dayNames[settings.weeklyDay]}s at '
                    '${clockLabel(settings.weeklyTime)}',
                  ),
                  value: settings.weeklyWeight,
                  onChanged: (on) => apply(() => notifier.setWeeklyWeight(on)),
                ),
                if (settings.weeklyWeight)
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: settings.weeklyDay,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (
                            var day = DateTime.monday;
                            day <= DateTime.sunday;
                            day++
                          )
                            DropdownMenuItem(
                              value: day,
                              child: Text(_dayNames[day]),
                            ),
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
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await pickTime(settings.weeklyTime);
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
                  title: const Text('Daily creatine reminder'),
                  subtitle: Text(
                    'Every day at ${clockLabel(settings.creatineTime)}',
                  ),
                  value: settings.creatine,
                  onChanged: (on) => apply(() => notifier.setCreatine(on)),
                ),
                if (settings.creatine)
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await pickTime(settings.creatineTime);
                      if (picked != null) {
                        await notifier.setCreatineTime(picked);
                      }
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(clockLabel(settings.creatineTime)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
