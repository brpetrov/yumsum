import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/widgets/macro_guide.dart';

/// The names of [_six]'s figures, in its order.
List<String> _names(AppLocalizations l10n) => [
  l10n.macroFat,
  l10n.macroSaturates,
  l10n.macroCarbs,
  l10n.macroSugars,
  l10n.macroFibre,
  l10n.macroSalt,
];

/// Salt's place in [_six].
const _salt = 5;

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
String _grams(AppLocalizations l10n, double value, {bool salt = false}) =>
    '${salt ? l10n.decimal(value) : value.round()}$_nb${l10n.commonGramsUnit}';

/// The known figures in one line, for a meal's row, the recipe page and the
/// amount sheet: "Fat 18 g · saturates 6 g · carbs 52 g · sugars 5 g ·
/// fibre 4 g · salt 2.1 g", each figure held together. With [protein], it
/// goes where a food label has it, between fibre and salt. In [l10n]'s
/// language, English without it.
String macrosLine(Nutrients macros, {double? protein, AppLocalizations? l10n}) {
  final texts = l10n ?? lookupAppLocalizations(const Locale('en'));
  final names = _names(texts);
  return capitalised(
    [
      for (final (i, value) in _six(macros).indexed) ...[
        if (i == _salt && protein != null)
          '${texts.macroProtein.toLowerCase()}$_nb${_grams(texts, protein)}',
        if (value != null)
          '${names[i].toLowerCase()}$_nb'
              '${_grams(texts, value, salt: i == _salt)}',
      ],
    ].join(' · '),
  );
}

/// A day's macros, for YumSum Star: one muted line with fat, carbs and salt
/// (four figures don't fit a 360dp phone, and salt is the one with a
/// limit), which opens on a tap to all six. Its info button explains each
/// one and the UK's guides ([showMacroGuide]). Plain totals: no bars, no
/// colours, no targets. Hidden with nothing logged; [noneNote] when no meal
/// has macros (by default, that today's meals have none).
class MacroTotals extends StatefulWidget {
  const MacroTotals({super.key, required this.meals, this.noneNote});

  final List<Meal> meals;
  final String? noneNote;

  @override
  State<MacroTotals> createState() => _MacroTotalsState();
}

class _MacroTotalsState extends State<MacroTotals> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final meals = widget.meals;
    if (meals.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final counted = [for (final meal in meals) ?meal.macros];
    if (counted.isEmpty) {
      return Text(widget.noneNote ?? l10n.macroNoneToday, style: muted);
    }

    final total = Nutrients.total(counted)!;
    final uncounted = meals.length - counted.length;
    // The info button, then the chevron, at the end of the last line.
    final ends = [
      IconButton(
        tooltip: l10n.macroAbout,
        onPressed: () => showMacroGuide(context, withProtein: false),
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
        l10n: l10n,
      );
      child = Row(
        children: [
          Expanded(
            child: Text(
              short.isEmpty ? macrosLine(total, l10n: l10n) : short,
              style: muted,
            ),
          ),
          ...ends,
        ],
      );
    } else {
      final totals = _six(total);
      final names = _names(l10n);
      // "At least" where some of the counted meals don't give the figure.
      String value(int i) => switch (totals[i]) {
        null => '–',
        final grams when counted.any((n) => _six(n)[i] == null) =>
          l10n.macroAtLeast(_grams(l10n, grams, salt: i == _salt)),
        final grams => _grams(l10n, grams, salt: i == _salt),
      };
      Widget cell(int i) => Row(
        children: [
          Text(names[i], style: muted),
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
          for (var i = 0; i < names.length; i += 2)
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
                    ? Text(l10n.macroNotCountedMacros(uncounted), style: muted)
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
