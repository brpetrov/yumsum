import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/services/food_contribution_service.dart';
import 'package:lean_streak/services/food_lookup_service.dart';

final foodLookupServiceProvider = Provider<FoodLookupService>(
  (ref) => FoodLookupService(),
);

/// Contributions go out under a random id kept for this install.
final foodContributionServiceProvider = Provider<FoodContributionService>((
  ref,
) {
  const key = 'off.app_uuid';
  final prefs = ref.watch(sharedPreferencesProvider);
  final uuid = prefs.getString(key) ?? newAppUuid();
  prefs.setString(key, uuid);
  return FoodContributionService(appUuid: uuid);
});
