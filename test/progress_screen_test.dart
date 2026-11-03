import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/progress/progress_screen.dart';
import 'package:lean_streak/services/weight_log_service.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_fixtures.dart';

class _FakeWeightLogController extends WeightLogController {
  int resets = 0;
  final List<String> deleted = [];

  @override
  Future<bool> resetHistory() async {
    resets++;
    return true;
  }

  @override
  Future<WeightLogResult?> deleteEntry(WeightEntry entry) async {
    deleted.add(entry.dateKey);
    return null;
  }
}

class _FakeProfileController extends ProfileController {
  final List<bool> switched = [];

  @override
  Future<bool> setAdaptiveOn(UserProfile profile, bool on) async {
    switched.add(on);
    return true;
  }
}

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

WeightEntry _entry(String day, double kg) => WeightEntry(
  dateKey: day,
  weightKg: kg,
  loggedAt: DateTime.parse(day),
  source: WeightSource.manual,
);

void main() {
  late _FakeWeightLogController controller;
  late _FakeProfileController profileController;

  Future<void> pumpScreen(
    WidgetTester tester, {
    UserProfile? profile,
    Entitlement? entitlement,
  }) async {
    controller = _FakeWeightLogController();
    profileController = _FakeProfileController();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          weightEntriesProvider.overrideWith(
            (ref) => Stream.value([
              _entry('2026-10-01', 86.0),
              _entry('2026-10-08', 85.2),
            ]),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(profile),
          ),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          adaptiveProgressProvider.overrideWith((ref) async => null),
          adaptiveTodayLineProvider.overrideWithValue(null),
          weightLogControllerProvider.overrideWith(() => controller),
          profileControllerProvider.overrideWith(() => profileController),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProgressScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the chart shows the weigh-ins as dots under the trend line', (
    tester,
  ) async {
    await pumpScreen(tester);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final [trend, weighIns] = chart.data.lineBarsData;
    // A week later the trend has moved 1 - 0.9^7 of the way to 85.2.
    expect(trend.spots.last.y, closeTo(86.0 - 0.8 * 0.5217031, 1e-6));
    expect(trend.dotData.show, isFalse);
    expect([for (final s in weighIns.spots) s.y], [86.0, 85.2]);
    expect(weighIns.barWidth, 0);
  });

  testWidgets('without YumSum Star the Adaptive formula is there, off', (
    tester,
  ) async {
    await pumpScreen(tester, profile: planProfile());
    // In the chart's card, under the chart.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.byType(LineChart),
          matching: find.byType(AppCard),
        ),
        matching: find.text('Adaptive formula'),
      ),
      findsOneWidget,
    );
    expect(find.byType(PlusStar), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.ensureVisible(find.byTooltip('How it works'));
    await tester.tap(find.byTooltip('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('How the Adaptive formula works'), findsOneWidget);
    expect(find.text('See YumSum Star'), findsOneWidget);
    expect(find.text('Remind me each morning'), findsNothing);
  });

  testWidgets('with YumSum Star it shows the sum it makes', (tester) async {
    await pumpScreen(
      tester,
      profile: planProfile(adaptiveKcal: -80),
      entitlement: _plus,
    );
    expect(
      find.text('1670 from your plan − 80 adaptive = 1590 kcal'),
      findsOneWidget,
    );
    expect(find.byType(PlusStar), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('switching it off asks first, as it clears the adjustment', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      profile: planProfile(adaptiveKcal: -80),
      entitlement: _plus,
    );
    await tester.ensureVisible(find.byType(Switch));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your target goes back to your standard plan, 1670 kcal. If you '
        'switch it on again, it starts over from there.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(profileController.switched, isEmpty);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch off'));
    await tester.pumpAndSettle();
    expect(profileController.switched, [false]);
  });

  testWidgets('switching it on saves at once', (tester) async {
    await pumpScreen(
      tester,
      profile: planProfile().copyWith(adaptiveOn: false),
      entitlement: _plus,
    );
    expect(
      find.text(
        'Learns from your weigh-ins and adjusts your target each Monday.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(profileController.switched, [true]);
  });

  testWidgets('a weigh-in can be deleted, after asking', (tester) async {
    await pumpScreen(tester);
    // Newest first, so the first button is the newest weigh-in's.
    final delete = find.byTooltip('Delete weigh-in').first;
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();

    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Remove 85.2 kg from Thu, 8 Oct? Your plan adjusts back to 86.0 kg.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.deleted, isEmpty);

    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(controller.deleted, ['2026-10-08']);
    expect(find.text('Weigh-in deleted.'), findsOneWidget);
  });

  testWidgets('Reset progress asks first, then clears the weight history', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.ensureVisible(find.text('Reset progress'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.resets, 0);

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(controller.resets, 1);
    expect(find.text('Weight history cleared.'), findsOneWidget);
  });
}
