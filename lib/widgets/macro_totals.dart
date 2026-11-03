import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/widgets/macro_guide.dart';

const _names = ['fat', 'saturates', 'carbs', 'sugars', 'fibre', 'salt'];

List<double?> _six(Nutrients n) => [
  n.fat,
  n.saturates,
  n.carbs,
  n.sugars,
  n.fibre,
  n.salt,
];

// Non-breaking, so a line wraps between figures, never inside one.
const _nb = ' ';

/// Whole grams, except salt, which gets one decimal.
String _grams(String name, double value) =>
    '${name == 'salt' ? value.toStringAsFixed(1) : value.round()}${_nb}g';

String _capitalised(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// The known figures in one line, for a meal's row, the recipe page and the
/// amount sheet: "Fat 18 g · saturates 6 g · carbs 52 g · sugars 5 g ·
/// fibre 4 g · salt 2.1 g", each figure held together.
String macrosLine(Nutrients macros) => _capitalised(
  [
    for (final (i, value) in _six(macros).indexed)
      if (value != null) '${_names[i]}$_nb${_grams(_names[i], value)}',
  ].join(' · '),
);

/// A day's macros, for YumSum Star: one muted line with fat, carbs and salt
/// (four figures don't fit a 360dp phone, and salt is the one with a
/// limit), which opens on a tap to all six. Its info button explains each
/// one and the UK's guides ([showMacroGuide]). Plain totals: no bars, no
/// colours, no targets. Hidden with nothing logged; [noneNote] when no meal
/// has macros.
class MacroTotals extends StatefulWidget {
  const MacroTotals({
    super.key,
    required this.meals,
    this.noneNote = 'No macro info for today\'s meals',
  });

  final List<Meal> meals;
  final String noneNote;

  @override
  State<MacroTotals> createState() => _MacroTotalsState();
}

class _MacroTotalsState extends State<MacroTotals> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final meals = widget.meals;
    if (meals.isEmpty) return const SizedBox.shrink();
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final counted = [for (final meal in meals) ?meal.macros];
    if (counted.isEmpty) return Text(widget.noneNote, style: muted);

    final total = Nutrients.total(counted)!;
    final uncounted = meals.length - counted.length;
    // The info button, then the chevron, at the end of the last line.
    final ends = [
      IconButton(
        tooltip: 'About macros',
        onPressed: () => showMacroGuide(context, total),
        icon: const Icon(Icons.info_outline_rounded),
        iconSize: 18,
        color: AppColors.textSecondary,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
      Icon(
        _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
    ];

    final Widget child;
    if (!_open) {
      final short = macrosLine(
        Nutrients(fat: total.fat, carbs: total.carbs, salt: total.salt),
      );
      child = Row(
        children: [
          Expanded(
            child: Text(
              short.isEmpty ? macrosLine(total) : short,
              style: muted,
            ),
          ),
          ...ends,
        ],
      );
    } else {
      final totals = _six(total);
      // "At least" where some of the counted meals don't give the figure.
      String value(int i) => switch (totals[i]) {
        null => '–',
        final grams when counted.any((n) => _six(n)[i] == null) =>
          'at least ${_grams(_names[i], grams)}',
        final grams => _grams(_names[i], grams),
      };
      Widget cell(int i) => Row(
        children: [
          Text(_capitalised(_names[i]), style: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value(i),
              textAlign: TextAlign.end,
              style: muted.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _names.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: cell(i)),
                  const SizedBox(width: 20),
                  Expanded(child: cell(i + 1)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: uncounted > 0
                    ? Text(
                        '$uncounted ${uncounted == 1 ? 'meal' : 'meals'} not '
                        'counted (no macro info)',
                        style: muted,
                      )
                    : const SizedBox.shrink(),
              ),
              ...ends,
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _open = !_open),
      child: child,
    );
  }
}
