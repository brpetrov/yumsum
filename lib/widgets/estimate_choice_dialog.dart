import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// Asks about every item of [items] the AI couldn't settle
/// ([showEstimateChoice]), at most [limit] of them, and returns the list
/// with the answers in: the version picked, or the one the AI went with
/// when dismissed. Null when there was nothing to ask.
Future<List<EstimateItem>?> offerEstimateChoices(
  BuildContext context,
  List<EstimateItem> items, {
  int limit = 2,
}) async {
  final asked = [
    for (final (index, item) in items.indexed)
      if (item.options.isNotEmpty) index,
  ].take(limit).toList();
  if (asked.isEmpty) return null;
  final result = [...items];
  for (final index in asked) {
    if (!context.mounted) return null;
    final chosen = await showEstimateChoice(context, items[index]);
    result[index] = chosen ?? items[index].settled;
  }
  return result;
}

/// Asks which version of [item] the user had, when the AI couldn't tell:
/// the one it went with first, ticked, then the other likely versions, each
/// with its calories. A tap answers. Returns the version, or null when
/// dismissed, which keeps the first.
Future<EstimateItem?> showEstimateChoice(
  BuildContext context,
  EstimateItem item,
) {
  return showDialog<EstimateItem>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Which did you have?'),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Text(
              'We went with the first.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
          ),
          _Choice(
            item,
            assumed: true,
            onTap: () => Navigator.of(context).pop(item.settled),
          ),
          for (final option in item.options)
            _Choice(option, onTap: () => Navigator.of(context).pop(option)),
        ],
      ),
    ),
  );
}

/// One version of the item: its name and calories on a soft pill, tinted
/// and ticked for the one the AI went with.
class _Choice extends StatelessWidget {
  const _Choice(this.item, {this.assumed = false, required this.onTap});

  final EstimateItem item;
  final bool assumed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final name = item.name;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: assumed ? AppColors.primaryContainer : AppColors.surfaceVariant,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name.isEmpty
                        ? name
                        : name[0].toUpperCase() + name.substring(1),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: assumed
                          ? AppColors.onPrimaryContainer
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${item.kcal} kcal',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (assumed) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
