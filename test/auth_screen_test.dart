import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/screens/auth/auth_screen.dart';

class _FakeAuthController extends AuthController {
  final resets = <String>[];
  final resends = <(String, String)>[];
  int googleSignIns = 0;

  /// What sending the link again fails with, if anything.
  Object? resendError;

  /// Every email sign-in finds the email not yet verified.
  @override
  Future<bool> signIn(String email, String password) async {
    state = AsyncError(const EmailNotVerifiedException(), StackTrace.empty);
    return false;
  }

  @override
  Future<void> resendVerification(String email, String password) async {
    resends.add((email, password));
    state = resendError == null
        ? const AsyncData(AuthStatus.verificationSent)
        : AsyncError(resendError!, StackTrace.empty);
  }

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
  testWidgets('The password eye says what it does in its current state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuthController()),
          languageCodeProvider.overrideWithValue('en'),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsNothing);
  });

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

  group('signing in before verifying the email', () {
    /// The sign-in page after signing in with an email not yet verified.
    Future<void> pumpUnverified(
      WidgetTester tester,
      _FakeAuthController controller,
    ) async {
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
      await tester.enterText(find.byType(TextFormField).at(0), 'me@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(
        find.text('Verify your email first. Check your inbox for the link.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Send the link again'));
    }

    testWidgets('can send the link again, and says it went', (tester) async {
      final controller = _FakeAuthController();
      await pumpUnverified(tester, controller);

      await tester.tap(find.text('Send the link again'));
      await tester.pumpAndSettle();

      expect(controller.resends, [('me@x.com', 'secret1')]);
      expect(find.text('Verification email sent'), findsOneWidget);
      expect(
        find.text(
          'We sent a link to me@x.com. Open it to verify your account, then '
          'sign in. Not in your inbox? Check your junk or spam folder.',
        ),
        findsOneWidget,
      );
      expect(find.text('Send the link again'), findsNothing);
    });

    testWidgets('a wrong password says so, as signing in does', (tester) async {
      final controller = _FakeAuthController()
        ..resendError = FirebaseAuthException(code: 'invalid-credential');
      await pumpUnverified(tester, controller);

      await tester.tap(find.text('Send the link again'));
      await tester.pumpAndSettle();

      expect(controller.resends, hasLength(1));
      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.text('Verification email sent'), findsNothing);
      expect(find.text('Send the link again'), findsNothing);
    });
  });
}
