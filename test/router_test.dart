import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/app/app.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/activity_scale_migration_provider.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/auth/auth_screen.dart';
import 'package:lean_streak/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_fixtures.dart';

class _FakeAccountController extends AccountController {
  @override
  Future<void> syncAuthEmailToProfile() async {}
}

class _Login extends Fake implements UserInfo {
  _Login(this.providerId);

  @override
  final String providerId;
}

/// Signed in with [provider] ('password' or 'google.com').
class _User extends Fake implements User {
  _User(String provider, {required this.emailVerified})
    : providerData = [_Login(provider)];

  @override
  final bool emailVerified;

  @override
  final List<UserInfo> providerData;

  @override
  String get uid => 'test';

  @override
  String? get email => 'me@x.com';
}

void main() {
  /// The whole app with [user] signed in and no profile yet.
  Future<void> pumpApp(WidgetTester tester, User user) async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceRegionProvider.overrideWithValue('GB'),
          deviceLanguageProvider.overrideWithValue('en'),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          accountControllerProvider.overrideWith(_FakeAccountController.new),
          entitlementProvider.overrideWith((ref) => Stream.value(null)),
          realEntitlementProvider.overrideWith((ref) => Stream.value(null)),
          billingServiceProvider.overrideWithValue(FakeBillingService()),
          activityScaleMigrationProvider.overrideWith((ref) async {}),
          adaptiveMondayProvider.overrideWith((ref) async {}),
          reminderSyncProvider.overrideWith((ref) async {}),
        ],
        child: const LeanStreakApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Sign-up is signed in while it sends the confirmation link, which showed
  // onboarding for a moment (12 November 2026).
  testWidgets('a password account with its email not verified stays on '
      'sign-in', (tester) async {
    await pumpApp(tester, _User('password', emailVerified: false));

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  for (final (provider, verified) in [
    ('password', true),
    ('google.com', true),
    ('google.com', false),
  ]) {
    testWidgets('a $provider account, verified $verified, goes on to '
        'onboarding', (tester) async {
      await pumpApp(tester, _User(provider, emailVerified: verified));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });
  }
}
