import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

/// The device's region code (ISO, e.g. GB): the phone's region in the app,
/// the browser's language region on the web. Null when it gives none.
final deviceRegionProvider = Provider<String?>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale.countryCode,
);

/// The device's language code (e.g. en, bg): the phone's language in the
/// app, the browser's first language on the web.
final deviceLanguageProvider = Provider<String>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale.languageCode,
);

/// Where the user lives, for the AI, food search and contributions: the
/// device's region, else the country the profile stored at onboarding, else
/// [defaultCountry]. Never written back to the profile.
final countryProvider = Provider.autoDispose<String>((ref) {
  final region = ref.watch(deviceRegionProvider);
  if (region != null && region.isNotEmpty) return countryNameFor(region);
  final stored = ref.watch(
    userProfileProvider.select((profile) => profile.valueOrNull?.country),
  );
  return stored == null || stored.trim().isEmpty ? defaultCountry : stored;
});
