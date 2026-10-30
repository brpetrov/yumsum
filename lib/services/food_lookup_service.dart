import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:lean_streak/core/constants/app_info.dart';

/// A packaged food as Open Food Facts describes it, per 100 g.
typedef PackagedFood = ({
  String name,
  String? brand,
  int kcalPer100g,
  int? proteinPer100g,
  int? servingGrams,

  /// A small photo of the front of the pack, when one has been uploaded.
  String? imageUrl,
});

/// What Open Food Facts already has for a product it lists without a
/// calorie figure, so its nutrition can be added and nothing else touched.
typedef ListedProduct = ({
  String? name,
  String? brand,
  String? quantity,
  String? servingSize,

  /// The product's main language on Open Food Facts, e.g. en or bg.
  String? lang,
  bool hasNutritionPhoto,
  String? imageUrl,
});

/// A barcode lookup: [listed] is false when Open Food Facts has never
/// heard of the product; [food] is null too when it has the product but
/// no name or calorie figure for it, and [needsNutrition] is what it has
/// when the calorie figure is what's missing.
typedef BarcodeLookup = ({
  bool listed,
  PackagedFood? food,
  ListedProduct? needsNutrition,
});

class FoodLookupException implements Exception {
  const FoodLookupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Looks packaged foods up in Open Food Facts, the open database behind
/// most barcode scanners: by barcode, or by name. Only the barcode or the
/// words searched for are sent.
class FoodLookupService {
  FoodLookupService([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  /// The product behind [barcode].
  Future<BarcodeLookup> byBarcode(String barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {
        'fields':
            'product_name,product_name_en,brands,nutriments,serving_size,quantity,image_front_small_url,lang,image_nutrition_small_url',
        'app_name': 'YumSum',
      },
    );
    final response = await _get(uri);
    if (response.statusCode == 404) {
      return (listed: false, food: null, needsNutrition: null);
    }
    if (response.statusCode != 200) {
      throw const FoodLookupException(
        'The food database is not answering right now.',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      listed: json['product'] is Map,
      food: parsePackagedFood(json),
      needsNutrition: parseListedProduct(json),
    );
  }

  /// Up to 20 products matching [query], those sold in [country] first,
  /// skipping any without a calorie figure. Phones only: the search
  /// service doesn't allow calls from web pages.
  Future<List<PackagedFood>> search(String query, {String? country}) async {
    final uri = Uri.https('search.openfoodfacts.org', '/search', {
      'q': query,
      'page_size': '30',
      'fields':
          'product_name,product_name_en,brands,nutriments,serving_size,'
          'quantity,countries_tags,image_front_small_url',
    });
    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw const FoodLookupException(
        'The food database is not answering right now.',
      );
    }
    return parseSearchHits(
      jsonDecode(response.body) as Map<String, dynamic>,
      country: country,
    );
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client
          .get(
            uri,
            // Open Food Facts asks apps to identify themselves; browsers
            // don't allow setting this header, so the web relies on app_name.
            headers: {if (!kIsWeb) 'User-Agent': 'YumSum/0.1 ($supportEmail)'},
          )
          .timeout(const Duration(seconds: 12));
    } on Exception {
      throw const FoodLookupException(
        'Could not reach the food database. Check your connection.',
      );
    }
  }
}

/// Reads a search reply: the products sold in [country] (e.g. "United
/// Kingdom") first, those without a calorie figure left out, at most 20.
List<PackagedFood> parseSearchHits(
  Map<String, dynamic> json, {
  String? country,
}) {
  final hits = json['hits'];
  if (hits is! List) return const [];
  final tag = 'en:${country?.toLowerCase().replaceAll(' ', '-')}';
  bool local(Object? hit) =>
      hit is Map && (hit['countries_tags'] as List?)?.contains(tag) == true;
  return [
    for (final hit in [...hits.where(local), ...hits.where((h) => !local(h))])
      if (hit is Map<String, dynamic>) ?parsePackagedFood({'product': hit}),
  ].take(20).toList();
}

/// Reads an Open Food Facts product reply. Null for an unknown product or
/// one without a calorie figure, which is useless for logging.
PackagedFood? parsePackagedFood(Map<String, dynamic> json) {
  final product = json['product'];
  if (product is! Map<String, dynamic>) return null;
  final name =
      _text(product['product_name_en']) ?? _text(product['product_name']);
  if (name == null) return null;

  final nutriments = product['nutriments'];
  final n = nutriments is Map<String, dynamic> ? nutriments : const {};
  final kcal = _kcalPer100g(n);
  if (kcal == null) return null;

  // A comma-separated string from the product API, a list from search.
  final brands = product['brands'];
  final brand =
      (brands is List
              ? _text(brands.firstOrNull)
              : _text(brands)?.split(',').first)
          ?.trim();
  return (
    name: name,
    brand:
        brand != null &&
            brand.isNotEmpty &&
            !name.toLowerCase().contains(brand.toLowerCase())
        ? brand
        : null,
    kcalPer100g: kcal.round(),
    proteinPer100g: _number(n['proteins_100g'])?.round(),
    servingGrams:
        gramsIn(_text(product['serving_size'])) ??
        gramsIn(_text(product['quantity'])),
    imageUrl: _text(product['image_front_small_url']),
  );
}

/// What a product listed without a calorie figure already has. Null for an
/// unknown product, or one with calories.
ListedProduct? parseListedProduct(Map<String, dynamic> json) {
  final product = json['product'];
  if (product is! Map<String, dynamic>) return null;
  final nutriments = product['nutriments'];
  if (_kcalPer100g(nutriments is Map ? nutriments : const {}) != null) {
    return null;
  }
  return (
    name: _text(product['product_name_en']) ?? _text(product['product_name']),
    brand: _text(product['brands'])?.split(',').first.trim(),
    quantity: _text(product['quantity']),
    servingSize: _text(product['serving_size']),
    lang: _text(product['lang']),
    hasNutritionPhoto: _text(product['image_nutrition_small_url']) != null,
    imageUrl: _text(product['image_front_small_url']),
  );
}

double? _kcalPer100g(Map<dynamic, dynamic> n) =>
    _number(n['energy-kcal_100g']) ??
    (_number(n['energy-kj_100g']) ?? _number(n['energy_100g']))?.let(
      (kj) => kj / 4.184,
    );

final _grams = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:g|ml)\b', caseSensitive: false);

/// The grams (or ml) in a label like "30 g", "1 wrap (220 g)" or "4 x 25 g":
/// the first amount written with its unit, so a multipack gives one item.
int? gramsIn(String? label) {
  if (label == null) return null;
  final match = _grams.firstMatch(label);
  if (match == null) return null;
  final grams = double.parse(match.group(1)!.replaceAll(',', '.')).round();
  return grams > 0 ? grams : null;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _number(Object? value) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
