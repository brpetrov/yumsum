import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/services/food_lookup_service.dart';

final foodLookupServiceProvider = Provider<FoodLookupService>(
  (ref) => FoodLookupService(),
);
