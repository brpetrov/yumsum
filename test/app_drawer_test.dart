import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GoRouter router;

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Entitlement? entitlement,
    bool debugTools = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        for (final route in [
          AppRoutes.dashboard,
          AppRoutes.review,
          AppRoutes.recipes,
          AppRoutes.progress,
          AppRoutes.planSettings,
          AppRoutes.notifications,
          AppRoutes.profile,
          AppRoutes.plus,
        ])
          GoRoute(
            path: route,
            builder: (_, _) => Scaffold(
              appBar: AppBar(title: Text(route)),
              drawer: const AppDrawer(),
              body: const SizedBox.expand(),
            ),
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          debugToolsProvider.overrideWithValue(debugTools),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    if (location != AppRoutes.dashboard) {
      router.push(location);
      await tester.pumpAndSettle();
    }
  }

  Future<void> pick(WidgetTester tester, String entry) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  String location() => router.state.uri.path;

  testWidgets('from Home the menu opens a page above it', (tester) async {
    await pumpAt(tester, AppRoutes.dashboard);
    await pick(tester, 'History');
    expect(location(), AppRoutes.review);
    expect(router.canPop(), isTrue);
  });

  testWidgets('from a page the menu swaps pages, so Back lands on Home', (
    tester,
  ) async {
    await pumpAt(tester, AppRoutes.review);
    await pick(tester, 'Weight & Progress');
    expect(location(), AppRoutes.progress);
    router.pop();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.dashboard);
  });

  testWidgets('Debug tools are in the menu only where they are on offer', (
    tester,
  ) async {
    await pumpAt(tester, AppRoutes.dashboard);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Debug tools', skipOffstage: false), findsOneWidget);

    await pumpAt(tester, AppRoutes.dashboard, debugTools: false);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Debug tools', skipOffstage: false), findsNothing);
  });

  testWidgets('the menu lists Recipes', (tester) async {
    await pumpAt(tester, AppRoutes.dashboard);
    await pick(tester, 'Recipes');
    expect(location(), AppRoutes.recipes);
  });

  testWidgets('Home in the menu goes straight home', (tester) async {
    await pumpAt(tester, AppRoutes.review);
    await pick(tester, 'Home');
    expect(location(), AppRoutes.dashboard);
    expect(router.canPop(), isFalse);
  });

  testWidgets('YumSum Star opens over the current page', (tester) async {
    await pumpAt(tester, AppRoutes.review);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PlusMark));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PlusMark));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.plus);
    router.pop();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.review);
  });

  testWidgets('without YumSum Star, Become a Star beside the logo opens it', (
    tester,
  ) async {
    await pumpAt(tester, AppRoutes.review);
    await pick(tester, 'Become a Star');
    expect(location(), AppRoutes.plus);
    expect(find.byTooltip('YumSum Star'), findsNothing);
  });

  testWidgets('a member sees the star beside the logo instead', (tester) async {
    await pumpAt(
      tester,
      AppRoutes.review,
      entitlement: const Entitlement(
        active: true,
        source: EntitlementSource.manual,
      ),
    );
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Become a Star'), findsNothing);
    await tester.tap(find.byTooltip('YumSum Star'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.plus);
  });
}
