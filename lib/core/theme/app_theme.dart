import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Bundled in assets/fonts. Component styles that replace the text style
/// rather than merge into it (app bar, buttons, snack bar) name it too.
const _font = 'Nunito';

/// Rounded and soft to match the smiling-bowl icon: pill buttons and chips,
/// big card and sheet corners, and Nunito's rounded letters.
class AppTheme {
  AppTheme._();

  static const cardRadius = 22.0;
  static const inputRadius = 18.0;

  static final ThemeData light = _build(AppPalette.light, Brightness.light);
  static final ThemeData dark = _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        primaryContainer: p.primaryContainer,
        onPrimaryContainer: p.onPrimaryContainer,
        secondary: p.textSecondary,
        secondaryContainer: p.primaryContainer,
        onSecondaryContainer: p.onPrimaryContainer,
        surface: p.surface,
        onSurface: p.textPrimary,
        onSurfaceVariant: p.textSecondary,
        // Material 3 paints dialogs, menus and sheets with these roles; keep
        // them on the palette instead of seed-tinted greys.
        surfaceContainerLowest: p.surface,
        surfaceContainerLow: p.surface,
        surfaceContainer: p.surface,
        surfaceContainerHigh: p.surface,
        surfaceContainerHighest: p.surfaceVariant,
        outline: p.outline,
        outlineVariant: p.divider,
        error: p.error,
      ),
      scaffoldBackgroundColor: p.background,
      fontFamily: _font,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          color: p.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(cardRadius)),
          side: BorderSide(color: p.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        // Dialogs otherwise grow to their longest line on wide browsers.
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 480),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        constraints: const BoxConstraints(maxWidth: 640),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceVariant,
          disabledForegroundColor: p.textDisabled,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceVariant,
          disabledForegroundColor: p.textDisabled,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          side: BorderSide(color: p.primary, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textDisabled),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceVariant,
      ),
      // Merged so every style, listed or not, keeps the font.
      textTheme: base.textTheme.merge(
        TextTheme(
          displayLarge: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
          displayMedium: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          headlineSmall: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            color: p.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: p.textPrimary),
          bodyMedium: TextStyle(color: p.textPrimary),
          bodySmall: TextStyle(color: p.textSecondary),
          labelLarge: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: TextStyle(color: p.textSecondary, letterSpacing: 0.5),
        ),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide.none,
        shape: StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: p.textPrimary,
        contentTextStyle: TextStyle(fontFamily: _font, color: p.background),
      ),
    );
  }
}
