import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// reCAPTCHA Enterprise (Fraud Defense) site key for the web app, a public
/// value; classic reCAPTCHA v3 no longer accepts new App Check
/// registrations. App Check is skipped on the web while this is empty.
const recaptchaSiteKey = '6LffhvUtAAAAANG3hWgQg2FP8EF3vDy0PU1k5XsL';

bool get appCheckAvailable => !kIsWeb || recaptchaSiteKey.isNotEmpty;

/// A release build installed from the PC rather than from Google Play, which
/// Play Integrity refuses: built with `--dart-define=APP_CHECK_DEBUG=true`,
/// it uses a debug token on Android too.
const _debugTokenOnAndroid = bool.fromEnvironment('APP_CHECK_DEBUG');

/// Debug builds prove themselves with a debug token registered in the
/// Firebase console (printed in the log on first run); release builds use
/// the platform attestation.
Future<void> activateAppCheck() async {
  if (!appCheckAvailable) return;
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode || _debugTokenOnAndroid
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    webProvider: kIsWeb ? ReCaptchaEnterpriseProvider(recaptchaSiteKey) : null,
  );
}
