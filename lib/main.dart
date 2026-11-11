import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lean_streak/app/app.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/core/config/app_check.dart';
import 'package:lean_streak/core/config/crash_reports.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/firebase_options.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/theme_controller.dart';
import 'package:lean_streak/widgets/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Logs carry food names, AI replies and token counts; keep them out of
  // release builds' logcat and browser console.
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('LeanStreak FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString());
  };

  // English until the stored language is read, below.
  var language = 'en';
  ErrorWidget.builder = (details) {
    return _StartupErrorApp(
      message: details.exceptionAsString(),
      language: language,
    );
  };

  // Nunito and Fredoka are bundled under the SIL Open Font License, which
  // travels with them.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], license);
    final fredoka = await rootBundle.loadString('assets/fonts/OFL-Fredoka.txt');
    yield LicenseEntryWithLineBreaks(['Fredoka'], fredoka);
  });

  final prefs = await SharedPreferences.getInstance();
  language = LanguageController.storedIn(prefs) ?? 'en';
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    observers: [if (!kIsWeb) CrashReportObserver()],
  );
  // The phone's launch screen stays up until the first frame, so draw the
  // splash now; the app replaces it once Firebase is ready.
  AppColors.isDark =
      container.read(effectiveBrightnessProvider) == Brightness.dark;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppColors.isDark ? AppTheme.dark : AppTheme.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(),
    ),
  );
  // Taps on a notification (later: shortcut, widget) only need the container,
  // so wire them before Firebase; a tap that started the app must not be lost.
  final launchActionsReady = bindLaunchActions(container);

  try {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') {
        rethrow;
      }
    }
    // On the web it starts later, off the start-up path (ensureAppCheck).
    // On phones before the other Firebase products are used; a failure is
    // reported once crash reports are set up, below.
    (Object, StackTrace)? appCheckFailure;
    if (!kIsWeb) {
      try {
        await activateAppCheck();
      } catch (error, stack) {
        // Without a token the AI call fails with a clear message; the rest
        // of the app does not depend on App Check.
        appCheckFailure = (error, stack);
      }
    }
    if (!kIsWeb) {
      // Crashlytics has no web build; the debugPrint handler above stays
      // there. Uncaught errors become crash reports (device, OS, app
      // version and the trace; nothing the user logged).
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await setUpCrashReports();
      if (appCheckFailure case (final error, final stack)) {
        reportError(error, stack, 'App Check set-up');
      }
    }
  } catch (error, stackTrace) {
    debugPrint('LeanStreak startup failed: $error');
    debugPrint(stackTrace.toString());
    // Once Firebase is up (reportFault checks).
    reportFault(error, stackTrace, 'Start-up');
    AppColors.isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    runApp(_StartupErrorApp(message: error.toString(), language: language));
    return;
  }

  try {
    await launchActionsReady;
  } catch (error) {
    debugPrint('Launch action setup failed: $error');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LeanStreakApp(),
    ),
  );
}

/// Shown when the app can't start, before Riverpod and the app's
/// localisations: [language] is the stored setting, read in main().
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message, required this.language});

  final String message;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppLocalizations(Locale(language));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.startupErrorTitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.display.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.startupErrorBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
