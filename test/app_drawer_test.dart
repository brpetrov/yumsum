import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GoRouter router;

  Future<void> pumpAt(WidgetTester tester, String location) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        for (final route in [
          AppRoutes.dashboard,
          AppRoutes.review,
          AppRoutes.progress,
          AppRoutes.planSettings,
          AppRoutes.notifications,
          AppRoutes.profile,
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
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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

  testWidgets('from Today the menu opens a page above it', (tester) async {
    await pumpAt(tester, AppRoutes.dashboard);
    await pick(tester, 'History');
    expect(location(), AppRoutes.review);
    expect(router.canPop(), isTrue);
  });

  testWidgets('from a page the menu swaps pages, so Back lands on Today', (
    tester,
  ) async {
    await pumpAt(tester, AppRoutes.review);
    await pick(tester, 'Weight & Progress');
    expect(location(), AppRoutes.progress);
    router.pop();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.dashboard);
  });

  testWidgets('Today in the menu goes straight home', (tester) async {
    await pumpAt(tester, AppRoutes.review);
    await pick(tester, 'Today');
    expect(location(), AppRoutes.dashboard);
    expect(router.canPop(), isFalse);
  });
}
