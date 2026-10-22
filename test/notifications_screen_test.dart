import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/screens/notifications/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> pumpScreen(
    WidgetTester tester, [
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the weigh-in reminder defaults to Saturday 20:00; day changes', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('Saturdays at 20:00'), findsOneWidget);

    await tester.tap(find.text('Saturday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunday').last);
    await tester.pumpAndSettle();

    expect(find.text('Sundays at 20:00'), findsOneWidget);
    expect(prefs.getInt('reminders.weekly_weight_day'), DateTime.sunday);
    expect(prefs.getInt('reminders.weekly_weight_hour'), 20);
  });

  testWidgets('the creatine reminder is off by default', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Every day at 09:00'), findsOneWidget);
    final creatine = find.widgetWithText(
      SwitchListTile,
      'Daily creatine reminder',
    );
    expect(tester.widget<SwitchListTile>(creatine).value, isFalse);
    expect(find.widgetWithText(TextButton, '09:00'), findsNothing);
  });

  testWidgets('once on, the creatine reminder shows its time', (tester) async {
    await pumpScreen(tester, {
      'reminders.creatine': true,
      'reminders.creatine_hour': 7,
      'reminders.creatine_minute': 30,
    });
    expect(find.text('Every day at 07:30'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '07:30'), findsOneWidget);
  });

  group('the creatine offer', () {
    Future<ReminderSettingsNotifier> notifier() async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container.read(reminderSettingsProvider.notifier);
    }

    final signedUp = DateTime(2026, 10, 20, 18);

    test('waits a day, then is offered during the first week', () async {
      final reminders = await notifier();
      bool offerOn(DateTime now) =>
          reminders.shouldOfferCreatine(signedUp: signedUp, now: now);

      expect(offerOn(DateTime(2026, 10, 20, 22)), isFalse);
      expect(offerOn(DateTime(2026, 10, 21, 8)), isTrue);
      expect(offerOn(DateTime(2026, 10, 26, 23)), isTrue);
      expect(offerOn(DateTime(2026, 10, 27, 8)), isFalse);
    });

    test('is offered once', () async {
      final reminders = await notifier();
      final now = DateTime(2026, 10, 22);
      await reminders.markCreatineOffered();
      expect(
        reminders.shouldOfferCreatine(signedUp: signedUp, now: now),
        isFalse,
      );
    });
  });
}
