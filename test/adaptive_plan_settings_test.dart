import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/profile/profile_screen.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

import 'adaptive_fixtures.dart';

class _FakeProfileController extends ProfileController {
  final saved = <({bool adaptiveOn, TrainingFrequency training})>[];

  @override
  Future<bool> saveProfile({
    required UserProfile currentProfile,
    required String name,
    required int age,
    required Gender gender,
    required double heightCm,
    required double currentWeightKg,
    required double? targetWeightKg,
    required ActivityLevel activityLevel,
    required TrainingFrequency trainingFrequency,
    required WeightLossPace weightLossPace,
    required String country,
    required String usualFood,
    required bool trackProtein,
    required bool adaptiveOn,
  }) async {
    saved.add((adaptiveOn: adaptiveOn, training: trainingFrequency));
    return true;
  }
}

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

void main() {
  late _FakeProfileController controller;

  Future<void> pumpSettings(
    WidgetTester tester, {
    Entitlement? entitlement = _plus,
    int adaptiveKcal = -80,
    AdaptiveMeasure progress = const AdaptiveMeasure(
      hold: AdaptiveNote.learning,
      days: 13,
      weighIns: 11,
      daysLogged: 13,
    ),
  }) async {
    controller = _FakeProfileController();
    final profile = planProfile(adaptiveKcal: adaptiveKcal);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          adaptiveProgressProvider.overrideWith((ref) async => progress),
          profileControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          // Saving pops back to the page before.
          routerConfig: GoRouter(
            initialLocation: '/plan',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: Text('Home')),
                routes: [
                  GoRoute(
                    path: 'plan',
                    builder: (_, _) => const PlanSettingsScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.plus,
                builder: (_, _) => const Scaffold(body: Text('The paywall')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final adaptiveSwitch = find.widgetWithText(
    SwitchListTile,
    'Adaptive formula',
  );

  Future<void> showSwitch(WidgetTester tester) async {
    await tester.ensureVisible(adaptiveSwitch);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a free user sees it off with the star; a tap opens the paywall',
    (tester) async {
      await pumpSettings(tester, entitlement: null, adaptiveKcal: 0);
      await showSwitch(tester);
      expect(tester.widget<SwitchListTile>(adaptiveSwitch).value, isFalse);
      expect(
        find.descendant(of: adaptiveSwitch, matching: find.byType(PlusStar)),
        findsOneWidget,
      );
      expect(find.textContaining('from your plan'), findsNothing);

      await tester.tap(adaptiveSwitch);
      await tester.pumpAndSettle();
      expect(find.text('The paywall'), findsOneWidget);
    },
  );

  testWidgets('a subscriber sees the sum and how well it knows them', (
    tester,
  ) async {
    await pumpSettings(tester);
    await showSwitch(tester);
    expect(tester.widget<SwitchListTile>(adaptiveSwitch).value, isTrue);
    expect(
      find.descendant(of: adaptiveSwitch, matching: find.byType(PlusStar)),
      findsNothing,
    );
    expect(
      find.text('1670 from your plan − 80 adaptive = 1590 kcal'),
      findsOneWidget,
    );
    expect(find.text('Learning: 11 weigh-ins, 13 days logged'), findsOneWidget);
    expect(
      find.text('Saving starts it again from your new plan.'),
      findsNothing,
    );
  });

  testWidgets('at the minimum, the sum says so', (tester) async {
    await pumpSettings(
      tester,
      adaptiveKcal: -220,
      progress: const AdaptiveMeasure(
        hold: null,
        days: 35,
        weighIns: 33,
        daysLogged: 35,
        gap: -226,
        confidence: 0.55,
      ),
    );
    await showSwitch(tester);
    expect(
      find.text('1670 from your plan − 170 adaptive = 1500 kcal, your minimum'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Knows you fairly well: 33 weigh-ins and 35 days logged in 5 weeks',
      ),
      findsOneWidget,
    );
  });

  testWidgets('switching it off and saving passes adaptiveOn: false', (
    tester,
  ) async {
    await pumpSettings(tester);
    await showSwitch(tester);
    await tester.tap(adaptiveSwitch);
    await tester.pumpAndSettle();
    expect(find.textContaining('from your plan'), findsNothing);

    await tester.ensureVisible(find.text('Save plan'));
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(controller.saved.single.adaptiveOn, isFalse);
  });

  testWidgets('a free user saving keeps the stored switch', (tester) async {
    await pumpSettings(tester, entitlement: null);
    await tester.ensureVisible(find.text('Save plan'));
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(controller.saved.single.adaptiveOn, isTrue);
  });

  testWidgets('changing training says saving starts it again', (tester) async {
    await pumpSettings(tester);
    final training = find.text('5+ sessions/week');
    await tester.ensureVisible(training);
    await tester.tap(training);
    await tester.pumpAndSettle();
    await showSwitch(tester);
    expect(
      find.text('Saving starts it again from your new plan.'),
      findsOneWidget,
    );
    // The preview no longer counts the old adjustment.
    expect(find.textContaining('+ 0 adaptive'), findsOneWidget);
  });
}
