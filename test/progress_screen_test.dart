import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/progress/progress_screen.dart';
import 'package:lean_streak/services/weight_log_service.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:lean_streak/widgets/shine.dart';
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

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

WeightEntry _entry(String day, double kg) => WeightEntry(
  dateKey: day,
  weightKg: kg,
  loggedAt: DateTime.parse(day),
  source: WeightSource.manual,
);

void main() {
  late _FakeWeightLogController controller;

  Future<void> pumpScreen(
    WidgetTester tester, {
    UserProfile? profile,
    Entitlement? entitlement,
    List<WeightEntry>? entries,
    String region = 'DE',
  }) async {
    controller = _FakeWeightLogController();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceRegionProvider.overrideWithValue(region),
          weightEntriesProvider.overrideWith(
            (ref) => Stream.value(
              entries ??
                  [_entry('2026-10-01', 86.0), _entry('2026-10-08', 85.2)],
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(profile),
          ),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          adaptiveProgressProvider.overrideWith((ref) async => null),
          adaptiveTodayLineProvider.overrideWithValue(null),
          weightLogControllerProvider.overrideWith(() => controller),
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

  testWidgets('the dots and the target sit clear of the chart\'s edges', (
    tester,
  ) async {
    // On a phone, the highest and lowest weigh-ins at the ends, the target
    // (73 kg) below them all.
    tester.view.physicalSize = const Size(411 * 3, 915 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      profile: planProfile(),
      entries: [
        _entry('2026-10-20', 80.6),
        _entry('2026-11-04', 79.3),
        _entry('2026-11-07', 79.5),
      ],
    );
    final chart = find.byType(LineChart);
    final data = tester.widget<LineChart>(chart).data;
    final size = tester.getSize(chart);
    final titles = data.titlesData;
    final width = size.width - titles.leftTitles.sideTitles.reservedSize;
    final height = size.height - titles.bottomTitles.sideTitles.reservedSize;
    double xGap(double days) => days / (data.maxX - data.minX) * width;
    double yGap(double kg) => kg / (data.maxY - data.minY) * height;
    // A dot reaches 7 from its centre with its rim, a touched one 10, so
    // more than that is kept clear.
    expect(yGap(data.maxY - 80.6), greaterThan(10));
    expect(yGap(73 - data.minY), greaterThan(10));
    expect(xGap(0 - data.minX), greaterThan(10));
    expect(xGap(data.maxX - 18), greaterThan(10));
    // The tooltip stays inside too, not cut off by the card's corner.
    expect(data.lineTouchData.touchTooltipData.fitInsideHorizontally, isTrue);
    expect(data.lineTouchData.touchTooltipData.fitInsideVertically, isTrue);
  });

  testWidgets('without YumSum Star it is a shining button that offers it', (
    tester,
  ) async {
    await pumpScreen(tester, profile: planProfile());
    // In the chart's card, under the chart: the button is the name itself,
    // shining; the star waits in the dialog.
    // The nearest one; the card has its own.
    final button = find
        .ancestor(
          of: find.text('Adaptive formula'),
          matching: find.byType(InkWell),
        )
        .first;
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
    expect(
      find.ancestor(of: button, matching: find.byType(Shine)),
      findsOneWidget,
    );
    expect(find.byType(PlusStar), findsNothing);
    expect(
      find.text(
        'A customised formula tailored just for you. Adapting with time and '
        'your weigh-ins.',
      ),
      findsOneWidget,
    );
    // No numbers that knock the plan, and no info button.
    expect(find.textContaining('kcal'), findsNothing);
    expect(find.byTooltip('How it works'), findsNothing);
    expect(find.byType(Switch), findsNothing);

    await tester.ensureVisible(find.text('Adaptive formula'));
    await tester.tap(find.text('Adaptive formula'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Feel more confident about how much to eat'),
      findsOneWidget,
    );
    expect(find.text('Become a Star'), findsOneWidget);
    expect(find.text('Maybe later'), findsOneWidget);
    expect(find.text('Log my weight'), findsNothing);
  });

  testWidgets('with YumSum Star it is on: what you burn and your target', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      profile: planProfile(adaptiveKcal: -80),
      entitlement: _plus,
    );
    expect(find.text('On'), findsOneWidget);
    // Nothing measured right now, so the burn the target assumes: 2495 − 80,
    // learnt before.
    expect(find.text('You burn 2410 kcal a day'), findsOneWidget);
    expect(find.text('Learnt from your weigh-ins and meals.'), findsOneWidget);
    expect(find.text('Your target is 1590 kcal a day'), findsOneWidget);
    expect(find.text('To lose 0.75 kg a week.'), findsOneWidget);
    expect(find.byType(PlusStar), findsNothing);
    expect(find.byType(Switch), findsNothing);

    await tester.ensureVisible(find.byTooltip('How it works'));
    await tester.tap(find.byTooltip('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('Log my weight'), findsOneWidget);
    expect(find.text('Become a Star'), findsNothing);
  });

  testWidgets('a new member\'s burn is a first estimate', (tester) async {
    await pumpScreen(tester, profile: planProfile(), entitlement: _plus);
    expect(find.text('You burn 2490 kcal a day'), findsOneWidget);
    expect(
      find.text('A first estimate. It learns as you weigh in.'),
      findsOneWidget,
    );
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

  testWidgets('a long history builds only the weigh-ins on screen', (
    tester,
  ) async {
    final start = DateTime.utc(2026, 8, 1);
    await pumpScreen(
      tester,
      entries: [
        for (var i = 0; i < 90; i++)
          _entry(
            start.add(Duration(days: i)).toIso8601String().substring(0, 10),
            90 - i * 0.05,
          ),
      ],
    );
    // Newest first, so the oldest is far below and not built yet.
    expect(find.text('Thu, 29 Oct 2026'), findsOneWidget);
    final oldest = find.text('Sat, 1 Aug 2026', skipOffstage: false);
    expect(oldest, findsNothing);

    await tester.scrollUntilVisible(find.text('Sat, 1 Aug 2026'), 500);
    expect(oldest, findsOneWidget);
    expect(find.text('Thu, 29 Oct 2026', skipOffstage: false), findsNothing);
  });

  testWidgets('Reset progress asks first, then clears the weight history', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.ensureVisible(
      find.text('Reset progress', skipOffstage: false),
    );
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

  testWidgets('in pounds: the numbers, the chart and the delete question', (
    tester,
  ) async {
    await pumpScreen(tester, region: 'US');
    expect(find.text('187.8 lb'), findsWidgets);
    expect(find.text('-1.8 lb'), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final weighIns = chart.data.lineBarsData[1];
    expect(weighIns.spots.last.y, closeTo(kgToLb(85.2), 1e-9));

    final delete = find.byTooltip('Delete weigh-in').first;
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Remove 187.8 lb from Thu, 8 Oct? Your plan adjusts back to 189.6 lb.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('in stones: stones and pounds, and the axis in stones', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      profile: planProfile().copyWith(weightUnit: WeightUnit.st),
    );
    // 85.2 kg is 187.8 lb; the target, 73 kg, 160.9 lb.
    expect(find.text('13 st 6 lb'), findsWidgets);
    expect(find.text('11 st 7 lb'), findsOneWidget);
    expect(find.text('-1.8 lb'), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final axis = chart.data.titlesData.leftTitles.sideTitles;
    // About 157 to 194 lb: a line a stone.
    expect(axis.interval, 14);
    expect(find.text('12 st'), findsOneWidget);
    expect(find.text('13 st'), findsOneWidget);
  });
}
