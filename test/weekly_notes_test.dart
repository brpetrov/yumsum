import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/screens/review/weekly_notes.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

final _monday = DateTime(2026, 10, 26);

void main() {
  late GoRouter router;

  /// [child] on a History page pushed over Home; the AI Coach page says
  /// which week it was asked for.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Entitlement? entitlement = _plus,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/history',
          builder: (_, _) => Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [child],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.coach,
          builder: (_, state) => Scaffold(
            body: Text(
              'Coach ${state.uri.queryParameters['week'] ?? 'latest'}',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.push('/history');
    await tester.pumpAndSettle();
  }

  group('with YumSum Star', () {
    testWidgets('a finished week opens the AI Coach page on it, swapping '
        'History so Back lands on Home', (tester) async {
      await pump(tester, WeeklyNotesCard(monday: _monday));
      expect(find.text('AI Coach'), findsOneWidget);
      expect(find.text('Read your notes on this week.'), findsOneWidget);

      await tester.tap(find.text('AI Coach'));
      await tester.pumpAndSettle();
      expect(find.text('Coach 2026-10-26'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('a week before YumSum Star began gets no card', (tester) async {
      await pump(
        tester,
        WeeklyNotesCard(monday: _monday),
        entitlement: Entitlement(
          active: true,
          source: EntitlementSource.play,
          startedAt: DateTime(2026, 11, 4),
        ),
      );
      expect(find.text('AI Coach'), findsNothing);

      await pump(
        tester,
        WeeklyNotesCard(monday: DateTime(2026, 11, 2)),
        entitlement: Entitlement(
          active: true,
          source: EntitlementSource.play,
          startedAt: DateTime(2026, 11, 4),
        ),
      );
      expect(find.text('AI Coach'), findsOneWidget);
    });

    testWidgets('in the month view it says which week', (tester) async {
      await pump(tester, WeeklyNotesCard(monday: _monday, named: true));
      expect(find.text('Week of 26 October'), findsOneWidget);
      expect(find.text('Read your notes on that week.'), findsOneWidget);
    });

    testWidgets('a week still going says when its notes come, and opens '
        'the latest', (tester) async {
      final now = DateTime.now();
      final thisMonday = DateTime(
        now.year,
        now.month,
        now.day - now.weekday + 1,
      );
      await pump(tester, WeeklyNotesCard(monday: thisMonday));
      expect(
        find.text('Your notes on this week come on Monday.'),
        findsOneWidget,
      );

      await tester.tap(find.text('AI Coach'));
      await tester.pumpAndSettle();
      expect(find.text('Coach latest'), findsOneWidget);
    });
  });

  group('without YumSum Star', () {
    testWidgets('the AI Coach button opens the page', (tester) async {
      await pump(tester, WeeklyNotesCard(monday: _monday), entitlement: null);
      expect(
        find.text(
          'See what\'s working, what\'s holding you back, and get personal '
          'tips on how to improve.',
        ),
        findsOneWidget,
      );
      expect(find.byType(PlusStar), findsNothing);

      await tester.tap(find.text('AI Coach'));
      await tester.pumpAndSettle();
      expect(find.text('Coach latest'), findsOneWidget);
    });

    testWidgets('the line under it opens the page too', (tester) async {
      await pump(tester, WeeklyNotesCard(monday: _monday), entitlement: null);
      await tester.tap(find.textContaining('See what\'s working'));
      await tester.pumpAndSettle();
      expect(find.text('Coach latest'), findsOneWidget);
    });
  });
}
