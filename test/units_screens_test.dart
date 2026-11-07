import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/onboarding/onboarding_screen.dart';
import 'package:lean_streak/screens/profile/profile_screen.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/services/weight_log_service.dart';

import 'adaptive_fixtures.dart';

typedef _Body = ({
  double heightCm,
  double currentWeightKg,
  double? targetWeightKg,
  WeightUnit weightUnit,
  HeightUnit heightUnit,
});

class _FakeOnboardingController extends OnboardingController {
  final submitted = <_Body>[];

  @override
  Future<void> submit({
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
    required bool trackProtein,
    required WeightUnit weightUnit,
    required HeightUnit heightUnit,
  }) async {
    submitted.add((
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      weightUnit: weightUnit,
      heightUnit: heightUnit,
    ));
  }
}

class _FakeProfileController extends ProfileController {
  final saved = <_Body>[];

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
    required bool trackProtein,
    required WeightUnit weightUnit,
    required HeightUnit heightUnit,
  }) async {
    saved.add((
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      weightUnit: weightUnit,
      heightUnit: heightUnit,
    ));
    return true;
  }
}

class _FakeWeightLogController extends WeightLogController {
  final logged = <double>[];

  @override
  Future<WeightLogResult?> logWeight({
    required double weightKg,
    WeightSource source = WeightSource.manual,
  }) async {
    logged.add(weightKg);
    return WeightLogResult(
      profile: planProfile(),
      previousCalorieTarget: 1670,
      newCalorieTarget: 1670,
    );
  }
}

class _FakeAuthController extends AuthController {
  @override
  Future<void> signOut() async {}
}

TextField _box(WidgetTester tester, String label, {int at = 0}) =>
    tester.widget<TextField>(find.widgetWithText(TextField, label).at(at));

Future<void> _type(
  WidgetTester tester,
  String label,
  String text, {
  int at = 0,
}) async {
  await tester.enterText(find.widgetWithText(TextField, label).at(at), text);
  await tester.pump();
}

void main() {
  group('onboarding', () {
    late _FakeOnboardingController onboarding;

    Future<void> pump(WidgetTester tester, Locale locale) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localeTestValue = locale;
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      onboarding = _FakeOnboardingController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingControllerProvider.overrideWith(() => onboarding),
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> next(WidgetTester tester) async {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    Future<void> toHeight(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'Alex');
      await tester.pump();
      await next(tester);
      await tester.tap(find.text('Female'));
      await tester.pump();
      await next(tester);
      await tester.enterText(find.byType(TextField), '34');
      await tester.pump();
      await next(tester);
      expect(find.text('How tall are you?'), findsOneWidget);
    }

    Future<void> toStart(WidgetTester tester) async {
      for (final _ in List.filled(3, 0)) {
        await next(tester);
      }
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
    }

    testWidgets('in the UK: feet and inches, stones and pounds', (
      tester,
    ) async {
      await pump(tester, const Locale('en', 'GB'));
      await toHeight(tester);

      expect(find.text('ft & in'), findsOneWidget);
      await _type(tester, 'Height', '5');
      await _type(tester, 'Inches', '7');
      await next(tester);

      expect(find.text('st & lb'), findsOneWidget);
      await _type(tester, 'Current weight', '12');
      await _type(tester, 'Pounds', '8');
      await next(tester);
      await next(tester);

      await _type(tester, 'Target weight', '13');
      expect(
        find.text('Must be less than your current weight'),
        findsOneWidget,
      );
      await _type(tester, 'Target weight', '11');
      await next(tester);
      await toStart(tester);

      final body = onboarding.submitted.single;
      expect(body.heightCm, closeTo(67 * cmPerInch, 1e-9));
      expect(body.currentWeightKg, closeTo(lbToKg(176), 1e-9));
      expect(body.targetWeightKg, closeTo(lbToKg(154), 1e-9));
      expect(body.weightUnit, WeightUnit.st);
      expect(body.heightUnit, HeightUnit.ftin);
    });

    testWidgets('in the US: pounds, and the ranges in pounds', (tester) async {
      await pump(tester, const Locale('en', 'US'));
      await toHeight(tester);
      await _type(tester, 'Height', '9');
      expect(find.text('3 ft 4 in–8 ft 2 in'), findsOneWidget);
      await _type(tester, 'Height', '5');
      await _type(tester, 'Inches', '10');
      await next(tester);

      expect(_box(tester, 'Current weight').decoration!.suffixText, 'lb');
      await _type(tester, 'Current weight', '50');
      expect(find.text('67–661 lb'), findsOneWidget);
      await _type(tester, 'Current weight', '180');
      await next(tester);
      await tester.tap(find.text('Keep my weight'));
      await tester.pump();
      await next(tester);
      await toStart(tester);

      final body = onboarding.submitted.single;
      expect(body.currentWeightKg, closeTo(lbToKg(180), 1e-9));
      expect(body.weightUnit, WeightUnit.lb);
      expect(body.heightUnit, HeightUnit.ftin);
    });

    testWidgets('a card\'s toggle switches the unit and keeps the number', (
      tester,
    ) async {
      await pump(tester, const Locale('en', 'GB'));
      await toHeight(tester);
      await tester.tap(find.text('cm'));
      await tester.pump();
      await _type(tester, 'Height', '170');
      await next(tester);

      await _type(tester, 'Current weight', '12');
      await _type(tester, 'Pounds', '8');
      await tester.tap(find.text('kg'));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Pounds'), findsNothing);
      expect(_box(tester, 'Current weight').controller!.text, '79.8');
      await _type(tester, 'Current weight', '80');
      await next(tester);
      await tester.tap(find.text('Keep my weight'));
      await tester.pump();
      await next(tester);
      await toStart(tester);

      final body = onboarding.submitted.single;
      expect(body.heightCm, 170);
      expect(body.currentWeightKg, 80);
      expect(body.weightUnit, WeightUnit.kg);
      expect(body.heightUnit, HeightUnit.cm);
    });
  });

  group('Plan Settings', () {
    late _FakeProfileController controller;

    Future<void> pump(WidgetTester tester, UserProfile profile) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      controller = _FakeProfileController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) => Stream.value(profile)),
            entitlementProvider.overrideWith(
              (ref) => Stream<Entitlement?>.value(null),
            ),
            adaptiveProgressProvider.overrideWith(
              (ref) async => const AdaptiveMeasure(
                hold: AdaptiveNote.learning,
                days: 3,
                weighIns: 1,
                daysLogged: 3,
              ),
            ),
            profileControllerProvider.overrideWith(() => controller),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
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
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      final button = find.text('Save plan');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    final imperial = planProfile().copyWith(
      weightUnit: WeightUnit.st,
      heightUnit: HeightUnit.ftin,
    );

    testWidgets('in stones and feet, saved untouched, nothing changes', (
      tester,
    ) async {
      await pump(tester, imperial);
      // 170 cm, 79.8 kg and 73 kg.
      expect(_box(tester, 'Height').controller!.text, '5');
      expect(_box(tester, 'Inches').controller!.text, '6.9');
      expect(_box(tester, 'Current weight').controller!.text, '12');
      expect(_box(tester, 'Pounds').controller!.text, '7.9');
      expect(_box(tester, 'Target weight').controller!.text, '11');
      expect(_box(tester, 'Pounds', at: 1).controller!.text, '6.9');
      expect(find.text('Moderate - 1.1 lb/week'), findsOneWidget);

      await save(tester);
      expect(controller.saved, [
        (
          heightCm: 170.0,
          currentWeightKg: 79.8,
          targetWeightKg: 73.0,
          weightUnit: WeightUnit.st,
          heightUnit: HeightUnit.ftin,
        ),
      ]);
    });

    testWidgets('a weight typed in stones is saved in kg', (tester) async {
      await pump(tester, imperial);
      await _type(tester, 'Pounds', '0');
      await save(tester);
      expect(controller.saved.single.currentWeightKg, lbToKg(168));
    });

    testWidgets('the units choice switches the boxes and is saved', (
      tester,
    ) async {
      await pump(tester, imperial);
      await tester.tap(find.text('kg'));
      await tester.tap(find.text('cm'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Pounds'), findsNothing);
      expect(_box(tester, 'Height').controller!.text, '170');
      expect(_box(tester, 'Current weight').controller!.text, '79.8');
      expect(find.text('Moderate - 0.5 kg/week'), findsOneWidget);

      await save(tester);
      expect(controller.saved.single, (
        heightCm: 170.0,
        currentWeightKg: 79.8,
        targetWeightKg: 73.0,
        weightUnit: WeightUnit.kg,
        heightUnit: HeightUnit.cm,
      ));
    });

    testWidgets('a weight out of range says so in its unit', (tester) async {
      await pump(tester, imperial);
      await _type(tester, 'Current weight', '2');
      await save(tester);
      expect(find.text('4 st 11 lb–47 st 3 lb'), findsOneWidget);
      expect(controller.saved, isEmpty);
    });
  });

  testWidgets('the weigh-in in stones', (tester) async {
    final controller = _FakeWeightLogController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) =>
                Stream.value(planProfile().copyWith(weightUnit: WeightUnit.st)),
          ),
          weightLogControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(userProfileProvider);
              return Scaffold(
                body: TextButton(
                  onPressed: () => showLogWeightDialog(context),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(_box(tester, 'Current weight').controller!.text, '12');
    expect(_box(tester, 'Pounds').controller!.text, '7.9');
    await _type(tester, 'Current weight', '2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a weight between 4 st 0 lb and 62 st 13 lb.'),
      findsOneWidget,
    );

    await _type(tester, 'Current weight', '12');
    await _type(tester, 'Pounds', '4');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(controller.logged, [lbToKg(172)]);
  });
}
