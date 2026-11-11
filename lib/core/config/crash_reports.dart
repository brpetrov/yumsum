import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

// Crash reports go to Firebase Crashlytics from the Android and iOS apps;
// there is none on the web. Uncaught errors are fatal reports (main.dart);
// the errors a screen shows as a message are non-fatal ones, so a tester's
// "it said it couldn't save" can be found, and so are failures the app
// gets past quietly (our own emails, a saved coach note). Each carries the
// account's ID, which a user's feedback carries too. Nothing the user
// logged is sent.

/// Turns reports off in debug builds, so the owner's runs don't mix in, and
/// tags them with the signed-in account's ID (a random code).
Future<void> setUpCrashReports() async {
  if (kIsWeb) return;
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FirebaseAuth.instance.authStateChanges().listen(
    (user) => crashlytics.setUserIdentifier(user?.uid ?? ''),
  );
}

/// Reports [error], which the user was shown as a message or which was
/// handled quietly, as non-fatal, unless it's the user's or the network's
/// ([expectedError]).
void reportError(Object error, StackTrace? stack, String reason) {
  debugPrint('$reason: $error');
  if (!_canReport || expectedError(error)) return;
  reportFault(error, stack, reason);
}

/// None on the web, and none before Firebase is up (or in tests).
bool get _canReport => !kIsWeb && Firebase.apps.isNotEmpty;

/// Reports [error] as non-fatal whatever it is: for a path where an error
/// that's usually the user's is the app's (Google sign-in).
void reportFault(Object error, StackTrace? stack, String reason) {
  if (!_canReport) return;
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: reason,
    fatal: false,
  );
}

/// Firebase sign-in errors that are the user's or the network's: a wrong,
/// unknown or taken address or password, too many tries, a disabled
/// account, a sign-in too old for a change, a used link, a closed popup.
/// Any other (an internal error, a sign-in method not allowed, the app not
/// authorised) is the app's set-up and is reported.
const _usersAuthCodes = {
  'invalid-credential',
  'invalid-login-credentials',
  'wrong-password',
  'user-not-found',
  'invalid-email',
  'missing-email',
  'missing-password',
  'email-already-in-use',
  'weak-password',
  'user-disabled',
  'too-many-requests',
  'requires-recent-login',
  'user-mismatch',
  'user-token-expired',
  'network-request-failed',
  'expired-action-code',
  'invalid-action-code',
  'credential-already-in-use',
  'account-exists-with-different-credential',
  'popup-closed-by-user',
  'cancelled-popup-request',
  'popup-blocked',
};

/// Errors that are the user's or the network's, not the app's: a wrong
/// password, backing out of Google, a used-up allowance or month of
/// changes, the AI's own messages, no connection, or the server refusing a
/// listener after signing out.
bool expectedError(Object error) => switch (error) {
  FirebaseAuthException(:final code) => _usersAuthCodes.contains(code),
  _ when backedOutOfGoogle(error) => true,
  EmailNotVerifiedException() ||
  AccountActionException() ||
  EditLimitExceededException() ||
  DailyLimitExceededException() ||
  CalorieEstimateException() => true,
  FirebaseFunctionsException(code: 'resource-exhausted' || 'unavailable') =>
    true,
  FirebaseException(code: 'unavailable' || 'network-request-failed') => true,
  FirebaseException(code: 'permission-denied')
      when FirebaseAuth.instance.currentUser == null =>
    true,
  _ => false,
};

/// Reports a provider turning to an error, such as a controller's failed
/// save, once per error.
class CrashReportObserver extends ProviderObserver {
  CrashReportObserver({this.report = reportError});

  /// Where reports go: [reportError], or a test's list.
  final void Function(Object error, StackTrace? stack, String reason) report;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (newValue is! AsyncError) return;
    if (previousValue is AsyncError && previousValue.error == newValue.error) {
      return;
    }
    report(
      newValue.error,
      newValue.stackTrace,
      provider.name ?? provider.runtimeType.toString(),
    );
  }
}
