import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/widgets/splash_screen.dart';

void main() {
  testWidgets('after 15 seconds the splash says it is taking a while', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );
    const slow = 'Taking longer than usual. Check your connection.';
    expect(find.text(slow), findsNothing);

    await tester.pump(const Duration(seconds: 14));
    expect(find.text(slow), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text(slow), findsOneWidget);
    // Reload is for the website only.
    expect(find.text('Reload'), findsNothing);
  });
}
