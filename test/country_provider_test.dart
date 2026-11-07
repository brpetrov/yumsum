import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

import 'adaptive_fixtures.dart';

void main() {
  /// The country for a device that gives [region], with [stored] in the
  /// profile (no profile when null).
  Future<String> countryFor(String? region, {String? stored}) async {
    final profile = stored == null
        ? null
        : planProfile().copyWith(country: stored);
    final container = ProviderContainer(
      overrides: [
        deviceRegionProvider.overrideWithValue(region),
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(countryProvider, (_, _) {});
    await container.read(userProfileProvider.future);
    return container.read(countryProvider);
  }

  test('the device\'s region wins over the stored country', () async {
    expect(await countryFor('BG', stored: 'United Kingdom'), 'Bulgaria');
    expect(await countryFor('gb', stored: 'Bulgaria'), 'United Kingdom');
  });

  test('no region: the stored country', () async {
    expect(await countryFor(null, stored: 'Bulgaria'), 'Bulgaria');
    expect(await countryFor('', stored: 'Bulgaria'), 'Bulgaria');
  });

  test('neither: the default', () async {
    expect(await countryFor(null), defaultCountry);
    expect(await countryFor(null, stored: ' '), defaultCountry);
  });
}
