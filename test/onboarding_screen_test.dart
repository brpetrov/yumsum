import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';
import 'package:lean_streak/screens/onboarding/onboarding_screen.dart';
import 'package:lean_streak/widgets/health_plan_preview_card.dart';

typedef _Answers = ({
  String name,
  int age,
  Gender gender,
  double heightCm,
  double currentWeightKg,
  double? targetWeightKg,
  ActivityLevel activityLevel,
  TrainingFrequency trainingFrequency,
  WeightLossPace weightLossPace,
  String country,
  bool trackProtein,
  WeightUnit weightUnit,
  HeightUnit heightUnit,
});

class _FakeOnboardingController extends OnboardingController {
  final submitted = <_Answers>[];

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
      name: name,
      age: age,
      gender: gender,
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      activityLevel: activityLevel,
      trainingFrequency: trainingFrequency,
      weightLossPace: weightLossPace,
      country: country,
      trackProtein: trackProtein,
      weightUnit: weightUnit,
      heightUnit: heightUnit,
    ));
  }
}

class _FakeAuthController extends AuthController {
  int signOuts = 0;

  @override
  Future<void> signOut() async => signOuts++;
}

void main() {
  late _FakeOnboardingController onboarding;
  late _FakeAuthController auth;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('bg', 'BG');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    onboarding = _FakeOnboardingController();
    auth = _FakeAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith(() => onboarding),
          authControllerProvider.overrideWith(() => auth),
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

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  bool nextEnabled(WidgetTester tester) =>
      tester
          .widget<ElevatedButton>(
            find.ancestor(
              of: find.text('Next'),
              matching: find.byType(ElevatedButton),
            ),
          )
          .onPressed !=
      null;

  /// Name to current weight: Alex, Female, 34, 170 cm, 80 kg.
  Future<void> answerAboutYou(WidgetTester tester) async {
    expect(find.text('What\'s your name?'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);
    await type(tester, 'Alex');
    await next(tester);

    expect(find.text('Are you…'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);
    await tester.tap(find.text('Female'));
    await tester.pump();
    await next(tester);

    expect(find.text('How old are you?'), findsOneWidget);
    await type(tester, '34');
    await next(tester);

    expect(find.text('How tall are you?'), findsOneWidget);
    await type(tester, '170');
    await next(tester);

    expect(find.text('What do you weigh now?'), findsOneWidget);
    await type(tester, '80');
    await next(tester);
  }

  testWidgets('one question per card, then the plan and Start', (tester) async {
    await pump(tester);
    await answerAboutYou(tester);

    expect(find.text('What\'s your goal?'), findsOneWidget);
    expect(find.textContaining('A calorie is the energy in food.'), findsOne);
    await next(tester);

    expect(find.text('What weight are you aiming for?'), findsOneWidget);
    await type(tester, '70');
    await next(tester);

    expect(find.text('How active is your normal day?'), findsOneWidget);
    await tester.tap(find.text('On feet often'));
    await tester.pump();
    await next(tester);

    expect(find.text('Do you train on top of that?'), findsOneWidget);
    await tester.tap(find.text('1 to 2 sessions/week'));
    await tester.pump();
    await next(tester);

    expect(find.text('Track protein too?'), findsOneWidget);
    await next(tester);

    expect(find.text('Your plan is ready!'), findsOneWidget);
    expect(find.byType(HealthPlanPreviewCard), findsOneWidget);
    expect(find.textContaining('in Plan Settings'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(onboarding.submitted, [
      (
        name: 'Alex',
        age: 34,
        gender: Gender.female,
        heightCm: 170.0,
        currentWeightKg: 80.0,
        targetWeightKg: 70.0,
        activityLevel: ActivityLevel.moderatelyActive,
        trainingFrequency: TrainingFrequency.oneToTwo,
        weightLossPace: WeightLossPace.moderate,
        country: 'Bulgaria',
        trackProtein: true,
        weightUnit: WeightUnit.kg,
        heightUnit: HeightUnit.cm,
      ),
    ]);
  });

  testWidgets('the plan is built for a few seconds, with a fact and a line '
      'to start on, then shown', (tester) async {
    await pump(tester);
    await answerAboutYou(tester);
    await tester.tap(find.text('Keep my weight'));
    await tester.pump();
    await next(tester);
    await next(tester);
    await next(tester);
    expect(find.text('Track protein too?'), findsOneWidget);
    expect(
      find.textContaining('keep muscle while you lose weight'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Building your plan'), findsOneWidget);
    expect(find.text('Working out what you burn…'), findsOneWidget);
    expect(find.textContaining('1 in 8 people worldwide'), findsOneWidget);
    expect(find.text('World Health Organization, 2022'), findsOneWidget);
    final back = find.byWidgetPredicate((widget) => widget is TextButton);
    expect(tester.widget<TextButton>(back).onPressed, isNull);
    // The phone's back gesture waits too.
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500)); // the fade
    expect(find.textContaining('7,700 kcal'), findsOneWidget);
    expect(find.text('World Health Organization, 2022'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(
      find.textContaining('Today you start a journey with YumSum'),
      findsOneWidget,
    );
    expect(find.text('Your plan is ready!'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Your plan is ready!'), findsOneWidget);
    expect(find.text('Building your plan'), findsNothing);

    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);

    // Back from the plan goes to the last question, not through it again.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Track protein too?'), findsOneWidget);
  });

  testWidgets('someone gaining gets a fact on muscle first', (tester) async {
    await pump(tester);
    await answerAboutYou(tester);
    await tester.tap(find.text('Gain weight'));
    await tester.pump();
    await next(tester);
    await type(tester, '85');
    await next(tester);
    await next(tester);
    await next(tester);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('A small surplus is enough to build muscle'),
      findsOneWidget,
    );
    expect(find.textContaining('1 in 8 people'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('keeping weight skips the target weight', (tester) async {
    await pump(tester);
    await answerAboutYou(tester);
    expect(
      find.text('You can change this any time in Plan Settings.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep my weight'));
    await tester.pump();
    await next(tester);

    expect(find.text('How active is your normal day?'), findsOneWidget);
    await next(tester);
    await next(tester);
    await next(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(onboarding.submitted.single.weightLossPace, WeightLossPace.maintain);
    expect(onboarding.submitted.single.targetWeightKg, isNull);
  });

  testWidgets('gaining: three goals, a target over the current weight, and '
      'the plan in gain', (tester) async {
    await pump(tester);
    await answerAboutYou(tester);
    expect(find.text('Lose weight'), findsOneWidget);
    expect(find.text('Keep my weight'), findsOneWidget);
    expect(find.text('Gain weight'), findsOneWidget);
    await tester.tap(find.text('Gain weight'));
    await tester.pump();
    await next(tester);

    expect(find.text('What weight are you aiming for?'), findsOneWidget);
    await type(tester, '75');
    expect(find.text('Must be more than your current weight'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);
    await type(tester, '80');
    expect(nextEnabled(tester), isFalse);
    await type(tester, '85');
    expect(nextEnabled(tester), isTrue);
    await next(tester);
    await next(tester);
    await next(tester);
    await next(tester);

    expect(find.text('Your plan is ready!'), findsOneWidget);
    expect(find.text('Weekly gain'), findsOneWidget);
    expect(find.text('0.25 kg/wk'), findsOneWidget);
    expect(find.text('Sustainable pace'), findsOneWidget);
    expect(
      find.text('A small surplus over estimated maintenance.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(onboarding.submitted.single.weightLossPace, WeightLossPace.gain);
    expect(onboarding.submitted.single.targetWeightKg, 85);
  });

  testWidgets('a target at or over the current weight can\'t go on', (
    tester,
  ) async {
    await pump(tester);
    await answerAboutYou(tester);
    await next(tester);

    await type(tester, '85');
    expect(find.text('Must be less than your current weight'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);
    await type(tester, '75');
    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('Back goes to the card before; on the first, to sign in', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'Alex');
    await next(tester);
    expect(find.text('Are you…'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('What\'s your name?'), findsOneWidget);
    expect(auth.signOuts, 0);

    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
  });

  testWidgets('Debug tools\' preview: Back on the first card and Start go '
      'back without saving or signing out', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('bg', 'BG');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    onboarding = _FakeOnboardingController();
    auth = _FakeAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith(() => onboarding),
          authControllerProvider.overrideWith(() => auth),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Debug tools')),
        ),
      ),
    );
    final debug = tester.element(find.text('Debug tools'));
    final container = ProviderScope.containerOf(debug);
    Future<void> open() async {
      container.read(onboardingPreviewProvider.notifier).state = true;
      Navigator.of(
        debug,
      ).push(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()));
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.text('Back to sign in'), findsNothing);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Debug tools'), findsOneWidget);
    expect(auth.signOuts, 0);
    expect(container.read(onboardingPreviewProvider), isFalse);

    await open();
    await answerAboutYou(tester);
    await next(tester);
    await type(tester, '70');
    await next(tester);
    await tester.tap(find.text('On feet often'));
    await tester.pump();
    await next(tester);
    await tester.tap(find.text('1 to 2 sessions/week'));
    await tester.pump();
    await next(tester);
    await next(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Debug tools'), findsOneWidget);
    expect(onboarding.submitted, isEmpty);
    expect(container.read(onboardingPreviewProvider), isFalse);
  });

  testWidgets('protein tracking can be turned off', (tester) async {
    await pump(tester);
    await answerAboutYou(tester);
    await tester.tap(find.text('Keep my weight'));
    await tester.pump();
    await next(tester);
    await next(tester);
    await next(tester);
    expect(find.text('Track protein too?'), findsOneWidget);
    await tester.tap(find.text('No'));
    await tester.pump();
    await next(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(onboarding.submitted.single.trackProtein, isFalse);
  });

  test('the country from the phone\'s region', () {
    expect(countryNameFor('GB'), 'United Kingdom');
    expect(countryNameFor('bg'), 'Bulgaria');
    expect(countryNameFor('XX'), 'XX');
    expect(countryNameFor(null), defaultCountry);
    expect(countryNameFor(''), defaultCountry);
  });
}
