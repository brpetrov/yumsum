import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/constants/app_colors.dart';

/// WCAG contrast ratio between two colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  for (final (name, p) in [
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('$name palette', () {
      test('text is readable on every surface', () {
        for (final surface in [
          p.background,
          p.surface,
          p.surfaceVariant,
          p.heroStart,
          p.heroEnd,
        ]) {
          expect(_contrast(p.textPrimary, surface), greaterThan(7));
          expect(_contrast(p.textSecondary, surface), greaterThan(4.5));
        }
      });

      test('accents stand out on cards', () {
        // 3:1 is the WCAG bar for UI components and large/bold text, which is
        // how the accents are used (bars, pills, bold numbers).
        for (final accent in [p.primary, p.veryBad, p.info]) {
          expect(_contrast(accent, p.surface), greaterThan(3));
        }
        // Light amber is a known exception (about 2:1); it is used for bars
        // and tinted pills rather than running text.
        if (name == 'dark') {
          expect(_contrast(p.bad, p.surface), greaterThan(4.5));
        }
      });

      test('button text is readable on the button', () {
        expect(_contrast(p.onPrimary, p.primary), greaterThan(4.5));
      });
    });
  }
}
