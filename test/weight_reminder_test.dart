import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/helpers/weight_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('nextDailyAt', () {
    test('today until the time has passed, then tomorrow', () {
      expect(
        nextDailyAt(hour: 7, minute: 30, now: DateTime(2026, 10, 31, 7, 29)),
        DateTime(2026, 10, 31, 7, 30),
      );
      expect(
        nextDailyAt(hour: 7, minute: 30, now: DateTime(2026, 10, 31, 7, 30)),
        DateTime(2026, 11, 1, 7, 30),
      );
    });
  });

  group('nextWeekdayAt', () {
    // 14 October 2026 is a Wednesday.
    test('finds the coming Saturday at the given time', () {
      expect(
        nextWeekdayAt(
          weekday: DateTime.saturday,
          hour: 20,
          minute: 0,
          now: DateTime(2026, 10, 14, 10),
        ),
        DateTime(2026, 10, 17, 20),
      );
    });

    test('on the day itself, counts until the time has passed', () {
      expect(
        nextWeekdayAt(
          weekday: DateTime.saturday,
          hour: 20,
          minute: 0,
          now: DateTime(2026, 10, 17, 19, 59),
        ),
        DateTime(2026, 10, 17, 20),
      );
      expect(
        nextWeekdayAt(
          weekday: DateTime.saturday,
          hour: 20,
          minute: 0,
          now: DateTime(2026, 10, 17, 20),
        ),
        DateTime(2026, 10, 24, 20),
      );
    });

    test('wraps past the weekend and a month end', () {
      expect(
        nextWeekdayAt(
          weekday: DateTime.monday,
          hour: 7,
          minute: 30,
          now: DateTime(2026, 10, 31, 12), // Saturday
        ),
        DateTime(2026, 11, 2, 7, 30),
      );
    });
  });

  group('launch actions', () {
    test('maps widget and shortcut URIs', () {
      expect(
        launchActionForUri(Uri.parse('leanstreak://log/voice?key=k1'), 'k1'),
        LaunchAction.voiceLog,
      );
      expect(
        launchActionForUri(Uri.parse('leanstreak://log/text?key=k1'), 'k1'),
        LaunchAction.typeLog,
      );
      expect(
        launchActionForUri(Uri.parse('leanstreak://log/weight?key=k1'), 'k1'),
        LaunchAction.logWeight,
      );
      expect(
        launchActionForUri(Uri.parse('leanstreak://other?key=k1'), 'k1'),
        isNull,
      );
      expect(launchActionForUri(null, 'k1'), isNull);
    });

    test("ignores links without this install's key", () {
      for (final link in [
        'leanstreak://log/voice',
        'leanstreak://log/voice?key=',
        'leanstreak://log/voice?key=k2',
      ]) {
        expect(launchActionForUri(Uri.parse(link), 'k1'), isNull);
      }
    });

    test('the launch key is random, then kept', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final key = launchKeyFor(prefs);
      expect(key, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(launchKeyFor(prefs), key);
    });

    test('maps notification payloads', () {
      expect(launchActionForPayload('log_weight'), LaunchAction.logWeight);
      expect(launchActionForPayload('log_meals'), isNull);
      expect(launchActionForPayload(null), isNull);
    });
  });
}
