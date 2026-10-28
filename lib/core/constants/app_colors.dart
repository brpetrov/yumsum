import 'package:flutter/material.dart';

/// One set of colours for a theme, taken from the app icon. Light is cream
/// from the bowl with the tile's orange as the accent; dark is the same idea
/// in warm charcoal, never pure black, with the hues lifted so they stay
/// readable on dark surfaces. Green (the icon's arc) means on track, the yolk
/// amber close, and a crimson, kept well apart from the orange, off track.
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.veryGood,
    required this.bad,
    required this.veryBad,
    required this.divider,
    required this.error,
    required this.shadow,
    required this.info,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color veryGood;
  final Color bad;
  final Color veryBad;
  final Color divider;
  final Color error;
  final Color shadow;
  final Color info;

  static const light = AppPalette(
    primary: Color(0xFFC94D1A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFCE5D3),
    onPrimaryContainer: Color(0xFF9A3B12),
    background: Color(0xFFFAF2E7),
    surface: Color(0xFFFFFBF5),
    surfaceVariant: Color(0xFFF5EADB),
    outline: Color(0xFFDDCBB5),
    textPrimary: Color(0xFF2B1F18),
    textSecondary: Color(0xFF76665A),
    textDisabled: Color(0xFFB4A595),
    veryGood: Color(0xFF1E9C74),
    bad: Color(0xFFE8A10F),
    veryBad: Color(0xFFC8284A),
    divider: Color(0xFFEFE3D2),
    error: Color(0xFFC8284A),
    shadow: Color(0x148C5A3C),
    info: Color(0xFF3B82F6),
  );

  static const dark = AppPalette(
    primary: Color(0xFFF58A5A),
    onPrimary: Color(0xFF2B1206),
    primaryContainer: Color(0xFF4A2616),
    onPrimaryContainer: Color(0xFFFFC7A8),
    background: Color(0xFF1A1512),
    surface: Color(0xFF241D19),
    surfaceVariant: Color(0xFF2F2621),
    outline: Color(0xFF4F433A),
    textPrimary: Color(0xFFF6EDE3),
    textSecondary: Color(0xFFBCAD9F),
    textDisabled: Color(0xFF7D7065),
    veryGood: Color(0xFF4FD1A5),
    bad: Color(0xFFF6C04A),
    veryBad: Color(0xFFF2647E),
    divider: Color(0xFF382E28),
    error: Color(0xFFF2647E),
    shadow: Color(0x66000000),
    info: Color(0xFF6FA6F8),
  );
}

/// The app's colour tokens. They read from the palette for the current
/// brightness, which `LeanStreakApp` sets before anything builds.
class AppColors {
  AppColors._();

  static bool isDark = false;

  static AppPalette get palette => isDark ? AppPalette.dark : AppPalette.light;

  static Color get primary => palette.primary;
  static Color get onPrimary => palette.onPrimary;
  static Color get primaryContainer => palette.primaryContainer;
  static Color get onPrimaryContainer => palette.onPrimaryContainer;

  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get surfaceVariant => palette.surfaceVariant;
  static Color get outline => palette.outline;

  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get textDisabled => palette.textDisabled;

  static Color get veryGood => palette.veryGood;
  static Color get bad => palette.bad;
  static Color get veryBad => palette.veryBad;

  static Color get divider => palette.divider;
  static Color get error => palette.error;
  static Color get shadow => palette.shadow;
  static Color get info => palette.info;
}
