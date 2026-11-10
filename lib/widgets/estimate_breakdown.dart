import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// How the AI arrived at its number: one muted line of components, which
/// opens into rows with weight and protein when tapped. With [onChanged],
/// a weight can be tapped and corrected; the item is rescaled and the new
/// list handed back, with no further AI call. Where the AI had to assume
/// how much of an item or which kind, it starts open, with the item's
/// other amounts and kinds as chips under it (a kind by what it changes,
/// [choiceLabel]), the assumed ones ticked; a tap swaps that version in
/// the same way. Ignored, the assumption stays.
class EstimateBreakdown extends StatefulWidget {
  const EstimateBreakdown({
    super.key,
    required this.items,
    this.onChanged,
    this.showProtein = true,
  });

  final List<EstimateItem> items;
  final ValueChanged<List<EstimateItem>>? onChanged;
  final bool showProtein;

  @override
  State<EstimateBreakdown> createState() => _EstimateBreakdownState();
}

bool _hasChoices(EstimateItem item) =>
    item.amounts.isNotEmpty || item.options.isNotEmpty;

class _EstimateBreakdownState extends State<EstimateBreakdown> {
  late bool _expanded;

  // The items as the AI gave them, choices and all (settled once a weight
  // is corrected), so an amount and a kind picked combine; what's picked,
  // by index; and the list last handed back, which isn't a new estimate.
  late List<EstimateItem> _asked;
  final _grams = <int, int>{};
  final _kinds = <int, EstimateItem>{};
  List<EstimateItem>? _sent;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(EstimateBreakdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.items, oldWidget.items) &&
        !identical(widget.items, _sent)) {
      _start();
    }
  }

  void _start() {
    _asked = widget.items;
    _grams.clear();
    _kinds.clear();
    _expanded = widget.onChanged != null && _asked.any(_hasChoices);
  }

  void _send(int index, EstimateItem item) {
    final items = [
      for (final (i, other) in widget.items.indexed) i == index ? item : other,
    ];
    _sent = items;
    widget.onChanged?.call(items);
  }

  void _answer(int index, {int? grams, EstimateItem? kind}) {
    setState(() {
      grams == null ? _grams.remove(index) : _grams[index] = grams;
      kind == null ? _kinds.remove(index) : _kinds[index] = kind;
    });
    _send(index, answered(_asked[index], kind: kind, grams: grams));
  }

  Future<void> _changeGrams(int index) async {
    final item = widget.items[index];
    final grams = await showDialog<int>(
      context: context,
      builder: (_) => _GramsDialog(item: item),
    );
    if (grams == null || grams == item.grams || !mounted) return;
    final changed = resized(item, grams);
    setState(() {
      _asked = [
        for (final (i, other) in _asked.indexed) i == index ? changed : other,
      ];
      _grams.remove(index);
      _kinds.remove(index);
    });
    _send(index, changed);
  }

  /// [index]'s other amounts and kinds, each row with the AI's first.
  Widget _choices(int index) {
    final l10n = context.l10n;
    final item = _asked[index];
    Widget row(List<Widget> chips) =>
        Wrap(spacing: 6, runSpacing: 4, children: chips);
    // A tap between the chips mustn't close the breakdown.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.amounts.isNotEmpty)
              row([
                _Chip(
                  item.amount ?? l10n.mealChoiceRegular,
                  selected: _grams[index] == null,
                  onTap: () => _answer(index, kind: _kinds[index]),
                ),
                for (final amount in item.amounts)
                  _Chip(
                    amount.label,
                    selected: _grams[index] == amount.grams,
                    onTap: () => _answer(
                      index,
                      grams: amount.grams,
                      kind: _kinds[index],
                    ),
                  ),
              ]),
            if (item.amounts.isNotEmpty && item.options.isNotEmpty)
              const SizedBox(height: 6),
            if (item.options.isNotEmpty)
              row([
                _Chip(
                  item.assumed ?? item.name,
                  selected: _kinds[index] == null,
                  onTap: () => _answer(index, grams: _grams[index]),
                ),
                for (final option in item.options)
                  _Chip(
                    choiceLabel(item, option),
                    selected: _kinds[index] == option,
                    onTap: () =>
                        _answer(index, grams: _grams[index], kind: option),
                  ),
              ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final editable =
        widget.onChanged != null &&
        widget.items.any((item) => item.grams != null);

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(12),
      // Room around the text, so the highlight doesn't crowd it.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: _expanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, item) in widget.items.indexed) ...[
                    if (index > 0) const SizedBox(height: 10),
                    // A long name wraps; its figures stay on its first line.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            capitalised(item.name),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.grams != null)
                          editable
                              ? InkWell(
                                  onTap: () => _changeGrams(index),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      l10n.commonGrams('${item.grams}'),
                                      style: muted.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primary
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    l10n.commonGrams('${item.grams}'),
                                    style: muted,
                                  ),
                                ),
                        Text(
                          item.protein == null || !widget.showProtein
                              ? l10n.commonKcal(item.kcal)
                              : l10n.mealKcalGrams(item.kcal, item.protein!),
                          style: muted,
                        ),
                      ],
                    ),
                    if (widget.onChanged != null && _hasChoices(_asked[index]))
                      _choices(index),
                  ],
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.items
                          .map((item) => '${item.name} ${item.kcal}')
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Asks for an item's real weight, starting from the AI's.
class _GramsDialog extends StatefulWidget {
  const _GramsDialog({required this.item});

  final EstimateItem item;

  @override
  State<_GramsDialog> createState() => _GramsDialogState();
}

class _GramsDialogState extends State<_GramsDialog> {
  late final _grams = TextEditingController(text: '${widget.item.grams}');

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  void _use() {
    final grams = int.tryParse(_grams.text);
    if (grams != null && grams > 0) Navigator.of(context).pop(grams);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.name),
      content: TextField(
        controller: _grams,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(
          labelText: context.l10n.mealWeight,
          suffixText: context.l10n.commonGramsUnit,
        ),
        onSubmitted: (_) => _use(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(onPressed: _use, child: Text(context.l10n.mealUseWeight)),
      ],
    );
  }
}

/// One amount or kind on a small quiet tag: a hairline edge, filled and
/// ticked when picked.
class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final color = selected
        ? AppColors.onPrimaryContainer
        : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.primaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? AppColors.primaryContainer : AppColors.outline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 13, color: color),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  capitalised(label),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
