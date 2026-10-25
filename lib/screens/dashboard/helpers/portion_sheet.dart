import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/services/food_lookup_service.dart';
import 'package:lean_streak/widgets/pack_photo.dart';

typedef Portion = ({String name, int kcal, int? protein});

/// Calories and protein for [grams] of [food].
Portion portionFor(PackagedFood food, int grams) => (
  name: food.name,
  kcal: (food.kcalPer100g * grams / 100).round(),
  protein: switch (food.proteinPer100g) {
    null => null,
    final per100 => (per100 * grams / 100).round(),
  },
);

/// Asks how much of [food] was eaten; resolves to the portion, or null if
/// the sheet was dismissed.
Future<Portion?> showPortionSheet(BuildContext context, PackagedFood food) =>
    showModalBottomSheet<Portion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _PortionSheet(food: food),
    );

class _PortionSheet extends StatefulWidget {
  const _PortionSheet({required this.food});

  final PackagedFood food;

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

  String _amounts(int kcal, int? protein) =>
      protein == null ? '$kcal kcal' : '$kcal kcal · $protein g protein';

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final portion = portionFor(food, _amount);
    final muted = TextStyle(fontSize: 14, color: AppColors.textSecondary);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
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
                      '${_amounts(food.kcalPer100g, food.proteinPer100g)}'
                      ' per 100 g · Open Food Facts',
                      style: muted.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    suffixText: 'g',
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
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _amount > 0 ? _use : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
