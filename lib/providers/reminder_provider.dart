import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/config/crash_reports.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/helpers/weight_reminder.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/services/notification_service.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.dailyMeal,
    required this.weeklyWeight,
    required this.weeklyDay,
    required this.weeklyTime,
    required this.creatine,
    required this.creatineTime,
  });

  final bool dailyMeal;
  final bool weeklyWeight;

  /// [DateTime.monday] to [DateTime.sunday], or [everyDay].
  final int weeklyDay;
  final TimeOfDay weeklyTime;
  final bool creatine;
  final TimeOfDay creatineTime;

  /// The weigh-in reminder's day when it comes every morning, as the
  /// Adaptive formula likes.
  static const everyDay = 0;

  ReminderSettings copyWith({
    bool? dailyMeal,
    bool? weeklyWeight,
    int? weeklyDay,
    TimeOfDay? weeklyTime,
    bool? creatine,
    TimeOfDay? creatineTime,
  }) {
    return ReminderSettings(
      dailyMeal: dailyMeal ?? this.dailyMeal,
      weeklyWeight: weeklyWeight ?? this.weeklyWeight,
      weeklyDay: weeklyDay ?? this.weeklyDay,
      weeklyTime: weeklyTime ?? this.weeklyTime,
      creatine: creatine ?? this.creatine,
      creatineTime: creatineTime ?? this.creatineTime,
    );
  }
}

/// The reminder switches, the weigh-in slot (Saturday 20:00 unless changed)
/// and the creatine time (09:00; that reminder is off unless turned on),
/// stored on the device since reminders are per device.
class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _dailyKey = 'reminders.daily_meal';
  static const _weeklyKey = 'reminders.weekly_weight';
  static const _weeklyDayKey = 'reminders.weekly_weight_day';
  static const _weeklyHourKey = 'reminders.weekly_weight_hour';
  static const _weeklyMinuteKey = 'reminders.weekly_weight_minute';
  static const _creatineKey = 'reminders.creatine';
  static const _creatineHourKey = 'reminders.creatine_hour';
  static const _creatineMinuteKey = 'reminders.creatine_minute';
  static const _creatineOfferedKey = 'reminders.creatine_offered';

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReminderSettings(
      dailyMeal: prefs.getBool(_dailyKey) ?? true,
      weeklyWeight: prefs.getBool(_weeklyKey) ?? true,
      weeklyDay: prefs.getInt(_weeklyDayKey) ?? DateTime.saturday,
      weeklyTime: TimeOfDay(
        hour: prefs.getInt(_weeklyHourKey) ?? 20,
        minute: prefs.getInt(_weeklyMinuteKey) ?? 0,
      ),
      creatine: prefs.getBool(_creatineKey) ?? false,
      creatineTime: TimeOfDay(
        hour: prefs.getInt(_creatineHourKey) ?? 9,
        minute: prefs.getInt(_creatineMinuteKey) ?? 0,
      ),
    );
  }

  /// Nothing stored yet: startup may show the permission prompt this once.
  bool get isFirstRun =>
      !ref.read(sharedPreferencesProvider).containsKey(_dailyKey);

  Future<void> markFirstRunDone() => _persist(state);

  /// Returns false, leaving the switch off, when the system denies permission.
  Future<bool> setDailyMeal(bool on) =>
      _set(on, (settings) => settings.copyWith(dailyMeal: on));

  Future<bool> setWeeklyWeight(bool on) =>
      _set(on, (settings) => settings.copyWith(weeklyWeight: on));

  /// Turning it on also keeps the Adaptive formula from learning for the
  /// next 28 days, while creatine's extra water settles.
  Future<bool> setCreatine(bool on) async {
    final done = await _set(on, (settings) => settings.copyWith(creatine: on));
    if (done && on) unawaited(_pauseAdaptiveForCreatine());
    return done;
  }

  Future<void> _pauseAdaptiveForCreatine() async {
    // Best effort: the reminder is on either way, and without the pause
    // the formula only reads the water as slower loss for a few weeks.
    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) return;
      final profiles = ref.read(userProfileRepositoryProvider);
      final profile = await profiles.fetchProfile(uid);
      if (profile == null) return;
      final now = DateTime.now();
      final from = AdaptiveFormula.dateKey(
        DateTime(now.year, now.month, now.day + AdaptiveFormula.creatineDays),
      );
      final current = profile.adaptiveFrom;
      if (current != null && current.compareTo(from) >= 0) return;
      await profiles.createProfile(profile.copyWith(adaptiveFrom: from));
    } catch (error, stack) {
      reportError(error, stack, 'Pause the Adaptive formula for creatine');
    }
  }

  Future<void> setCreatineTime(TimeOfDay time) async {
    state = state.copyWith(creatineTime: time);
    await _persist(state);
  }

  /// The creatine reminder is offered once, in the first week after sign-up
  /// (from the day after, so it doesn't crowd the first session).
  bool shouldOfferCreatine({
    required DateTime signedUp,
    required DateTime now,
  }) {
    final offered = ref
        .read(sharedPreferencesProvider)
        .getBool(_creatineOfferedKey);
    if (state.creatine || offered == true) return false;
    final days = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(signedUp.year, signedUp.month, signedUp.day))
        .inDays;
    return days >= 1 && days < 7;
  }

  Future<void> markCreatineOffered() =>
      ref.read(sharedPreferencesProvider).setBool(_creatineOfferedKey, true);

  Future<void> setWeeklySchedule({
    required int day,
    required TimeOfDay time,
  }) async {
    state = state.copyWith(weeklyDay: day, weeklyTime: time);
    await _persist(state);
  }

  Future<bool> _set(
    bool on,
    ReminderSettings Function(ReminderSettings) update,
  ) async {
    if (on && !await NotificationService.requestPermission()) return false;
    state = update(state);
    await _persist(state);
    return true;
  }

  Future<void> _persist(ReminderSettings settings) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_dailyKey, settings.dailyMeal);
    await prefs.setBool(_weeklyKey, settings.weeklyWeight);
    await prefs.setInt(_weeklyDayKey, settings.weeklyDay);
    await prefs.setInt(_weeklyHourKey, settings.weeklyTime.hour);
    await prefs.setInt(_weeklyMinuteKey, settings.weeklyTime.minute);
    await prefs.setBool(_creatineKey, settings.creatine);
    await prefs.setInt(_creatineHourKey, settings.creatineTime.hour);
    await prefs.setInt(_creatineMinuteKey, settings.creatineTime.minute);
  }
}

/// A reminder time as the settings show it, e.g. "09:00".
String clockLabel(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

/// Keeps the scheduled notifications in step with the settings. Re-runs
/// whenever a switch flips, a time changes or the language changes (the
/// texts are fixed when scheduled).
final reminderSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final settings = ref.watch(reminderSettingsProvider);
  final l10n = ref.watch(l10nProvider);

  final notifier = ref.read(reminderSettingsProvider.notifier);
  if (notifier.isFirstRun) {
    await NotificationService.requestPermission();
    await notifier.markFirstRunDone();
  }
  if (!await NotificationService.hasPermission()) return;

  if (settings.dailyMeal) {
    await NotificationService.scheduleDailyMealReminder(l10n);
  } else {
    await NotificationService.cancelDailyMealReminder();
  }

  if (settings.creatine) {
    await NotificationService.scheduleCreatineReminder(
      l10n,
      hour: settings.creatineTime.hour,
      minute: settings.creatineTime.minute,
    );
  } else {
    await NotificationService.cancelCreatineReminder();
  }

  if (!settings.weeklyWeight) {
    await NotificationService.cancelWeeklyWeightReminder();
    return;
  }
  final daily = settings.weeklyDay == ReminderSettings.everyDay;
  final time = settings.weeklyTime;
  await NotificationService.scheduleWeeklyWeightReminder(
    l10n,
    daily: daily,
    firstFireAt: daily
        ? nextDailyAt(hour: time.hour, minute: time.minute, now: DateTime.now())
        : nextWeekdayAt(
            weekday: settings.weeklyDay,
            hour: time.hour,
            minute: time.minute,
            now: DateTime.now(),
          ),
  );
});
