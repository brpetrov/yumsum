import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/activity_scale_migration_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/providers/theme_controller.dart';

class LeanStreakApp extends ConsumerWidget {
  const LeanStreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityScaleMigrationProvider);
    ref.watch(reminderSyncProvider);
    final router = ref.watch(goRouterProvider);
    final mode = ref.watch(themeControllerProvider);
    // The AppColors getters must agree with the Material theme, so the flag
    // is set here, before any route builds.
    AppColors.isDark =
        ref.watch(effectiveBrightnessProvider) == Brightness.dark;
    // Most of the tree is built with `const`, which a normal rebuild skips,
    // so a switch marks every element dirty (state is kept, as on hot reload).
    // This listener runs mid-build, so the reassemble waits for the frame.
    ref.listen(effectiveBrightnessProvider, (_, next) {
      AppColors.isDark = next == Brightness.dark;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => WidgetsBinding.instance.reassembleApplication(),
      );
    });
    return MaterialApp.router(
      title: 'YumSum',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      // Lerping the theme while the getters have already flipped would show
      // a frame of mismatched colours.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: appShellBuilder,
    );
  }
}

/// Widest the app gets. Wider browser windows show it as one centred column,
/// so the app bar, pages, dialogs and the bottom bar all line up.
const double appMaxWidth = 760;

Widget appShellBuilder(BuildContext context, Widget? child) {
  // A tap on nothing in particular lets go of whichever box has the
  // keyboard, which also folds the quick-log bar away.
  final page = GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: child,
  );
  final mediaQuery = MediaQuery.of(context);
  if (mediaQuery.size.width <= appMaxWidth) return page;

  final theme = Theme.of(context);
  // A slightly deeper margin with a hairline edge makes the column read as a
  // page, so dialogs dimming only the column look intentional.
  return ColoredBox(
    color: AppColors.surfaceVariant,
    child: Center(
      child: Container(
        width: appMaxWidth,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.symmetric(
            vertical: BorderSide(color: AppColors.divider),
          ),
        ),
        child: MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(
              math.min(mediaQuery.size.width, appMaxWidth),
              mediaQuery.size.height,
            ),
          ),
          child: Theme(
            // Keep floating snackbars phone-sized inside the column.
            data: theme.copyWith(
              snackBarTheme: theme.snackBarTheme.copyWith(width: 480),
            ),
            child: page,
          ),
        ),
      ),
    ),
  );
}
