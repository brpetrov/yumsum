import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language chosen on this device: 'en', 'bg', or null when never
/// chosen, which shows English.
class LanguageController extends Notifier<String?> {
  static const _key = 'language';

  @override
  String? build() => storedIn(ref.watch(sharedPreferencesProvider));

  /// The setting as stored in [prefs], for main()'s first screens, which
  /// show before Riverpod.
  static String? storedIn(SharedPreferences prefs) {
    final stored = prefs.getString(_key);
    return AppLocalizations.supportedLocales.any(
          (locale) => locale.languageCode == stored,
        )
        ? stored
        : null;
  }

  Future<void> setLanguage(String code) async {
    state = code;
    await ref.read(sharedPreferencesProvider).setString(_key, code);
  }
}

final languageControllerProvider =
    NotifierProvider<LanguageController, String?>(LanguageController.new);

/// The language the app shows, 'en' or 'bg'. Also the one place the Cloud
/// Functions' calls take the language from, so replies and emails match.
final languageCodeProvider = Provider<String>(
  (ref) => ref.watch(languageControllerProvider) ?? 'en',
);

/// The app's texts for code without a BuildContext (controllers, services,
/// notifications): `ref.read(l10nProvider).someKey`. Follows the setting;
/// watch it where the text must change with the language.
final l10nProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(Locale(ref.watch(languageCodeProvider))),
);

/// Ask the language before sign-in: none chosen yet, and the device is set
/// to Bulgaria or Malta or to Bulgarian. Everyone else gets English unasked.
final languagePromptProvider = Provider<bool>((ref) {
  if (ref.watch(languageControllerProvider) != null) return false;
  final region = ref.watch(deviceRegionProvider)?.toUpperCase();
  return region == 'BG' ||
      region == 'MT' ||
      ref.watch(deviceLanguageProvider) == 'bg';
});
