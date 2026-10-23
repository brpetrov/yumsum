import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// How the AI arrived at its number: one muted line of components, which
/// opens into rows with weight and protein when tapped. With [onChanged],
/// a weight can be tapped and corrected; the item is rescaled and the new
/// list handed back, with no further AI call.
class EstimateBreakdown extends StatefulWidget {
  const EstimateBreakdown({super.key, required this.items, this.onChanged});

  final List<EstimateItem> items;
  final ValueChanged<List<EstimateItem>>? onChanged;

  @override
  State<EstimateBreakdown> createState() => _EstimateBreakdownState();
}

class _EstimateBreakdownState extends State<EstimateBreakdown> {
  bool _expanded = false;

  Future<void> _changeGrams(int index) async {
    final item = widget.items[index];
    final grams = await showDialog<int>(
      context: context,
      builder: (_) => _GramsDialog(item: item),
    );
    if (grams == null || grams == item.grams || !mounted) return;
    widget.onChanged?.call([
      for (final (i, other) in widget.items.indexed)
        i == index ? resized(other, grams) : other,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final editable =
        widget.onChanged != null &&
        widget.items.any((item) => item.grams != null);

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: _expanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, item) in widget.items.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name, style: muted)),
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
                                        '${item.grams} g',
                                        style: muted.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '${item.grams} g',
                                      style: muted,
                                    ),
                                  ),
                          Text(
                            item.protein == null
                                ? '${item.kcal} kcal'
                                : '${item.kcal} kcal · ${item.protein} g',
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  if (editable)
                    Text(
                      'Tap a weight to change it.',
                      style: muted.copyWith(fontSize: 12),
                    ),
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
        decoration: const InputDecoration(labelText: 'Weight', suffixText: 'g'),
        onSubmitted: (_) => _use(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _use, child: const Text('Use')),
      ],
    );
  }
}
