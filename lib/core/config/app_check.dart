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

Future<void>? _webAppCheck;

/// Starts App Check on the web, once: before each Cloud Functions call and a
/// few seconds after Home shows, rather than at start-up. Firestore and Auth
/// don't enforce it but wait for its reCAPTCHA token once it runs, and
/// reCAPTCHA's script (850 KB) slowed every start (7 November). The phone
/// apps start it in main(), so this does nothing there.
Future<void> ensureAppCheck() {
  if (!kIsWeb) return Future.value();
  return _webAppCheck ??= activateAppCheck().catchError((Object error) {
    debugPrint('App Check setup failed: $error');
  });
}

/// Debug builds prove themselves with a debug token registered in the
/// Firebase console (printed in the log on first run); release builds use
/// the platform attestation.
Future<void> activateAppCheck() async {
  if (!appCheckAvailable) return;
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode || _debugTokenOnAndroid
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
    providerWeb: kIsWeb ? ReCaptchaEnterpriseProvider(recaptchaSiteKey) : null,
  );
}
