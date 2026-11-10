import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/widgets/macro_guide.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:lean_streak/widgets/shine.dart';

/// How a ring reads its target: one to reach (protein, fibre), where more
/// is fine; a guide from the calories (carbs, fat), judged like the calorie
/// bar; or a most (sugars, saturates, salt).
enum _Kind { aim, guide, limit }

/// [decimal] for salt, whose grams get one decimal. A target to reach is
/// green from [greenFrom] grams, gold from [goldFrom], and red under
/// [redBelow] when it has one (else amber).
typedef _Ring = ({
  String name,
  double? grams,
  int target,
  _Kind kind,
  bool decimal,
  double? redBelow,
  double? greenFrom,
  double? goldFrom,
});

/// Where protein's ring changes colour, in g per kg of goal weight: red
/// under 0.8 (the minimum adults need), amber to 1.2, green, then gold from
/// 1.4. The macro guide lists them in grams.
const proteinBandsPerKg = (redBelow: 0.8, greenFrom: 1.2, goldFrom: 1.4);

/// Fibre's: amber under 20 g (80% of the 25 g target), green, then gold
/// from the UK's 30 g.
const fibreBands = (greenFrom: 20.0, goldFrom: 30.0);

/// Today's protein and macros as rings in the bars' green, protein first,
/// then carbs, fat and fibre, then the limits: sugars, saturates and salt,
/// scrolling to the right. Targets follow the plan ([HealthCalculator
/// .macroTargets]); a tap on a ring explains them ([showMacroGuide]).
/// Without YumSum Star ([full] false) protein is the only live ring, and
/// the rest are dimmed under a chip that calls [onUnlock].
class MacroRings extends StatelessWidget {
  const MacroRings({
    super.key,
    required this.meals,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.goalWeightKg,
    required this.trackProtein,
    required this.full,
    required this.onUnlock,
  });

  final List<Meal> meals;
  final int calorieTarget;
  final int proteinTarget;

  /// Protein's colours follow grams per kg of goal weight: red under 0.8
  /// (the minimum adults need), amber to 1.2, green, then gold from 1.4.
  final double goalWeightKg;
  final bool trackProtein;
  final bool full;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
      name: l10n.macroProtein,
      grams: protein,
      target: proteinTarget,
      kind: _Kind.aim,
      decimal: false,
      redBelow: goalWeightKg * proteinBandsPerKg.redBelow,
      greenFrom: goalWeightKg * proteinBandsPerKg.greenFrom,
      goldFrom: goalWeightKg * proteinBandsPerKg.goldFrom,
    );
    final List<_Ring> macros = [
      (
        name: l10n.macroRingCarbs,
        grams: eaten((n) => n.carbs),
        target: targets.carbs,
        kind: _Kind.guide,
        decimal: false,
        redBelow: null,
        greenFrom: null,
        goldFrom: null,
      ),
      (
        name: l10n.macroFat,
        grams: eaten((n) => n.fat),
        target: targets.fat,
        kind: _Kind.guide,
        decimal: false,
        redBelow: null,
        greenFrom: null,
        goldFrom: null,
      ),
      (
        name: l10n.macroFibre,
        grams: eaten((n) => n.fibre),
        target: targets.fibre,
        kind: _Kind.aim,
        decimal: false,
        redBelow: null,
        greenFrom: fibreBands.greenFrom,
        goldFrom: fibreBands.goldFrom,
      ),
      (
        name: l10n.macroSugars,
        grams: eaten((n) => n.sugars),
        target: targets.sugars,
        kind: _Kind.limit,
        decimal: false,
        redBelow: null,
        greenFrom: null,
        goldFrom: null,
      ),
      (
        name: l10n.macroRingSaturates,
        grams: eaten((n) => n.saturates),
        target: targets.saturates,
        kind: _Kind.limit,
        decimal: false,
        redBelow: null,
        greenFrom: null,
        goldFrom: null,
      ),
      (
        name: l10n.macroSalt,
        grams: eaten((n) => n.salt),
        target: targets.salt,
        kind: _Kind.limit,
        decimal: true,
        redBelow: null,
        greenFrom: null,
        goldFrom: null,
      ),
    ];

    void explain() => showMacroGuide(
      context,
      withProtein: trackProtein,
      goalWeightKg: goalWeightKg,
    );
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

    final withoutProtein = meals
        .where((meal) => meal.proteinGrams == null)
        .length;
    final withoutMacros = meals.length - counted.length;
    final notes = [
      if (trackProtein && withoutProtein > 0)
        l10n.macroNotCountedProtein(withoutProtein),
      if (full && withoutMacros > 0) l10n.macroNotCountedMacros(withoutMacros),
    ];

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
        rings,
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
      label: context.l10n.macroUnlockLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onUnlock,
        child: Stack(
          children: [
            Opacity(
              opacity: 0.3,
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
                          context.l10n.macroUnlock,
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

  /// Whether a target to reach is done really well: gold, with a glint.
  bool get _gold => switch ((ring.grams, ring.goldFrom)) {
    (final grams?, final from?) when preview == null => grams >= from,
    _ => false,
  };

  /// A gold ring catches the eye once, with the YumSum Star's glint, when
  /// it turns gold (and again on coming back to Home).
  Widget _shineWhenGold(Widget ring) =>
      _gold ? Shine(sweeps: 1, strength: 0.8, child: ring) : ring;

  /// Green while on course; amber, then red, past a most or well past a
  /// guide, the way the calorie bar turns. A target to reach (protein,
  /// fibre) is amber until [_Ring.greenFrom] (80% of it unless given), red
  /// under [_Ring.redBelow] where it has one, then green, then gold.
  Color get _color {
    final grams = ring.grams;
    if (grams == null || ring.target <= 0) return AppColors.veryGood;
    final share = grams / ring.target;
    if (ring.kind == _Kind.aim) {
      if (_gold) return AppColors.gold;
      if (grams >= (ring.greenFrom ?? ring.target * 0.8)) {
        return AppColors.veryGood;
      }
      final redBelow = ring.redBelow;
      return redBelow != null && grams < redBelow
          ? AppColors.veryBad
          : AppColors.bad;
    }
    final greenUpTo = ring.kind == _Kind.limit ? 1.0 : 1.1;
    if (share <= greenUpTo) return AppColors.veryGood;
    return share <= 1.2 ? AppColors.bad : AppColors.veryBad;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grams = ring.grams;
    final figure = switch (grams) {
      _ when preview != null => '',
      null => '–',
      final g when ring.decimal => l10n.commonGrams(l10n.decimal(g)),
      final g => l10n.commonGrams('${g.round()}'),
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
              child: _shineWhenGold(
                CustomPaint(
                  painter: _RingPainter(
                    value:
                        preview ??
                        (grams == null || ring.target <= 0
                            ? 0
                            : grams / ring.target),
                    color: _color,
                    gold: _gold,
                    track: switch ((_gold, AppColors.isDark)) {
                      (true, true) => AppColors.goldLight.withValues(
                        alpha: 0.14,
                      ),
                      (true, false) => Color.lerp(
                        Colors.white,
                        AppColors.goldLight,
                        0.3,
                      )!.withValues(alpha: 0.9),
                      (false, true) => Colors.white.withValues(alpha: 0.08),
                      (false, false) => Colors.white.withValues(alpha: 0.85),
                    },
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
                switch (ring.kind) {
                  _Kind.limit => l10n.macroRingMax(ring.target),
                  _Kind.aim => l10n.macroRingAtLeast(ring.target),
                  _Kind.guide => l10n.macroRingOf(ring.target),
                },
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// A round track with the eaten share drawn over it from the top, a little
/// lighter at the start, like the bars. A [gold] ring is shaded like
/// polished metal lit from the top left instead: pale there, deep at the
/// bottom right, whatever its share.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    this.gold = false,
  });

  final double value;
  final Color color;
  final Color track;
  final bool gold;

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
    final share = 2 * math.pi * value.clamp(0.0, 1.0);
    if (share <= 0) return;
    final arc = Paint()
      ..shader =
          (gold
                  ? SweepGradient(
                      // Clockwise from the top, the same colour at both ends
                      // so a full ring has no seam.
                      colors: [
                        color,
                        AppColors.goldDeep,
                        color,
                        AppColors.goldLight,
                        color,
                      ],
                      stops: const [0, 0.375, 0.65, 0.875, 1],
                      transform: const GradientRotation(-math.pi / 2),
                    )
                  : SweepGradient(
                      startAngle: 0,
                      endAngle: share,
                      colors: [Color.lerp(color, Colors.white, 0.3)!, color],
                      transform: const GradientRotation(-math.pi / 2),
                    ))
              .createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    // A full gold ring is one unbroken band, like a real ring.
    if (gold && value >= 1) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, arc);
      return;
    }
    // The round ends reach half the stroke past each end of the arc, so it
    // is drawn that much shorter at both: with its ends it covers the share
    // eaten, and a full ring's ends meet at the top rather than overlap.
    final cap = _stroke / 2 / (rect.width / 2);
    canvas.drawArc(
      rect,
      -math.pi / 2 + cap,
      math.max(share - 2 * cap, 0.001),
      false,
      arc..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.gold != gold;
}
