import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/account/account_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAccountController extends AccountController {
  final resetPasswords = <String>[];
  final deletePasswords = <String>[];

  @override
  Future<void> deleteAccount({required String password}) async {
    deletePasswords.add(password);
  }

  @override
  Future<void> syncAuthEmailToProfile() async {}

  @override
  Future<void> resetAllData({required String password}) async {
    resetPasswords.add(password);
  }
}

class _GoogleLogin extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';
}

/// Signed up with Google, so there's no password.
class _GoogleUser extends Fake implements User {
  @override
  String? get email => 'a@b.com';

  @override
  List<UserInfo> get providerData => [_GoogleLogin()];
}

final _now = DateTime(2026, 10, 16);
final _profile = UserProfile(
  uid: 'test',
  email: 'a@b.com',
  name: 'Test',
  age: 30,
  gender: Gender.male,
  heightCm: 180,
  currentWeightKg: 86,
  targetWeightKg: 75,
  activityLevel: ActivityLevel.lightlyActive,
  trainingFrequency: TrainingFrequency.oneToTwo,
  activityScaleVersion: currentActivityScaleVersion,
  planCalculationVersion: currentPlanCalculationVersion,
  weightLossPace: WeightLossPace.moderate,
  targetDate: _now.add(const Duration(days: 150)),
  bmi: 26.5,
  bmr: 1800,
  tdee: 2400,
  dailyCalorieTarget: 1900,
  goalPaceKgPerWeek: 0.5,
  goalPaceLevel: GoalPaceLevel.values.first,
  onboardingCompleted: true,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  late SharedPreferences prefs;
  late _FakeAccountController controller;

  Future<void> pumpScreen(WidgetTester tester, {User? user}) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    controller = _FakeAccountController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('test'),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(_profile),
          ),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
          accountControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AccountSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Account Settings links to feedback and the legal pages', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.ensureVisible(find.text('Terms of use'));
    expect(find.text('Send feedback'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
  });

  testWidgets('Reset all data asks for the password, then resets', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('Reset all data'));
    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
    expect(find.text('Reset all data?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'hunter2');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset all data'));
    await tester.pumpAndSettle();

    expect(controller.resetPasswords, ['hunter2']);
    expect(find.text('All logged data deleted.'), findsOneWidget);
  });

  testWidgets('A Google account confirms with Google, not a password', (
    tester,
  ) async {
    await pumpScreen(tester, user: _GoogleUser());
    expect(find.text('Change email'), findsNothing);
    expect(find.text('Send password reset email'), findsNothing);

    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('confirm with Google next'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(controller.deletePasswords, ['']);
  });
}
