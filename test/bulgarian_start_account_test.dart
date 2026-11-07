import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/account/account_settings_screen.dart';
import 'package:lean_streak/screens/auth/auth_screen.dart';
import 'package:lean_streak/screens/profile/profile_load_error_screen.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/feedback_dialog.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/plan_choices.dart';
import 'package:lean_streak/widgets/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_fixtures.dart';

// The start, the account pages and the menu in Bulgarian, on a 360 dp phone:
// the words are there and nothing overflows.

class _FakeAccountController extends AccountController {
  @override
  Future<void> syncAuthEmailToProfile() async {}
}

/// Sign-in that has just failed with [code].
class _FailedAuth extends AuthController {
  _FailedAuth(this.code);

  final String code;

  @override
  Future<AuthStatus> build() async => throw FirebaseAuthException(code: code);
}

final _now = DateTime(2026, 11, 7);
final _profile = UserProfile(
  uid: 'test',
  email: 'a@b.com',
  name: 'Мария',
  age: 30,
  gender: Gender.female,
  heightCm: 168,
  currentWeightKg: 70,
  targetWeightKg: 62,
  activityLevel: ActivityLevel.lightlyActive,
  trainingFrequency: TrainingFrequency.oneToTwo,
  activityScaleVersion: currentActivityScaleVersion,
  planCalculationVersion: currentPlanCalculationVersion,
  weightLossPace: WeightLossPace.moderate,
  targetDate: _now.add(const Duration(days: 120)),
  bmi: 24.8,
  bmr: 1450,
  tdee: 1950,
  dailyCalorieTarget: 1500,
  goalPaceKgPerWeek: 0.5,
  goalPaceLevel: GoalPaceLevel.values.first,
  onboardingCompleted: true,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  late SharedPreferences prefs;

  /// [home] in Bulgarian on a 360 × 780 phone, with [stored] preferences.
  Future<void> pumpBg(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
    Map<String, Object> stored = const {},
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'language': 'bg', ...stored});
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('test'),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          entitlementProvider.overrideWith((ref) => Stream.value(null)),
          realEntitlementProvider.overrideWith((ref) => Stream.value(null)),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('bg'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    // The splash's spinner never settles.
    settle ? await tester.pumpAndSettle() : await tester.pump();
  }

  /// Fails on any overflow or other error drawn so far.
  void fits(WidgetTester tester) => expect(tester.takeException(), isNull);

  testWidgets('sign-in', (tester) async {
    await pumpBg(tester, const AuthScreen());

    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Влез'), findsOneWidget);
    expect(find.text('Имейл'), findsOneWidget);
    expect(find.text('Забравена парола?'), findsOneWidget);
    expect(find.text('Продължи с Google'), findsOneWidget);
    expect(
      find.textContaining(
        'Като продължиш, приемаш Условията за ползване и Политиката за '
        'поверителност.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    fits(tester);

    await tester.tap(find.text('Регистрация'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Създай профил'));
    await tester.tap(find.text('Създай профил'));
    await tester.pumpAndSettle();
    expect(find.text('Въведи имейла си.'), findsOneWidget);
    expect(find.text('Въведи паролата си.'), findsOneWidget);
    fits(tester);
  });

  testWidgets('a sign-in error from Firebase', (tester) async {
    await pumpBg(
      tester,
      const AuthScreen(),
      overrides: [
        authControllerProvider.overrideWith(
          () => _FailedAuth('wrong-password'),
        ),
      ],
    );

    expect(find.text('Грешен имейл или парола.'), findsOneWidget);
    fits(tester);
  });

  testWidgets('the menu', (tester) async {
    await pumpBg(
      tester,
      const AppFrame(title: 'Начало', body: SizedBox.expand()),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    for (final page in [
      'Начало',
      'История',
      'AI треньор',
      'Рецепти',
      'Тегло и напредък',
      'Настройки на плана',
      'Известия',
      'Настройки на профила',
      'Изход',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(page)),
        findsOneWidget,
        reason: page,
      );
    }
    await tester.scrollUntilVisible(
      find.text('Български'),
      100,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Изглед'), findsOneWidget);
    expect(find.text('Системен'), findsOneWidget);
    expect(find.text('Тъмен'), findsOneWidget);
    expect(find.text('Език'), findsOneWidget);
    fits(tester);
  });

  testWidgets('Account Settings and its dialogs', (tester) async {
    await pumpBg(
      tester,
      const AccountSettingsScreen(),
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(_profile)),
        accountControllerProvider.overrideWith(_FakeAccountController.new),
        billingServiceProvider.overrideWithValue(FakeBillingService()),
        billingRepositoryProvider.overrideWithValue(FakeBillingRepository()),
      ],
    );

    expect(find.text('Настройки на профила'), findsOneWidget);
    expect(find.text('Управлявай профила си'), findsOneWidget);
    expect(find.text('Смени името, имейла или паролата си.'), findsOneWidget);
    expect(find.text('ПРОФИЛ'), findsOneWidget);
    expect(find.text('Запази името'), findsOneWidget);
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Изтрий профила'),
      200,
      scrollable: page,
    );
    expect(find.text('ПОМОЩ И ПРАВНА ИНФОРМАЦИЯ'), findsOneWidget);
    expect(find.text('Изпрати обратна връзка'), findsOneWidget);
    expect(find.text('Нулирай всички данни'), findsOneWidget);
    fits(tester);

    await tester.tap(find.text('Изтрий профила'));
    await tester.pumpAndSettle();
    expect(find.text('Да изтрием ли профила?'), findsOneWidget);
    expect(
      find.text(
        'Това изтрива профила ти и всичко в него. Не може да се отмени.',
      ),
      findsOneWidget,
    );
    expect(find.text('Парола'), findsOneWidget);
    fits(tester);
    await tester.tap(find.text('Отказ'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Смени имейла'),
      -200,
      scrollable: page,
    );
    await tester.tap(find.text('Смени имейла'));
    await tester.pumpAndSettle();
    expect(find.text('Смяна на имейла'), findsOneWidget);
    expect(find.text('Текуща парола'), findsOneWidget);
    expect(find.text('Изпрати линка'), findsOneWidget);
    fits(tester);
  });

  testWidgets('the feedback dialog, once the day\'s 3 are sent', (
    tester,
  ) async {
    await pumpBg(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showFeedbackDialog(context),
          child: const Text('open'),
        ),
      ),
      stored: {
        'feedback.sent_day': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'feedback.sent_count': 3,
      },
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Обратна връзка'), findsOneWidget);
    expect(find.text('Проблем'), findsOneWidget);
    expect(find.text('Идея'), findsOneWidget);
    expect(find.text('Какво се случи и какво очакваше?'), findsOneWidget);
    expect(
      find.text('Днес вече изпрати 3 съобщения. Утре можеш да изпратиш още.'),
      findsOneWidget,
    );
    expect(find.text('Изпрати'), findsOneWidget);
    fits(tester);
  });

  testWidgets('the plan choices, with the pace in Bulgarian numbers', (
    tester,
  ) async {
    await pumpBg(
      tester,
      Scaffold(
        body: ListView(
          children: [
            for (final level in ActivityLevel.values)
              ActivityCard(level: level, selected: false, onTap: () {}),
            for (final frequency in TrainingFrequency.values)
              TrainingCard(frequency: frequency, selected: true, onTap: () {}),
            for (final pace in WeightLossPace.values)
              PaceCard(
                pace: pace,
                weightUnit: WeightUnit.kg,
                selected: false,
                onTap: () {},
              ),
            const MedicalNote(),
          ],
        ),
      ),
    );

    expect(find.text('Предимно седене'), findsOneWidget);
    expect(find.text('Физическа работа или много движение'), findsOneWidget);
    expect(find.text('1–2 тренировки седмично'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(MedicalNote), 200);
    expect(find.text('Бавно – 0,25 кг седмично'), findsOneWidget);
    expect(find.text('Умерено – 0,5 кг седмично'), findsOneWidget);
    expect(find.text('Бързо – 0,75 кг седмично'), findsOneWidget);
    expect(find.textContaining('не медицински съвет'), findsOneWidget);
    fits(tester);
  });

  testWidgets('the profile that didn\'t load, and the splash', (tester) async {
    await pumpBg(tester, const ProfileLoadErrorScreen());
    expect(find.text('Не успяхме да заредим профила ти'), findsOneWidget);
    expect(find.text('Опитай отново'), findsOneWidget);
    expect(find.text('Обратно към входа'), findsOneWidget);
    fits(tester);

    await pumpBg(tester, const SplashScreen(), settle: false);
    expect(
      find.text('Постоянство всеки ден. Винаги във форма.'),
      findsOneWidget,
    );
    fits(tester);
  });

  test('the account\'s errors come in the app\'s language', () async {
    SharedPreferences.setMockInitialValues({'language': 'bg'});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        currentUidProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(accountControllerProvider.notifier)
          .updateAccountName(name: 'Мария'),
      throwsA(
        isA<AccountActionException>().having(
          (error) => error.message,
          'message',
          'Влез отново в профила си.',
        ),
      ),
    );
  });
}
