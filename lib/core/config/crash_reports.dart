import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
// "it said it couldn't save" can be found. Nothing the user logged is sent.

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

/// Reports [error], which the user was shown as a message, as non-fatal.
void reportError(Object error, StackTrace? stack, String reason) {
  debugPrint('$reason: $error');
  if (kIsWeb || expectedError(error)) return;
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: reason,
    fatal: false,
  );
}

/// Errors that are the user's or the network's, not the app's: a wrong
/// password, a used-up allowance or month of changes, the AI's own
/// messages, no connection, or the server refusing a listener after
/// signing out.
bool expectedError(Object error) => switch (error) {
  FirebaseAuthException() ||
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
