import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// reCAPTCHA v3 site key for the web app (a public value). Empty until the
/// web app is registered in Firebase App Check; App Check is skipped on the
/// web until then.
const recaptchaSiteKey = '6LfON_UtAAAAAACPilACMpqekwXtUm4PKbMLc9qk';

bool get appCheckAvailable => !kIsWeb || recaptchaSiteKey.isNotEmpty;

/// Debug builds prove themselves with a debug token registered in the
/// Firebase console (printed in the log on first run); release builds use
/// the platform attestation.
Future<void> activateAppCheck() async {
  if (!appCheckAvailable) return;
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    webProvider: kIsWeb ? ReCaptchaV3Provider(recaptchaSiteKey) : null,
  );
}
