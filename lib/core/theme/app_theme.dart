import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../../widgets/icon_bubble.dart';

/// Bundled in assets/fonts. Component styles that replace the text style
/// rather than merge into it (app bar, buttons, snack bar) name it too.
const _font = 'Nunito';

/// Rounded, bubbly and warm to match the smiling-bowl icon: pill buttons,
/// chips and toggles, big soft corners, warm shadows instead of borders,
/// Nunito for reading and Fredoka's round letters for headings and numbers.
class AppTheme {
  AppTheme._();

  static const cardRadius = 28.0;
  static const inputRadius = 20.0;
  static const sheetRadius = 32.0;

  /// Fredoka, for titles, headings and the big numbers. It has no Cyrillic,
  /// so Nunito fills in for any Bulgarian, such as a product's name.
  static const display = TextStyle(
    fontFamily: 'Fredoka',
    fontFamilyFallback: [_font],
    fontWeight: FontWeight.w600,
  );

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
    final buttonLabel = display.copyWith(fontSize: 17, letterSpacing: 0.2);
    // Filled buttons glow softly in their own orange, like the icon's tile.
    final glow = p.primary.withValues(
      alpha: brightness == Brightness.light ? 0.5 : 0.35,
    );
    WidgetStateProperty<T> selected<T>(T on, T off) =>
        WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? on : off,
        );
    OutlineInputBorder inputBorder([BorderSide side = BorderSide.none]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: side,
        );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleTextStyle: display.copyWith(color: p.textPrimary, fontSize: 22),
      ),
      // The menu button floats in a bubble, like the app bar's actions.
      actionIconTheme: ActionIconThemeData(
        drawerButtonIconBuilder: (context) =>
            const IconBubble(Icons.menu_rounded, raised: true),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(sheetRadius)),
        ),
        titleTextStyle: display.copyWith(color: p.textPrimary, fontSize: 24),
        // Dialogs otherwise grow to their longest line on wide browsers.
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 480),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 640),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceVariant,
          disabledForegroundColor: p.textDisabled,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: buttonLabel,
          elevation: 4,
          shadowColor: glow,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceVariant,
          disabledForegroundColor: p.textDisabled,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: buttonLabel.copyWith(fontSize: 16),
          elevation: 3,
          shadowColor: glow,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          side: BorderSide(color: p.primary, width: 2),
          textStyle: buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: const StadiumBorder(),
          textStyle: buttonLabel.copyWith(fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: inputBorder(),
        enabledBorder: inputBorder(),
        focusedBorder: inputBorder(BorderSide(color: p.primary, width: 2)),
        errorBorder: inputBorder(BorderSide(color: p.error, width: 1.5)),
        focusedErrorBorder: inputBorder(BorderSide(color: p.error, width: 2)),
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textDisabled),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(sheetRadius),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceVariant,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: selected(p.primary, p.outline),
        thumbColor: selected(
          p.onPrimary,
          brightness == Brightness.light ? Colors.white : p.textSecondary,
        ),
      ),
      // Merged so every style, listed or not, keeps the font.
      textTheme: base.textTheme.merge(
        TextTheme(
          displayLarge: display.copyWith(color: p.textPrimary),
          displayMedium: display.copyWith(color: p.textPrimary),
          displaySmall: display.copyWith(color: p.textPrimary),
          headlineLarge: display.copyWith(color: p.textPrimary),
          headlineMedium: display.copyWith(color: p.textPrimary),
          headlineSmall: display.copyWith(color: p.textPrimary),
          titleLarge: display.copyWith(color: p.textPrimary),
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
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        labelStyle: TextStyle(
          fontFamily: _font,
          color: p.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: p.textPrimary,
        contentTextStyle: TextStyle(fontFamily: _font, color: p.background),
      ),
    );
  }
}
