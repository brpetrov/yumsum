import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

/// The unit weights show in: the profile's choice, else kg.
final weightUnitProvider = Provider.autoDispose<WeightUnit>((ref) {
  final chosen = ref.watch(
    userProfileProvider.select((profile) => profile.valueOrNull?.weightUnit),
  );
  return chosen ?? WeightUnit.kg;
});

/// The unit heights show in: the profile's choice, else cm.
final heightUnitProvider = Provider.autoDispose<HeightUnit>((ref) {
  final chosen = ref.watch(
    userProfileProvider.select((profile) => profile.valueOrNull?.heightUnit),
  );
  return chosen ?? HeightUnit.cm;
});
