import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/day_off_repository.dart';
import 'package:lean_streak/repositories/meal_repository.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';
import 'package:lean_streak/screens/dashboard/dashboard_screen.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/services/daily_summary_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_fixtures.dart';

class _FakeMeals extends Fake implements MealRepository {}

class _FakeProfiles extends Fake implements UserProfileRepository {}

class _FakeSummaries extends Fake implements DailySummaryRepository {}

class _FakeDaysOff extends Fake implements DayOffRepository {}

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

/// The app's fonts, so a line's length on a 360dp phone is the real one.
Future<void> _loadFonts() async {
  for (final (family, file) in [
    ('Nunito', 'Nunito-Regular'),
    ('Fredoka', 'Fredoka-Medium'),
  ]) {
    final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

void main() {
  final now = DateTime.now();
  final thisMonday = AdaptiveFormula.dateKey(AdaptiveFormula.mondayOf(now));
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUpAll(_loadFonts);

  Future<void> pumpToday(
    WidgetTester tester, {
    required UserProfile profile,
    Entitlement? entitlement = _plus,
    DateTime? lastWeighIn,
    Map<String, Object> saved = const {adaptiveIntroShownKey: true},
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    final lastDay = lastWeighIn ?? now;
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('user-1'),
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
        latestWeightEntryProvider.overrideWith(
          (ref) => Stream<WeightEntry?>.value(weighIn(lastDay, 80)),
        ),
        mealsForDateProvider.overrideWith(
          (ref, date) => Stream.value(const <Meal>[]),
        ),
        dailySummaryForDateProvider.overrideWith(
          (ref, date) => Stream<DailySummary?>.value(null),
        ),
        dayOffProvider.overrideWith((ref, date) => Stream.value(false)),
        reviewSummariesProvider.overrideWith(
          (ref, range) => Stream.value(const {}),
        ),
        dailySummaryServiceProvider.overrideWithValue(
          DailySummaryService(
            mealRepository: _FakeMeals(),
            userProfileRepository: _FakeProfiles(),
            dailySummaryRepository: _FakeSummaries(),
            dayOffRepository: _FakeDaysOff(),
          ),
        ),
        aiUsageTodayProvider.overrideWith((ref) => Stream.value(0)),
        recentMealsProvider.overrideWith((ref) => Stream.value(const [])),
        recipesProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  UserProfile adapted(String note, {int kcal = 0, WeightLossPace? pace}) =>
      planProfile(
        adaptiveKcal: kcal,
        adaptiveWeek: thisMonday,
        adaptiveNote: note,
        pace: pace ?? WeightLossPace.fast,
      );

  /// The line, checked to fit in two lines on the phone.
  void expectLine(WidgetTester tester, String line) {
    final text = find.text(line);
    expect(text, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(text);
    final lineHeight = paragraph.getFullHeightForCaret(
      const TextPosition(offset: 0),
    );
    expect(paragraph.size.height, lessThan(2.5 * lineHeight));
  }

  /// None of the lines, from the start of each.
  void expectNoLine() {
    for (final start in [
      'Adjusted for you',
      'You may burn',
      'No change this week',
      'Your target is at',
      'Not enough',
      'Your numbers',
      'Paused',
    ]) {
      expect(find.textContaining(start), findsNothing);
    }
  }

  group('the Today line', () {
    final lines = {
      'lowered': (
        adapted('lowered', kcal: -80),
        'Adjusted for you: −80 kcal. You burn a little less than your plan '
            'assumed.',
      ),
      'raised': (
        adapted('raised', kcal: 80),
        'Adjusted for you: +80 kcal. You burn a little more than your plan '
            'assumed.',
      ),
      'first sign': (
        adapted('first_sign'),
        'You may burn a little less than your plan assumed. Checking again '
            'next Monday.',
      ),
      'no change, adjusted before': (
        adapted('steady', kcal: -160, pace: WeightLossPace.slow),
        'Adjusted for you: −160 kcal. No change this week.',
      ),
      'no change, never adjusted': (
        adapted('steady'),
        'No change this week: your weight matches what you eat.',
      ),
      'at the minimum': (
        adapted('lowered', kcal: -220),
        'Your target is at your minimum, so your goal date is now '
            '${DateFormat('d MMMM').format(AdaptiveFormula.planOf(adapted('lowered', kcal: -220), now: now).targetDate)}.',
      ),
      'not enough weigh-ins': (
        adapted('few_weigh_ins'),
        'Not enough weigh-ins this week, so your target stays the same.',
      ),
      'not enough logging': (
        adapted('few_days'),
        'Not enough days logged this week, so your target stays the same.',
      ),
      'unusual': (
        adapted('unusual'),
        'Your numbers look unusual. Check your logging and weigh-ins.',
      ),
    };
    for (final MapEntry(key: name, value: (profile, line)) in lines.entries) {
      testWidgets(name, (tester) async {
        await pumpToday(tester, profile: profile);
        expectLine(tester, line);
      });
    }

    testWidgets('paused, as soon as the last weigh-in is 10 days old', (
      tester,
    ) async {
      await pumpToday(
        tester,
        profile: adapted('steady'),
        lastWeighIn: DateTime(now.year, now.month, now.day - 10),
      );
      expectLine(
        tester,
        'Paused: no weigh-in for 10 days. Weigh in to keep it personal.',
      );
    });

    testWidgets('nothing for free users', (tester) async {
      await pumpToday(
        tester,
        profile: adapted('lowered', kcal: -80),
        entitlement: null,
      );
      expectNoLine();
    });

    testWidgets('nothing while learning', (tester) async {
      await pumpToday(tester, profile: adapted('learning'));
      expectNoLine();
    });

    testWidgets('nothing from an earlier week', (tester) async {
      await pumpToday(
        tester,
        profile: planProfile(
          adaptiveWeek: '2026-01-05',
          adaptiveNote: 'steady',
        ),
      );
      expectNoLine();
    });
  });

  group('the dialogs', () {
    testWidgets('the card\'s info button explains calories, then macros', (
      tester,
    ) async {
      await pumpToday(tester, profile: adapted('learning'));
      await tester.tap(find.byTooltip('About your targets'));
      await tester.pumpAndSettle();
      expect(find.text('Your targets'), findsOneWidget);
      double top(String text) => tester
          .getTopLeft(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text(text),
            ),
          )
          .dy;
      expect(top('Calories'), lessThan(top('Protein')));
      expect(
        find.textContaining('a little taken off if you\'re losing weight'),
        findsOneWidget,
      );
      expect(find.textContaining('UK'), findsNothing);
      expect(
        find.textContaining('Keep these under the amounts shown.'),
        findsOneWidget,
      );
    });

    testWidgets('How it works shows after subscribing', (tester) async {
      await pumpToday(tester, profile: adapted('learning'), saved: const {});
      expect(find.text(adaptiveSubtitle), findsOneWidget);
      expect(prefs.getBool(adaptiveIntroShownKey), isTrue);
      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(find.text(adaptiveSubtitle), findsNothing);
    });

    testWidgets('and only once', (tester) async {
      await pumpToday(tester, profile: adapted('learning'));
      expect(find.text(adaptiveSubtitle), findsNothing);
    });

    testWidgets('not for free users', (tester) async {
      await pumpToday(
        tester,
        profile: adapted('learning'),
        entitlement: null,
        saved: const {},
      );
      expect(find.text(adaptiveSubtitle), findsNothing);
    });

    testWidgets('"Log my weight" opens the weigh-in dialog', (tester) async {
      await pumpToday(tester, profile: adapted('learning'), saved: const {});
      await tester.tap(find.text('Log my weight'));
      await tester.pumpAndSettle();
      expect(find.text('Log your weight'), findsOneWidget);
    });

    Future<void> lapse(WidgetTester tester, {required bool shown}) async {
      final ended = Entitlement(
        active: false,
        source: EntitlementSource.play,
        state: 'expired',
        expiresAt: DateTime(now.year, now.month, now.day - 3, 12),
      );
      final back = AdaptiveFormula.lapseEnd(ended.expiresAt!);
      await pumpToday(
        tester,
        profile: adapted('lowered', kcal: -80),
        entitlement: ended,
        saved: {
          adaptiveIntroShownKey: true,
          if (shown) adaptiveLapseNoticeKey: AdaptiveFormula.dateKey(back),
        },
      );
      if (shown) {
        expect(find.text('Your YumSum Star has ended'), findsNothing);
        return;
      }
      expect(find.text('Your YumSum Star has ended'), findsOneWidget);
      expect(
        find.text(
          'Your target goes back to your standard plan on '
          '${DateFormat('d MMMM').format(back)}.',
        ),
        findsOneWidget,
      );
      expect(
        prefs.getString(adaptiveLapseNoticeKey),
        AdaptiveFormula.dateKey(back),
      );
    }

    testWidgets('the lapse notice shows once YumSum Star ends', (tester) async {
      await lapse(tester, shown: false);
    });

    testWidgets('but only once per end date', (tester) async {
      await lapse(tester, shown: true);
    });

    testWidgets('no lapse notice without an adjustment', (tester) async {
      await pumpToday(
        tester,
        profile: adapted('steady'),
        entitlement: Entitlement(
          active: false,
          source: EntitlementSource.play,
          expiresAt: DateTime(now.year, now.month, now.day - 3),
        ),
      );
      expect(find.text('Your YumSum Star has ended'), findsNothing);
    });
  });
}
