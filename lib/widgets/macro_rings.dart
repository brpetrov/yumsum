import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/widgets/macro_guide.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// One ring: what's eaten against the target, and whether the target is a
/// most (saturates, sugars, salt), whose ring turns amber once it's passed.
typedef _Ring = ({String name, double? grams, int target, bool limit});

/// Today's macros for YumSum Star, as rings in the bars' green: protein
/// (when tracked), fat and carbs first, then saturates, sugars, fibre and
/// salt to scroll to. Targets follow the plan ([HealthCalculator
/// .macroTargets]); the info button explains them ([showMacroGuide]).
class MacroRings extends StatelessWidget {
  const MacroRings({
    super.key,
    required this.meals,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.trackProtein,
  });

  final List<Meal> meals;
  final int calorieTarget;
  final int proteinTarget;
  final bool trackProtein;

  @override
  Widget build(BuildContext context) {
    final counted = [for (final meal in meals) ?meal.macros];
    final total = Nutrients.total(counted);
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

    final List<_Ring> rings = [
      if (trackProtein)
        (name: 'Protein', grams: protein, target: proteinTarget, limit: false),
      (
        name: 'Fat',
        grams: eaten((n) => n.fat),
        target: targets.fat,
        limit: false,
      ),
      (
        name: 'Carbs',
        grams: eaten((n) => n.carbs),
        target: targets.carbs,
        limit: false,
      ),
      (
        name: 'Saturates',
        grams: eaten((n) => n.saturates),
        target: targets.saturates,
        limit: true,
      ),
      (
        name: 'Sugars',
        grams: eaten((n) => n.sugars),
        target: targets.sugars,
        limit: true,
      ),
      (
        name: 'Fibre',
        grams: eaten((n) => n.fibre),
        target: targets.fibre,
        limit: false,
      ),
      (
        name: 'Salt',
        grams: eaten((n) => n.salt),
        target: targets.salt,
        limit: true,
      ),
    ];
    final notes = [
      if (trackProtein)
        _count(
          meals.where((meal) => meal.proteinGrams == null).length,
          'protein',
        ),
      _count(meals.length - counted.length, 'macro'),
    ].nonNulls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          info: IconButton(
            tooltip: 'About macros',
            onPressed: () => showMacroGuide(
              context,
              total,
              protein: trackProtein ? protein : null,
            ),
            icon: const Icon(Icons.info_outline_rounded),
            iconSize: 20,
            color: AppColors.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 10),
        _RingRow(rings: rings),
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

  static String? _count(int meals, String what) => meals == 0
      ? null
      : '$meals ${meals == 1 ? 'meal' : 'meals'} not counted (no $what info)';
}

/// The rings dimmed, for an account without YumSum Star: a tap opens
/// [onTap] (the YumSum Star page).
class MacroRingsTeaser extends StatelessWidget {
  const MacroRingsTeaser({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Macros with YumSum Star',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              info: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PlusStar(size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'Become a Star',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // There to see, not to use.
            Opacity(
              opacity: 0.45,
              child: IgnorePointer(
                child: _RingRow(
                  preview: true,
                  rings: [
                    for (final name in ['Fat', 'Carbs', 'Fibre', 'Salt'])
                      (name: name, grams: null, target: 0, limit: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info});

  final Widget info;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Macros',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        info,
      ],
    );
  }
}

/// The rings side by side; past the first three they scroll, and the next
/// one peeks in to say so.
class _RingRow extends StatelessWidget {
  const _RingRow({required this.rings, this.preview = false});

  final List<_Ring> rings;

  /// Part-filled rings with no figures, to show what YumSum Star adds.
  final bool preview;

  static const _previewFills = [0.7, 0.5, 0.35, 0.6];

  @override
  Widget build(BuildContext context) {
    // A row, not a list, so it is as tall as its text, whatever its size.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, ring) in rings.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            _RingTile(
              ring: ring,
              preview: preview ? _previewFills[i % _previewFills.length] : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _RingTile extends StatelessWidget {
  const _RingTile({required this.ring, this.preview});

  final _Ring ring;

  /// A made-up fill, shown without a figure.
  final double? preview;

  @override
  Widget build(BuildContext context) {
    final grams = ring.grams;
    final over = ring.limit && grams != null && grams > ring.target;
    final figure = switch (grams) {
      _ when preview != null => '',
      null => '–',
      final g when ring.name == 'Salt' => '${g.toStringAsFixed(1)} g',
      final g => '${g.round()} g',
    };
    return SizedBox(
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
                color: over ? AppColors.bad : AppColors.veryGood,
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
          if (ring.target > 0)
            Text(
              '${ring.limit ? 'max' : 'of'} ${ring.target} g',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
        ],
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
