import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lean_streak/app/app.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/core/config/app_check.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/firebase_options.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('LeanStreak FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString());
  };

  ErrorWidget.builder = (details) {
    return _StartupErrorApp(message: details.exceptionAsString());
  };

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
    try {
      await activateAppCheck();
    } catch (error) {
      // Without a token the AI call fails with a clear message; the rest of
      // the app does not depend on App Check.
      debugPrint('App Check setup failed: $error');
    }
  } catch (error, stackTrace) {
    debugPrint('LeanStreak startup failed: $error');
    debugPrint(stackTrace.toString());
    AppColors.isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    runApp(_StartupErrorApp(message: error.toString()));
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

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
                      'LeanStreak could not start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please refresh the page. If it keeps happening, send this message back to the developer.',
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
