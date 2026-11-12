import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/app.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/activity_scale_migration_provider.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/account/account_settings_screen.dart';
import 'package:lean_streak/screens/auth/auth_screen.dart';
import 'package:lean_streak/screens/debug/debug_screen.dart';
import 'package:lean_streak/screens/language/language_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_fixtures.dart';
import 'billing_fixtures.dart';

class _FakeAccountController extends AccountController {
  @override
  Future<void> syncAuthEmailToProfile() async {}
}

void main() {
  late SharedPreferences prefs;

  /// The whole app, signed out (or with [profile]), on a device set to
  /// [region] and [language], with [router] standing in for the real one
  /// when given.
  Future<void> pumpApp(
    WidgetTester tester, {
    String? region = 'GB',
    String language = 'en',
    String? stored,
    GoRouter? router,
    UserProfile? profile,
  }) async {
    SharedPreferences.setMockInitialValues({'language': ?stored});
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceRegionProvider.overrideWithValue(region),
          deviceLanguageProvider.overrideWithValue(language),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          accountControllerProvider.overrideWith(_FakeAccountController.new),
          entitlementProvider.overrideWith((ref) => Stream.value(null)),
          realEntitlementProvider.overrideWith((ref) => Stream.value(null)),
          billingServiceProvider.overrideWithValue(FakeBillingService()),
          activityScaleMigrationProvider.overrideWith((ref) async {}),
          adaptiveMondayProvider.overrideWith((ref) async {}),
          reminderSyncProvider.overrideWith((ref) async {}),
          if (router != null) goRouterProvider.overrideWithValue(router),
        ],
        child: const LeanStreakApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Locale appLocale(WidgetTester tester) =>
      Localizations.localeOf(tester.element(find.byType(Scaffold).first));

  testWidgets('context.l10n falls back to English without delegates', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            return Text(l10n.languageEnglish);
          },
        ),
      ),
    );

    expect(l10n.localeName, 'en');
    expect(find.text('English'), findsOneWidget);
  });

  group('the language question before sign-in', () {
    for (final (region, language) in [
      ('BG', 'bg'),
      ('MT', 'en'),
      ('GB', 'bg'),
      (null, 'bg'),
    ]) {
      testWidgets('is asked for region $region, language $language', (
        tester,
      ) async {
        await pumpApp(tester, region: region, language: language);

        expect(find.byType(LanguageScreen), findsOneWidget);
        expect(find.text('Choose your language'), findsOneWidget);
        expect(find.text('Избери език'), findsOneWidget);
        expect(find.byType(AuthScreen), findsNothing);
      });
    }

    for (final region in ['GB', 'US', null]) {
      testWidgets('is not asked for region $region in English', (tester) async {
        await pumpApp(tester, region: region);

        expect(find.byType(LanguageScreen), findsNothing);
        expect(find.byType(AuthScreen), findsOneWidget);
        expect(appLocale(tester), const Locale('en'));
      });
    }

    testWidgets('is not asked again once chosen', (tester) async {
      await pumpApp(tester, region: 'BG', stored: 'en');

      expect(find.byType(LanguageScreen), findsNothing);
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('choosing Български saves it and goes on to sign-in', (
      tester,
    ) async {
      await pumpApp(tester, region: 'BG');
      await tester.tap(find.text('Български'));
      await tester.pumpAndSettle();

      expect(prefs.getString('language'), 'bg');
      expect(find.byType(LanguageScreen), findsNothing);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(appLocale(tester), const Locale('bg'));
    });

    testWidgets('choosing English saves it and goes on to sign-in', (
      tester,
    ) async {
      await pumpApp(tester, region: 'MT');
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(prefs.getString('language'), 'en');
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(appLocale(tester), const Locale('en'));
    });
  });

  testWidgets('Debug tools\' onboarding preview asks the language first, '
      'goes on in it, and puts the device\'s own back after', (tester) async {
    Locale? onboardingIn;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => previewOnboarding(context, ref),
                child: const Text('Preview'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.language,
          builder: (_, _) => const LanguageScreen(),
        ),
        // Onboarding itself, whose preview is tested on its own.
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, _) {
            onboardingIn = Localizations.localeOf(context);
            return Scaffold(
              body: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Leave'),
              ),
            );
          },
        ),
      ],
    );
    await pumpApp(tester, router: router, profile: planProfile(), stored: 'en');

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageScreen), findsOneWidget);

    await tester.tap(find.text('Български'));
    await tester.pumpAndSettle();
    expect(find.text('Leave'), findsOneWidget);
    expect(onboardingIn, const Locale('bg'));

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    expect(prefs.getString('language'), 'en');
    expect(appLocale(tester), const Locale('en'));
  });

  testWidgets('Settings switches the language at once', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AccountSettingsScreen()),
      ],
    );
    await pumpApp(tester, router: router, profile: planProfile());

    await tester.scrollUntilVisible(
      find.text('Български'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('LANGUAGE'), findsOneWidget);

    await tester.tap(find.text('Български'));
    await tester.pumpAndSettle();

    expect(find.text('ЕЗИК'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsNothing);
    expect(appLocale(tester), const Locale('bg'));
    expect(prefs.getString('language'), 'bg');
  });

  testWidgets('Settings has no language choice outside Bulgaria, Malta and '
      'the UK', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AccountSettingsScreen()),
      ],
    );
    await pumpApp(tester, region: 'US', router: router, profile: planProfile());

    expect(find.text('APPEARANCE', skipOffstage: false), findsOneWidget);
    expect(find.text('LANGUAGE', skipOffstage: false), findsNothing);
    expect(find.text('Български', skipOffstage: false), findsNothing);
  });

  group('the language choice in Settings', () {
    Future<bool> offered({
      String? region,
      String language = 'en',
      String? stored,
    }) async {
      SharedPreferences.setMockInitialValues({'language': ?stored});
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          deviceRegionProvider.overrideWithValue(region),
          deviceLanguageProvider.overrideWithValue(language),
        ],
      );
      addTearDown(container.dispose);
      return container.read(languageChoiceProvider);
    }

    test('is offered in Bulgaria, Malta and the UK', () async {
      for (final region in ['BG', 'MT', 'GB', 'gb']) {
        expect(await offered(region: region), isTrue, reason: region);
      }
    });

    test('is not offered elsewhere in English', () async {
      for (final region in ['US', 'DE', null]) {
        expect(await offered(region: region), isFalse, reason: '$region');
      }
    });

    test('is offered anywhere on a Bulgarian device', () async {
      expect(await offered(region: 'DE', language: 'bg'), isTrue);
    });

    test(
      'stays while Bulgarian is chosen, so it can be switched back',
      () async {
        expect(await offered(region: 'US', stored: 'bg'), isTrue);
        expect(await offered(region: 'US', stored: 'en'), isFalse);
      },
    );
  });

  test('l10nProvider and the server language follow the setting', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(languageCodeProvider), 'en');
    expect(container.read(l10nProvider).reminderCreatineTitle, 'Creatine time');

    await container.read(languageControllerProvider.notifier).setLanguage('bg');

    expect(container.read(languageCodeProvider), 'bg');
    expect(
      container.read(l10nProvider).reminderCreatineTitle,
      'Време за креатин',
    );
  });

  group('dates and numbers', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final bg = lookupAppLocalizations(const Locale('bg'));
    final saturday = DateTime(2026, 11, 7, 20, 30);

    test('dates read in the language', () {
      expect(bg.dayMonth(saturday), '7 ноември');
      expect(bg.weekdayDayMonth(saturday), 'събота, 7 ноември');
      expect(capitalised(bg.weekdayDayMonth(saturday)), 'Събота, 7 ноември');
      expect(bg.shortWeekdayDayMonth(saturday), 'сб, 7 ное');
      expect(bg.monthYear(saturday), 'ноември 2026');
      expect(bg.time(saturday), '20:30');

      expect(en.dayMonth(saturday), '7 November');
      expect(en.weekdayDayMonth(saturday), 'Saturday, 7 November');
      expect(en.shortWeekdayDayMonth(saturday), 'Sat, 7 Nov');
      expect(en.monthYear(saturday), 'November 2026');
    });

    test('decimals use a comma in Bulgarian', () {
      expect(bg.decimal(1.5), '1,5');
      expect(bg.decimal(72.25, 2), '72,25');
      expect(bg.decimal(1500.0, 0), '1500');
      expect(en.decimal(1.5), '1.5');
      expect(en.decimal(72.0), '72.0');
    });

    test('typed decimals take a comma or a point', () {
      expect(parseDecimal('1,5'), 1.5);
      expect(parseDecimal(' 72.4 '), 72.4);
      expect(parseDecimal('abc'), isNull);
    });
  });
}
