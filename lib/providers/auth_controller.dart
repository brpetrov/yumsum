import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:lean_streak/core/config/crash_reports.dart';

import 'package:lean_streak/providers/language_provider.dart';

enum AuthStatus { idle, verificationSent, resetSent }

/// Thrown when a user tries to sign in before verifying their email.
class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException();
}

Future<void>? _googleReady;

/// Google sign-in's errors from Firebase that are the user's or the
/// network's.
const _googleUsersCodes = {
  'network-request-failed',
  'too-many-requests',
  'user-disabled',
};

/// The phone's Google sign-in, set up on first use: the plugin may only be
/// initialised once, and signing in again or confirming a deletion uses it
/// too.
Future<GoogleSignIn> googleSignIn() async {
  await (_googleReady ??= GoogleSignIn.instance.initialize());
  return GoogleSignIn.instance;
}

/// Whether [error] is the user closing Google's account picker or popup,
/// which isn't shown as an error.
bool backedOutOfGoogle(Object? error) => switch (error) {
  GoogleSignInException(code: GoogleSignInExceptionCode.canceled) => true,
  FirebaseAuthException(
    code: 'popup-closed-by-user' || 'cancelled-popup-request',
  ) =>
    true,
  _ => false,
};

class AuthController extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async => AuthStatus.idle;

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (!(credential.user?.emailVerified ?? false)) {
        await FirebaseAuth.instance.signOut();
        throw const EmailNotVerifiedException();
      }
      return AuthStatus.idle;
    });
    state = nextState;
    return !nextState.hasError;
  }

  /// Google sign-in: Firebase's own popup on the web, the account picker on
  /// phones. Google accounts arrive verified, so there is no email check.
  /// Returns false when the user backs out, which is not shown as an error.
  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() async {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final account = await (await googleSignIn()).authenticate();
        await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
            idToken: account.authentication.idToken,
          ),
        );
      }
      return AuthStatus.idle;
    });
    if (backedOutOfGoogle(next.error)) {
      state = const AsyncData(AuthStatus.idle);
      return false;
    }
    // Firebase's sign-in errors are usually the user's (expectedError), but
    // here nearly all are the app's set-up, such as no Google client for
    // the key a build is signed with (the Play build, 10 November 2026).
    if (next.error case final FirebaseAuthException error
        when expectedError(error) && !_googleUsersCodes.contains(error.code)) {
      reportFault(error, next.stackTrace, 'Google sign-in');
    }
    state = next;
    return !next.hasError;
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await _sendVerification(credential.user);
      await FirebaseAuth.instance.signOut();
      return AuthStatus.verificationSent;
    });
  }

  /// Sends the confirmation link again, for an account whose sign-in failed
  /// with [EmailNotVerifiedException]: signs in to send it, then signs out.
  /// An account verified since just stays signed in.
  Future<void> resendVerification(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user?.emailVerified ?? false) return AuthStatus.idle;
      try {
        await _sendVerification(credential.user);
      } finally {
        await FirebaseAuth.instance.signOut();
      }
      return AuthStatus.verificationSent;
    });
  }

  /// Firebase's confirmation email, in the app's language. Ours, styled and
  /// sent through help.yumsum's Gmail (functions/src/email.ts), is not used:
  /// Outlook held it for an hour and junked it (12 November 2026), as a new
  /// free Gmail address sending HTML looks like phishing, where Firebase's
  /// servers are trusted.
  Future<void> _sendVerification(User? user) async {
    if (user == null) return;
    await _inAppLanguage(ref);
    await user.sendEmailVerification();
  }

  /// Emails a link to choose a new password: ours, else Firebase's. An
  /// unknown address gets the same answer as a known one, so the form can't
  /// be used to probe emails.
  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await sendResetEmail(ref, email.trim());
      return AuthStatus.resetSent;
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      // Forget the Google session too, so the next sign-in shows the picker.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    state = const AsyncData(AuthStatus.idle);
  }
}

/// Firebase's emails, and the pages their links open, come in the app's
/// language.
Future<void> _inAppLanguage(Ref ref) =>
    FirebaseAuth.instance.setLanguageCode(ref.read(languageCodeProvider));

/// Firebase's password reset email to [email], in the app's language (not
/// ours: see `_sendVerification`). It says nothing of an unknown address,
/// so the form can't be used to probe emails.
Future<void> sendResetEmail(Ref ref, String email) async {
  await _inAppLanguage(ref);
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  } on FirebaseAuthException catch (error) {
    if (error.code != 'user-not-found') rethrow;
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthStatus>(AuthController.new);
