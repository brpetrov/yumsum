import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/language_provider.dart';
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
  testWidgets('Forgot password asks for the email, then says a link went '
      'if an account uses it', (tester) async {
    final controller = _FakeAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => controller),
          languageCodeProvider.overrideWithValue('en'),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final dialogBox = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
    await tester.tap(find.text('Send link'));
    await tester.pump();
    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(controller.resets, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // It starts with what's in the sign-in box.
    await tester.enterText(find.byType(TextFormField).first, 'me@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(dialogBox).controller!.text,
      'me@example.com',
    );
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(controller.resets, ['me@example.com']);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('If an account uses me@example.com'), findsOne);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Check your email'), findsNothing);
  });

  testWidgets('the sign-in screen links to the terms and privacy policy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          languageCodeProvider.overrideWithValue('en'),
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
        overrides: [
          authControllerProvider.overrideWith(() => controller),
          languageCodeProvider.overrideWithValue('en'),
        ],
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
          languageCodeProvider.overrideWithValue('en'),
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
