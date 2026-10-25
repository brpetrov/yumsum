import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

class FoodContributionException implements Exception {
  const FoodContributionException(this.message);
  final String message;

  @override
  String toString() => message;
}

// The app's shared Open Food Facts account, given at build time
// (`--dart-define-from-file=config/off_account.json`) so the password never
// sits in the repository. Without it, contributing is simply not offered.
const _userId = String.fromEnvironment('OFF_USER_ID');
const _password = String.fromEnvironment('OFF_PASSWORD');
// world.openfoodfacts.org for real contributions; world.openfoodfacts.net
// is their test server, with accounts of its own.
const _host = String.fromEnvironment(
  'OFF_HOST',
  defaultValue: 'world.openfoodfacts.org',
);
const _appVersion = '0.1.0';

final _cyrillic = RegExp(r'[Ѐ-ӿ]');

/// Adds products to Open Food Facts on the user's behalf, through the app's
/// shared account as Open Food Facts asks apps to. [appUuid] is a random id
/// per install, so their moderators can turn away one bad contributor
/// without banning the whole app; nothing else about the user is sent.
class FoodContributionService {
  FoodContributionService({
    required this.appUuid,
    http.Client? client,
    this.userId = _userId,
    this.password = _password,
    this.host = _host,
  }) : _client = client ?? http.Client();

  final String appUuid;
  final String userId;
  final String password;
  final String host;
  final http.Client _client;

  bool get isConfigured => userId.isNotEmpty && password.isNotEmpty;

  Map<String, String> get _account => {
    'user_id': userId,
    'password': password,
    'app_name': 'LeanStreak',
    'app_version': _appVersion,
    'app_uuid': appUuid,
  };

  Map<String, String> get _headers => {
    if (!kIsWeb) 'User-Agent': 'LeanStreak/$_appVersion (broovenn@gmail.com)',
    // The test server sits behind a shared password of its own.
    if (host.endsWith('.net'))
      'Authorization': 'Basic ${base64Encode(utf8.encode('off:off'))}',
  };

  /// Saves the product's details, then its two photos, front first: only
  /// a photo sent as the front becomes the product's front picture.
  Future<void> contribute(ProductContribution product) async {
    final lc = product.lang ?? productLanguage(product.name);
    await _send(
      http.Request('POST', Uri.https(host, '/cgi/product_jqm2.pl'))
        ..bodyFields = {
          ..._account,
          ...productFields(product, lc),
          // Open Food Facts asks for "user agent + user id", nothing personal.
          'comment': 'LeanStreak $_appVersion user $appUuid',
        },
      saved: (reply) => reply?['status'] == 1,
    );
    for (final (field, bytes) in [
      ('front_$lc', product.frontPhoto),
      ('nutrition_$lc', product.labelPhoto),
    ]) {
      await _send(
        http.MultipartRequest(
            'POST',
            Uri.https(host, '/cgi/product_image_upload.pl'),
          )
          ..fields.addAll({
            ..._account,
            'code': product.barcode,
            'lc': lc,
            'imagefield': field,
          })
          ..files.add(
            http.MultipartFile.fromBytes(
              'imgupload_$field',
              bytes,
              filename: '$field.jpg',
            ),
          ),
        // A photo sent before (a retry after a dropped connection) comes
        // back as "already exists" with its id, which is just as good.
        saved: (reply) =>
            reply?['status'] == 'status ok' || reply?['imgid'] != null,
      );
    }
  }

  /// Sends [request]; [saved] reads Open Food Facts' JSON reply. A wrong
  /// account password comes back as an HTML page, so it fails [saved] too.
  Future<void> _send(
    http.BaseRequest request, {
    required bool Function(Map<String, dynamic>? reply) saved,
  }) async {
    request.headers.addAll(_headers);
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
    } on Exception {
      throw const FoodContributionException(
        'Could not reach Open Food Facts. Check your connection and try '
        'again.',
      );
    }
    if (response.statusCode != 200 || !saved(_json(response.body))) {
      debugPrint(
        'Open Food Facts said ${response.statusCode}: ${response.body}',
      );
      throw const FoodContributionException(
        'Open Food Facts didn\'t take it this time. Try again in a moment.',
      );
    }
  }

  static Map<String, dynamic>? _json(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
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
    'nutrition_data_per':
        _volume.hasMatch('${product.quantity} ${product.servingSize}')
        ? '100ml'
        : '100g',
    for (final MapEntry(key: id, :value) in product.per100g.entries) ...{
      'nutriment_$id': _figure(value),
      'nutriment_${id}_unit': id == 'energy-kcal' ? 'kcal' : 'g',
    },
  };
}

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
