import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local reminders on Android and iOS. Scheduling is driven by
/// `reminderSyncProvider`; taps are reported through [initialize]'s callback
/// (app running) or [launchPayload] (app started by the tap).
class NotificationService {
  NotificationService._();

  static const payloadLogMeals = 'log_meals';
  static const payloadLogWeight = 'log_weight';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;
  static const int _weeklyWeightReminderId = 1002;
  static const int _creatineReminderId = 1003;
  static bool _initialized = false;

  static bool get isSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  /// Sets up the plugin and timezone. Does not ask for permission.
  static Future<void> initialize({
    required void Function(String payload) onTap,
  }) async {
    if (!isSupported || _initialized) return;

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) onTap(payload);
      },
    );
    _initialized = true;
  }

  /// Payload of the notification that started the app, if one did. A
  /// cold-start tap is only reported here, never through the callback.
  static Future<String?> launchPayload() async {
    if (!isSupported) return null;
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse?.payload;
  }

  /// Shows the system permission dialog. Call from a toggle or first run only.
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _android?.requestNotificationsPermission() ?? true;
      case TargetPlatform.iOS:
        return await _ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      default:
        return false;
    }
  }

  /// Current permission state, without prompting.
  static Future<bool> hasPermission() async {
    if (!isSupported) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _android?.areNotificationsEnabled() ?? false;
      case TargetPlatform.iOS:
        return (await _ios?.checkPermissions())?.isEnabled ?? false;
      default:
        return false;
    }
  }

  static Future<void> scheduleDailyMealReminder() async {
    if (!isSupported) return;
    await _notifications.cancel(id: _dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      30,
    );
    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: 'Log today\'s meals',
      body: 'Add what you ate before the day ends.',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_log_reminder',
          'Daily Log Reminder',
          channelDescription: 'Reminds you each evening to log your meals.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await _androidScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadLogMeals,
    );
  }

  static Future<void> cancelDailyMealReminder() async {
    if (!isSupported) return;
    await _notifications.cancel(id: _dailyReminderId);
  }

  /// Fires at [firstFireAt] and then weekly at the same weekday and time.
  static Future<void> scheduleWeeklyWeightReminder({
    required DateTime firstFireAt,
  }) async {
    if (!isSupported) return;
    await _notifications.cancel(id: _weeklyWeightReminderId);

    await _notifications.zonedSchedule(
      id: _weeklyWeightReminderId,
      title: 'Time to weigh in',
      body: 'Log this week\'s weight to keep your plan accurate.',
      scheduledDate: tz.TZDateTime.from(firstFireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_weight_reminder',
          'Weekly Weight Reminder',
          channelDescription: 'Reminds you once a week to log your weight.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await _androidScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payloadLogWeight,
    );
  }

  static Future<void> cancelWeeklyWeightReminder() async {
    if (!isSupported) return;
    await _notifications.cancel(id: _weeklyWeightReminderId);
  }

  /// Every day at [hour]:[minute].
  static Future<void> scheduleCreatineReminder({
    required int hour,
    required int minute,
  }) async {
    if (!isSupported) return;
    await _notifications.cancel(id: _creatineReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: _creatineReminderId,
      title: 'Creatine time',
      body: 'Take today\'s creatine.',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'creatine_reminder',
          'Creatine Reminder',
          channelDescription: 'Reminds you once a day to take creatine.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await _androidScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelCreatineReminder() async {
    if (!isSupported) return;
    await _notifications.cancel(id: _creatineReminderId);
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static IOSFlutterLocalNotificationsPlugin? get _ios => _notifications
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Exact alarms when already allowed; otherwise inexact, which is fine for
  /// reminders and avoids sending the user to system settings on every launch.
  static Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
