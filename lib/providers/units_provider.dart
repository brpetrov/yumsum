import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

/// The unit weights show in: the profile's choice, else the default for
/// where the user lives.
final weightUnitProvider = Provider.autoDispose<WeightUnit>((ref) {
  final chosen = ref.watch(
    userProfileProvider.select((profile) => profile.valueOrNull?.weightUnit),
  );
  return chosen ?? defaultWeightUnitFor(ref.watch(countryProvider));
});

/// The unit heights show in, chosen or defaulted as [weightUnitProvider].
final heightUnitProvider = Provider.autoDispose<HeightUnit>((ref) {
  final chosen = ref.watch(
    userProfileProvider.select((profile) => profile.valueOrNull?.heightUnit),
  );
  return chosen ?? defaultHeightUnitFor(ref.watch(countryProvider));
});
