import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:lean_streak/core/config/app_check.dart';
import 'package:lean_streak/core/config/crash_reports.dart';

import 'package:lean_streak/core/constants/app_info.dart';
import 'package:lean_streak/l10n/l10n.dart';

/// A new product as the user checked it, ready to send. [per100g] is keyed
/// by Open Food Facts nutrient ids (`energy-kcal`, `proteins`, ...).
typedef ProductContribution = ({
  String barcode,
  String name,
  String? brand,
  String? quantity,
  String? servingSize,
  Map<String, double> per100g,
  Uint8List frontPhoto,
  Uint8List labelPhoto,
  String? country,

  /// The language the name is printed in, when the AI could tell.
  String? lang,
});

/// Nutrition for a product Open Food Facts lists without it, as the user
/// checked it. Only what the product lacks goes: [name] and [servingSize]
/// are null when it has them, [labelPhoto] when it has a nutrition photo.
typedef NutritionContribution = ({
  String barcode,

  /// The product's language, for its name and photo.
  String lang,
  String? name,
  String? servingSize,

  /// Figures per 100 ml, for a product sold by volume.
  bool perVolume,
  Map<String, double> per100g,
  Uint8List? labelPhoto,
});

class FoodContributionException implements Exception {
  const FoodContributionException(this.message);
  final String message;

  @override
  String toString() => message;
}

// A trial run (`--dart-define=OFF_DRY_RUN=true`, the "contribute dry run"
// launch configuration): every screen, any barcode, but what would be sent
// is only printed to the log, so nothing reaches Open Food Facts.
const _dryRun = bool.fromEnvironment('OFF_DRY_RUN');

final _cyrillic = RegExp(r'[Ѐ-ӿ]');

/// Adds products to Open Food Facts on the user's behalf. The
/// `contributeProduct` function sends them through the app's shared
/// account, as Open Food Facts asks apps to; only the server has its
/// password. [appUuid] is a random id per install, so their moderators can
/// turn away one bad contributor without banning the whole app; nothing
/// else about the user is sent.
class FoodContributionService {
  FoodContributionService({
    required this.appUuid,
    required FirebaseFunctions functions,
    this.dryRun = _dryRun,
    AppLocalizations? l10n,
  }) : _functions = functions,
       _l10n = l10n ?? lookupAppLocalizations(const Locale('en'));

  final String appUuid;
  final bool dryRun;
  final FirebaseFunctions _functions;

  /// The language of the errors it throws: the app's (`l10nProvider`).
  final AppLocalizations _l10n;

  /// The account is on the server, so contributing can always be offered
  /// (Today still leaves it out on the web).
  bool get isConfigured => true;

  /// Saves the product's details, then its two photos, front first: only
  /// a photo sent as the front becomes the product's front picture.
  Future<void> contribute(ProductContribution product) {
    final lc = product.lang ?? productLanguage(product.name);
    return _send(productFields(product, lc), {
      'front_$lc': product.frontPhoto,
      'nutrition_$lc': product.labelPhoto,
    });
  }

  /// Adds the nutrition to a product Open Food Facts already lists, then
  /// the nutrition photo if it has none. Nothing else on it is changed.
  Future<void> addNutrition(NutritionContribution nutrition) => _send(
    nutritionFields(nutrition),
    {'nutrition_${nutrition.lang}': ?nutrition.labelPhoto},
  );

  /// Has the server send [fields], then each of [photos] in order as the
  /// picture its key names (front_en, nutrition_bg, ...).
  Future<void> _send(
    Map<String, String> fields,
    Map<String, Uint8List> photos,
  ) async {
    if (dryRun) {
      debugPrint(
        'Open Food Facts dry run, not sent: $fields, photos ${photos.keys}',
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return;
    }
    await ensureAppCheck();
    try {
      await _functions
          .httpsCallable(
            'contributeProduct',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 2)),
          )
          .call<Object?>({
            'appUuid': appUuid,
            'appVersion': appVersion,
            'fields': fields,
            'photos': [
              for (final MapEntry(key: field, value: bytes) in photos.entries)
                {'field': field, 'jpeg': base64Encode(bytes)},
            ],
          });
    } on Exception catch (error, stack) {
      reportError(error, stack, 'Contribute to Open Food Facts');
      throw FoodContributionException(switch (error) {
        FirebaseFunctionsException(code: 'resource-exhausted') =>
          _l10n.contributeErrorLimit,
        // Open Food Facts answered, but not with a yes.
        FirebaseFunctionsException(code: 'aborted') =>
          _l10n.contributeErrorRejected,
        _ => _l10n.contributeErrorOffline,
      });
    }
  }
}

/// The product's main language as Open Food Facts records it: Bulgarian
/// for a Cyrillic name, otherwise English.
String productLanguage(String name) => _cyrillic.hasMatch(name) ? 'bg' : 'en';

const _uk = ('en:united-kingdom', 'uk');
const _bulgaria = ('en:bulgaria', 'bg');

/// The ways people write the countries LeanStreak is used in, with Open
/// Food Facts' country tag and code for each (its code for the United
/// Kingdom is uk, not gb). Any other country is left out, and Open Food
/// Facts goes by where the request came from instead.
const _countries = {
  'united kingdom': _uk,
  'uk': _uk,
  'gb': _uk,
  'great britain': _uk,
  'britain': _uk,
  'england': _uk,
  'scotland': _uk,
  'wales': _uk,
  'northern ireland': _uk,
  'bulgaria': _bulgaria,
  'българия': _bulgaria,
};

final _volume = RegExp(r'\d\s*(?:ml|cl|l)\b', caseSensitive: false);

/// The form fields that describe [product] in its language [lc]. Brands
/// and countries are added to, never replaced, as Open Food Facts asks;
/// the country goes as its taxonomy tag, e.g. en:united-kingdom. Figures
/// are per 100 ml for anything sold by volume.
Map<String, String> productFields(ProductContribution product, String lc) {
  final country = _countries[product.country?.trim().toLowerCase()];
  return {
    'code': product.barcode,
    'lc': lc,
    'lang': lc,
    'cc': ?country?.$2,
    'product_name_$lc': product.name,
    'add_brands': ?product.brand,
    'quantity': ?product.quantity,
    'serving_size': ?product.servingSize,
    'add_countries': ?country?.$1,
    'nutrition_data_per': soldByVolume(product.quantity, product.servingSize)
        ? '100ml'
        : '100g',
    ..._nutriments(product.per100g),
  };
}

/// The form fields for [nutrition]: the figures, plus the name and serving
/// size when the product had none.
Map<String, String> nutritionFields(NutritionContribution nutrition) => {
  'code': nutrition.barcode,
  'product_name_${nutrition.lang}': ?nutrition.name,
  'serving_size': ?nutrition.servingSize,
  'nutrition_data_per': nutrition.perVolume ? '100ml' : '100g',
  ..._nutriments(nutrition.per100g),
};

/// Whether a pack or serving size is a volume (ml, cl, l), so the label's
/// figures are per 100 ml.
bool soldByVolume(String? quantity, String? servingSize) =>
    _volume.hasMatch('$quantity $servingSize');

Map<String, String> _nutriments(Map<String, double> per100g) => {
  for (final MapEntry(key: id, :value) in per100g.entries) ...{
    'nutriment_$id': _figure(value),
    'nutriment_${id}_unit': id == 'energy-kcal' ? 'kcal' : 'g',
  },
};

String _figure(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

/// A random id for this install, as [FoodContributionService.appUuid].
String newAppUuid() {
  final random = Random.secure();
  return [
    for (var i = 0; i < 16; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
