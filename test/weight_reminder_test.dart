import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/helpers/weight_reminder.dart';

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
        launchActionForUri(Uri.parse('leanstreak://log/voice')),
        LaunchAction.voiceLog,
      );
      expect(
        launchActionForUri(Uri.parse('leanstreak://log/text')),
        LaunchAction.typeLog,
      );
      expect(
        launchActionForUri(Uri.parse('leanstreak://log/weight')),
        LaunchAction.logWeight,
      );
      expect(launchActionForUri(Uri.parse('leanstreak://other')), isNull);
      expect(launchActionForUri(null), isNull);
    });

    test('maps notification payloads', () {
      expect(launchActionForPayload('log_weight'), LaunchAction.logWeight);
      expect(launchActionForPayload('log_meals'), isNull);
      expect(launchActionForPayload(null), isNull);
    });
  });
}
