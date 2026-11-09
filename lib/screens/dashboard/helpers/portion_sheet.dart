import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/services/food_lookup_service.dart';
import 'package:lean_streak/widgets/macro_totals.dart';
import 'package:lean_streak/widgets/pack_photo.dart';

typedef Portion = ({String name, int kcal, int? protein, Nutrients? macros});

/// Calories, protein and macros for [grams] of [food].
Portion portionFor(PackagedFood food, int grams) => (
  name: food.name,
  kcal: (food.kcalPer100g * grams / 100).round(),
  protein: switch (food.proteinPer100g) {
    null => null,
    final per100 => (per100 * grams / 100).round(),
  },
  macros: food.macrosPer100g?.scaled(grams / 100),
);

/// Asks how much of [food] was eaten, in grams, with chips for 1, 2 and 3
/// of the pack's servings and the whole pack where the pack says them;
/// resolves to the portion, or null if the sheet was dismissed.
Future<Portion?> showPortionSheet(
  BuildContext context,
  PackagedFood food, {
  bool showProtein = true,
  bool showMacros = false,
}) => showModalBottomSheet<Portion>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  builder: (_) => _PortionSheet(
    food: food,
    showProtein: showProtein,
    showMacros: showMacros,
  ),
);

class _PortionSheet extends StatefulWidget {
  const _PortionSheet({
    required this.food,
    required this.showProtein,
    required this.showMacros,
  });

  final PackagedFood food;
  final bool showProtein;
  final bool showMacros;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late final _grams = TextEditingController(
    text: '${widget.food.servingGrams ?? 100}',
  );

  int get _amount => int.tryParse(_grams.text.trim()) ?? 0;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  void _use() {
    if (_amount <= 0) return;
    Navigator.of(context).pop(portionFor(widget.food, _amount));
  }

  void _setGrams(int grams) {
    final text = '$grams';
    setState(
      () => _grams.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  /// 1, 2 and 3 of the pack's servings, and the whole pack unless it's one
  /// of those, each with its grams.
  List<(String, int)> get _chips {
    final food = widget.food;
    final l10n = context.l10n;
    final servings = [
      if (food.servingGrams case final serving?)
        for (final count in [1, 2, 3])
          (l10n.foodPortionServings(count), serving * count),
    ];
    return [
      ...servings,
      if (food.packGrams case final pack?
          when !servings.any((chip) => chip.$2 == pack))
        (l10n.foodPortionWholePack, pack),
    ];
  }

  /// Whether the pack's words for a serving say more than its grams, as
  /// "1 biscuit (12.5 g)" does and "30 g" doesn't.
  static bool _saysMore(String label) => label
      .replaceAll(
        RegExp(r'\d+(?:[.,]\d+)?\s*(?:g|ml)\b', caseSensitive: false),
        '',
      )
      .contains(RegExp(r'\p{L}', unicode: true));

  String _amounts(int kcal, int? protein) =>
      protein == null || !widget.showProtein
      ? context.l10n.commonKcal(kcal)
      : context.l10n.commonKcalProtein(kcal, protein);

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final portion = portionFor(food, _amount);
    final muted = TextStyle(fontSize: 14, color: AppColors.textSecondary);
    final chips = _chips;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        // padding.bottom is the navigation bar and drops to 0 while the
        // keyboard covers it.
        24 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (food.imageUrl != null) ...[
                  PackPhoto(food.imageUrl, size: 72),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (food.brand != null) Text(food.brand!, style: muted),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.foodPortionSource(
                          _amounts(food.kcalPer100g, food.proteinPer100g),
                        ),
                        style: muted.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, grams) in chips)
                    ChoiceChip(
                      label: Text(label),
                      selected: _amount == grams,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (_) => _setGrams(grams),
                    ),
                ],
              ),
            ],
            if (food.servingLabel case final label? when _saysMore(label)) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.foodPortionServingIs(label),
                style: muted.copyWith(fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _grams,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.l10n.foodPortionAmount,
                      suffixText: context.l10n.commonGramsUnit,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _use(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _amount > 0 ? _amounts(portion.kcal, portion.protein) : '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showMacros && _amount > 0)
              if (portion.macros case final macros?) ...[
                const SizedBox(height: 10),
                Text(
                  macrosLine(macros, l10n: context.l10n),
                  style: muted.copyWith(fontSize: 13),
                ),
              ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _amount > 0 ? _use : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(context.l10n.commonDone),
            ),
          ],
        ),
      ),
    );
  }
}
