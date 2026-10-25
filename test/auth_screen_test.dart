import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/screens/auth/auth_screen.dart';

class _FakeAuthController extends AuthController {
  final resets = <String>[];
  int googleSignIns = 0;

  @override
  Future<bool> signInWithGoogle() async {
    googleSignIns++;
    return true;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resets.add(email);
    state = const AsyncData(AuthStatus.resetSent);
  }
}

void main() {
  testWidgets('Forgot password needs an email, then sends the reset link', (
    tester,
  ) async {
    final controller = _FakeAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    expect(find.textContaining('Enter your email above first'), findsOneWidget);
    expect(controller.resets, isEmpty);

    await tester.enterText(find.byType(TextFormField).first, 'me@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(controller.resets, ['me@example.com']);
    expect(find.text('Password reset email sent.'), findsOneWidget);
  });

  testWidgets('the sign-in screen links to the terms and privacy policy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Terms of Use', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Privacy Policy', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Continue with Google starts the Google flow', (tester) async {
    final controller = _FakeAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(controller.googleSignIns, 1);
  });

  testWidgets('the link is only offered when signing in', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsNothing);
  });
}
