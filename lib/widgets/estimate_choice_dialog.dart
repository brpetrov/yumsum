import 'dart:math';

import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// Asks about the items of [items] the AI couldn't settle
/// ([showEstimateChoice]): at most [limit] of them, those whose answers
/// move the calories most, in the meal's order. Returns the list with the
/// answers in, every other item settled, as is one whose dialog was
/// dismissed. Null when there was nothing to ask. [said] is what the user
/// typed or said, shown under the title; a meal of one item then needs no
/// item name.
Future<List<EstimateItem>?> offerEstimateChoices(
  BuildContext context,
  List<EstimateItem> items, {
  int limit = 2,
  String? said,
}) async {
  final open = [
    for (final (index, item) in items.indexed)
      if (item.amounts.isNotEmpty || item.options.isNotEmpty) index,
  ];
  if (open.isEmpty) return null;
  final widest = [...open]
    ..sort((a, b) {
      final wider = _spread(items[b]).compareTo(_spread(items[a]));
      return wider != 0 ? wider : a.compareTo(b);
    });
  final asked = widest.take(limit).toSet();
  final result = [for (final item in items) item.settled];
  for (final index in open.where(asked.contains)) {
    if (!context.mounted) return null;
    final chosen = await showEstimateChoice(
      context,
      items[index],
      said: said,
      showName: said == null || items.length > 1,
    );
    result[index] = chosen ?? items[index].settled;
  }
  return result;
}

/// How far an item's answers can move its calories: the widest gap between
/// it and any of its amounts or kinds.
int _spread(EstimateItem item) => [
  if (item.grams case final from?)
    for (final amount in item.amounts)
      (item.kcal * amount.grams / from - item.kcal).abs().round(),
  for (final option in item.options) (option.kcal - item.kcal).abs(),
].fold(0, max);

/// Asks how much of [item] the user had and which kind, where the AI
/// couldn't tell: a row of amounts and a row of kinds, each with the one
/// the AI went with first and ticked, and the calories of what's picked.
/// Done answers that, settled; Cancel or dismissing answers null, which
/// keeps the AI's. [said], what the user typed or said, goes under the
/// title; [showName] false leaves out the item's name (a one-item meal).
Future<EstimateItem?> showEstimateChoice(
  BuildContext context,
  EstimateItem item, {
  String? said,
  bool showName = true,
}) => showDialog<EstimateItem>(
  context: context,
  builder: (_) => _ChoiceDialog(item, said: said, showName: showName),
);

class _ChoiceDialog extends StatefulWidget {
  const _ChoiceDialog(this.item, {this.said, this.showName = true});

  final EstimateItem item;
  final String? said;
  final bool showName;

  @override
  State<_ChoiceDialog> createState() => _ChoiceDialogState();
}

class _ChoiceDialogState extends State<_ChoiceDialog> {
  // The amount and the kind picked; null for the AI's.
  int? _grams;
  EstimateItem? _kind;

  EstimateItem get _answer => answered(widget.item, kind: _kind, grams: _grams);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = widget.item;

    Widget row(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mealChoiceTitle),
          // What the user typed or said, so they know what's being asked.
          if (widget.said case final said?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _capitalised(said),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The kind row starts with the item's name; without one, the
            // name says what the amounts are of, unless the meal is just
            // this item and the subtitle already says.
            if (item.options.isEmpty && widget.showName)
              Text(
                _capitalised(item.name),
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
            if (item.amounts.isNotEmpty)
              row(
                RegExp(r'^\d').hasMatch(item.amount ?? '')
                    ? l10n.mealChoiceHowMany
                    : l10n.mealChoiceHowMuch,
                [
                  _Chip(
                    item.amount ?? l10n.mealChoiceRegular,
                    selected: _grams == null,
                    onTap: () => setState(() => _grams = null),
                  ),
                  for (final amount in item.amounts)
                    _Chip(
                      amount.label,
                      selected: _grams == amount.grams,
                      onTap: () => setState(() => _grams = amount.grams),
                    ),
                ],
              ),
            if (item.options.isNotEmpty)
              row(l10n.mealChoiceWhichKind, [
                _Chip(
                  item.name,
                  selected: _kind == null,
                  onTap: () => setState(() => _kind = null),
                ),
                for (final option in item.options)
                  _Chip(
                    option.name,
                    selected: _kind == option,
                    onTap: () => setState(() => _kind = option),
                  ),
              ]),
            const SizedBox(height: 18),
            Text(
              l10n.commonKcal(_answer.kcal),
              style: AppTheme.display.copyWith(
                fontSize: 24,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_answer),
          child: Text(l10n.commonDone),
        ),
      ],
    );
  }
}

String _capitalised(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// One answer on a soft pill, tinted and ticked when picked.
class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: selected ? AppColors.primaryContainer : AppColors.surfaceVariant,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _capitalised(label),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.onPrimaryContainer
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
