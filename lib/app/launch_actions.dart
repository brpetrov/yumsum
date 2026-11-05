import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/services/notification_service.dart';

/// Something the user asked for from outside the app: a notification tap, the
/// app-icon shortcut or the home-screen widget. Set by [bindLaunchActions] and
/// consumed once by the screen that can do it.
enum LaunchAction { logWeight, voiceLog, typeLog }

/// The app-icon shortcut's id; its type is `log_voice:` and the launch key.
const shortcutLogVoice = 'log_voice';

/// Where the launch key is kept, in the app's preferences and in
/// home_widget's, which the widget reads (LogWidgetProvider.kt).
const _launchKeyId = 'launch_key';

/// A random key for this install that the widget's links and the shortcut
/// carry. Other apps can open YumSum too, but without the key they can't
/// start the mic.
String launchKeyFor(SharedPreferences prefs) {
  final saved = prefs.getString(_launchKeyId);
  if (saved != null) return saved;
  final random = Random.secure();
  final key = [
    for (var i = 0; i < 16; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  prefs.setString(_launchKeyId, key);
  return key;
}

class LaunchActionNotifier extends Notifier<LaunchAction?> {
  @override
  LaunchAction? build() => null;

  void set(LaunchAction action) => state = action;

  void clear() => state = null;
}

final launchActionProvider =
    NotifierProvider<LaunchActionNotifier, LaunchAction?>(
      LaunchActionNotifier.new,
    );

/// `leanstreak://log/voice`, `leanstreak://log/text` and
/// `leanstreak://log/weight`, each with `?key=` and this install's [key];
/// anything else is ignored.
LaunchAction? launchActionForUri(Uri? uri, String key) {
  if (uri?.queryParameters['key'] != key) return null;
  return switch ((uri?.host, uri?.path)) {
    ('log', '/voice') => LaunchAction.voiceLog,
    ('log', '/text') => LaunchAction.typeLog,
    ('log', '/weight') => LaunchAction.logWeight,
    _ => null,
  };
}

LaunchAction? launchActionForPayload(String? payload) =>
    payload == NotificationService.payloadLogWeight
    ? LaunchAction.logWeight
    : null;

/// Hooks every entry point up to [launchActionProvider]. Runs first thing in
/// main(): the handlers only need [container], so a cold-start tap never
/// waits behind Firebase.
Future<void> bindLaunchActions(ProviderContainer container) async {
  if (!NotificationService.isSupported) return;
  final key = launchKeyFor(container.read(sharedPreferencesProvider));

  void dispatch(LaunchAction action) {
    container.read(launchActionProvider.notifier).set(action);
    // With another page on top (Review, Progress...), come back to Today so
    // the action is visible. On a cold start the router doesn't exist yet and
    // the redirects land on Today anyway.
    if (container.exists(goRouterProvider)) {
      container.read(goRouterProvider).go(AppRoutes.dashboard);
    }
  }

  // Long-press the app icon → "Log by voice". Registered before anything
  // else is awaited, so a cold start from the shortcut is not missed.
  final quickActions = QuickActions();
  final shortcutType = '$shortcutLogVoice:$key';
  await quickActions.initialize((type) {
    if (type == shortcutType) dispatch(LaunchAction.voiceLog);
  });
  await quickActions.setShortcutItems([
    ShortcutItem(type: shortcutType, localizedTitle: 'Log by voice'),
  ]);

  // The Android home-screen widget opens the app with leanstreak://log/voice.
  // Taps while the app is running arrive on the stream, which must stay
  // subscribed; a tap that started the app is only reported by
  // initiallyLaunchedFromHomeWidget.
  if (defaultTargetPlatform == TargetPlatform.android) {
    HomeWidget.widgetClicked.listen((uri) {
      final action = launchActionForUri(uri, key);
      if (action != null) dispatch(action);
    });
    final widgetLaunch = launchActionForUri(
      await HomeWidget.initiallyLaunchedFromHomeWidget(),
      key,
    );
    if (widgetLaunch != null) dispatch(widgetLaunch);
    // The widget puts the key in its links, so redraw it once the key is
    // new to it (the first open, or after the app's data was cleared).
    if (await HomeWidget.getWidgetData<String>(_launchKeyId) != key) {
      await HomeWidget.saveWidgetData<String>(_launchKeyId, key);
      await HomeWidget.updateWidget(androidName: 'LogWidgetProvider');
    }
  }

  // Taps while the app is running arrive in the callback; a tap that started
  // the app is only reported by launchPayload.
  await NotificationService.initialize(
    onTap: (payload) {
      final action = launchActionForPayload(payload);
      if (action != null) dispatch(action);
    },
  );
  final launch = launchActionForPayload(
    await NotificationService.launchPayload(),
  );
  if (launch != null) dispatch(launch);
}
