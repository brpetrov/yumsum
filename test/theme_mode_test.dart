import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/app.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/activity_scale_migration_provider.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_fixtures.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> pumpApp(WidgetTester tester, {String? storedMode}) async {
    SharedPreferences.setMockInitialValues({'theme_mode': ?storedMode});
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('test'),
          entitlementProvider.overrideWith((ref) => Stream.value(null)),
          realEntitlementProvider.overrideWith((ref) => Stream.value(null)),
          billingServiceProvider.overrideWithValue(FakeBillingService()),
          activityScaleMigrationProvider.overrideWith((ref) async {}),
          adaptiveMondayProvider.overrideWith((ref) async {}),
          reminderSyncProvider.overrideWith((ref) async {}),
          goRouterProvider.overrideWithValue(
            GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) =>
                      const AppFrame(title: 'Today', body: SizedBox.expand()),
                ),
              ],
            ),
          ),
        ],
        child: const LeanStreakApp(),
      ),
    );
    await tester.pump();
  }

  Color scaffoldColor(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;

  tearDown(() => AppColors.isDark = false);

  testWidgets('a stored choice of dark is applied from the first frame', (
    tester,
  ) async {
    await pumpApp(tester, storedMode: 'dark');

    expect(scaffoldColor(tester), AppPalette.dark.background);
    // Both halves of the system agree: the Material theme and the getters.
    final context = tester.element(find.byType(AppFrame));
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      AppPalette.dark.background,
    );
  });

  testWidgets('System follows the phone, live', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);

    expect(scaffoldColor(tester), AppPalette.dark.background);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    expect(scaffoldColor(tester), AppPalette.light.background);
  });

  testWidgets('choosing Dark in the menu switches and is remembered', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(scaffoldColor(tester), AppPalette.light.background);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    // The menu scrolls when the window is short.
    await tester.scrollUntilVisible(
      find.text('Dark'),
      100,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    // Its last step lands without a frame.
    await tester.pump();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(scaffoldColor(tester), AppPalette.dark.background);
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
