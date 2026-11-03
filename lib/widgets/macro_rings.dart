import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/widgets/macro_guide.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// How a ring reads its target: one to reach (protein, fibre), where more
/// is fine; a guide from the calories (carbs, fat), judged like the calorie
/// bar; or a most (sugars, saturates, salt).
enum _Kind { aim, guide, limit }

typedef _Ring = ({String name, double? grams, int target, _Kind kind});

/// Today's protein and macros as rings in the bars' green, protein first,
/// then carbs, fat and fibre, then the limits: sugars, saturates and salt,
/// scrolling to the right. Targets follow the plan ([HealthCalculator
/// .macroTargets]); a tap on a ring or the info button explains them
/// ([showMacroGuide]). Without YumSum Star ([full] false) protein is the
/// only live ring, and the rest are dimmed under a chip that calls
/// [onUnlock].
class MacroRings extends StatelessWidget {
  const MacroRings({
    super.key,
    required this.meals,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.trackProtein,
    required this.full,
    required this.onUnlock,
  });

  final List<Meal> meals;
  final int calorieTarget;
  final int proteinTarget;
  final bool trackProtein;
  final bool full;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final counted = [for (final meal in meals) ?meal.macros];
    final total = full ? Nutrients.total(counted) : null;
    final protein = meals.fold<double>(
      0,
      (sum, meal) => sum + (meal.proteinGrams ?? 0),
    );
    final targets = HealthCalculator.macroTargets(
      calories: calorieTarget,
      proteinGrams: proteinTarget,
    );
    // Nothing logged yet reads as 0; meals without macros as unknown.
    double? eaten(double? Function(Nutrients n) of) =>
        meals.isEmpty ? 0 : (total == null ? null : of(total) ?? 0);

    final _Ring proteinRing = (
      name: 'Protein',
      grams: protein,
      target: proteinTarget,
      kind: _Kind.aim,
    );
    final List<_Ring> macros = [
      (
        name: 'Carbs',
        grams: eaten((n) => n.carbs),
        target: targets.carbs,
        kind: _Kind.guide,
      ),
      (
        name: 'Fat',
        grams: eaten((n) => n.fat),
        target: targets.fat,
        kind: _Kind.guide,
      ),
      (
        name: 'Fibre',
        grams: eaten((n) => n.fibre),
        target: targets.fibre,
        kind: _Kind.aim,
      ),
      (
        name: 'Sugars',
        grams: eaten((n) => n.sugars),
        target: targets.sugars,
        kind: _Kind.limit,
      ),
      (
        name: 'Saturates',
        grams: eaten((n) => n.saturates),
        target: targets.saturates,
        kind: _Kind.limit,
      ),
      (
        name: 'Salt',
        grams: eaten((n) => n.salt),
        target: targets.salt,
        kind: _Kind.limit,
      ),
    ];

    void explain() => showMacroGuide(context, withProtein: trackProtein);
    Widget row(List<_Ring> rings, {bool preview = false}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, ring) in rings.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          _RingTile(
            ring: ring,
            preview: preview ? _previewFills[i % _previewFills.length] : null,
            onTap: explain,
          ),
        ],
      ],
    );

    final notes = [
      if (trackProtein)
        _count(
          meals.where((meal) => meal.proteinGrams == null).length,
          'protein',
        ),
      if (full) _count(meals.length - counted.length, 'macro'),
    ].nonNulls;

    final Widget rings = full
        // A row, not a list, so it is as tall as its text, whatever its
        // size; the fourth ring peeks in to say it scrolls.
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: row([if (trackProtein) proteinRing, ...macros]),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trackProtein) ...[
                _RingTile(ring: proteinRing, onTap: explain),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _Locked(
                  onUnlock: onUnlock,
                  child: row(macros, preview: true),
                ),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The info button sits left of the first ring rather than on a line
        // of its own.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(padding: const EdgeInsets.only(left: 12), child: rings),
            // The icon just left of the start of the calorie bar, near the
            // top of the ring; the tap area is the usual 48.
            Positioned(
              top: -15,
              left: -20,
              child: IconButton(
                tooltip: 'About macros',
                onPressed: explain,
                icon: const Icon(Icons.info_outline_rounded),
                iconSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              note,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  static const _previewFills = [0.7, 0.5, 0.35, 0.6, 0.45, 0.55];

  static String? _count(int meals, String what) => meals == 0
      ? null
      : '$meals ${meals == 1 ? 'meal' : 'meals'} not counted (no $what info)';
}

/// The macros a free account doesn't have yet: dimmed, part-filled rings
/// with no figures, under a chip, and a tap anywhere calls [onUnlock].
class _Locked extends StatelessWidget {
  const _Locked({required this.onUnlock, required this.child});

  final VoidCallback onUnlock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Unlock full macros with YumSum Star',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onUnlock,
        child: Stack(
          children: [
            Opacity(
              opacity: 0.4,
              child: IgnorePointer(
                // Cut off at the edge rather than scrolled.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: child,
                ),
              ),
            ),
            // Level with the middle of the rings.
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.42),
                child: Material(
                  color: AppColors.primaryContainer,
                  shape: const StadiumBorder(),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PlusStar(size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Unlock full macros',
                          style: AppTheme.display.copyWith(
                            fontSize: 14,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingTile extends StatelessWidget {
  const _RingTile({required this.ring, required this.onTap, this.preview});

  final _Ring ring;
  final VoidCallback onTap;

  /// A made-up fill, shown without a figure.
  final double? preview;

  /// Green while on course; amber, then red, past a most or well past a
  /// guide, the way the calorie bar turns.
  Color get _color {
    final grams = ring.grams;
    if (grams == null || ring.target <= 0 || ring.kind == _Kind.aim) {
      return AppColors.veryGood;
    }
    final share = grams / ring.target;
    final greenUpTo = ring.kind == _Kind.limit ? 1.0 : 1.1;
    if (share <= greenUpTo) return AppColors.veryGood;
    return share <= 1.2 ? AppColors.bad : AppColors.veryBad;
  }

  @override
  Widget build(BuildContext context) {
    final grams = ring.grams;
    final figure = switch (grams) {
      _ when preview != null => '',
      null => '–',
      final g when ring.name == 'Salt' => '${g.toStringAsFixed(1)} g',
      final g => '${g.round()} g',
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            SizedBox.square(
              dimension: 60,
              child: CustomPaint(
                painter: _RingPainter(
                  value:
                      preview ??
                      (grams == null || ring.target <= 0
                          ? 0
                          : grams / ring.target),
                  color: _color,
                  track: AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.85),
                ),
                child: Center(
                  child: Text(
                    figure,
                    style: AppTheme.display.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ring.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (preview == null && ring.target > 0)
              Text(
                '${ring.kind == _Kind.limit ? 'max' : 'of'} ${ring.target} g',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// A round track with the eaten share drawn over it from the top, a little
/// lighter at the start, like the bars.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  static const _stroke = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );
    final sweep = 2 * math.pi * value.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: sweep,
          colors: [Color.lerp(color, Colors.white, 0.3)!, color],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
