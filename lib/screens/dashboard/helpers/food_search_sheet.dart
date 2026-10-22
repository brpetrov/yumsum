import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/services/food_lookup_service.dart';

/// Packaged foods matching [query] in Open Food Facts; resolves to the one
/// tapped, or null if the sheet was dismissed.
Future<PackagedFood?> showFoodSearchSheet(BuildContext context, String query) =>
    showModalBottomSheet<PackagedFood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _FoodSearchSheet(query: query),
    );

class _FoodSearchSheet extends ConsumerStatefulWidget {
  const _FoodSearchSheet({required this.query});

  final String query;

  @override
  ConsumerState<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<_FoodSearchSheet> {
  late final _results = ref
      .read(foodLookupServiceProvider)
      .search(
        widget.query,
        country: ref.read(userProfileProvider).valueOrNull?.country,
      );

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 14, color: AppColors.textSecondary);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Text(
              widget.query,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Packaged foods · Open Food Facts',
              style: muted.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final foods = snapshot.data ?? const <PackagedFood>[];
                if (snapshot.hasError || foods.isEmpty) {
                  final error = snapshot.error;
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error is FoodLookupException
                          ? error.message
                          : snapshot.hasError
                          ? 'Could not search right now.'
                          : 'Nothing found. Try other words, or let the AI '
                                'estimate it.',
                      style: muted,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      title: Text(food.name),
                      subtitle: Text(
                        [
                          if (food.brand != null) food.brand!,
                          '${food.kcalPer100g} kcal per 100 g',
                        ].join(' · '),
                      ),
                      onTap: () => Navigator.of(context).pop(food),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
