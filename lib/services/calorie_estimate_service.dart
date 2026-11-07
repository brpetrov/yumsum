import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/config/app_check.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';

/// One component of an AI estimate; [grams] is the weight the AI assumed
/// (ml for drinks), null when it gave none. Where the user left out what
/// swings the calories (the size, the milk, takeaway or homemade), the AI
/// went with the usual version and [options] are the other likely ones,
/// complete, for `showEstimateChoice`; empty otherwise.
class EstimateItem {
  const EstimateItem({
    required this.name,
    this.grams,
    required this.kcal,
    this.protein,
    this.options = const [],
  });

  final String name;
  final int? grams;
  final int kcal;
  final int? protein;
  final List<EstimateItem> options;

  /// This item with nothing left to ask.
  EstimateItem get settled =>
      EstimateItem(name: name, grams: grams, kcal: kcal, protein: protein);

  @override
  bool operator ==(Object other) =>
      other is EstimateItem &&
      other.name == name &&
      other.grams == grams &&
      other.kcal == kcal &&
      other.protein == protein &&
      listEquals(other.options, options);

  @override
  int get hashCode =>
      Object.hash(name, grams, kcal, protein, Object.hashAll(options));

  @override
  String toString() => 'EstimateItem($name, $kcal kcal)';
}

/// An option closer than this to the item's calories isn't worth asking
/// about.
const optionGap = 30;

/// [macros] are for the whole meal, and only there when they were asked for.
typedef CalorieEstimate = ({
  int kcal,
  int? protein,
  Nutrients? macros,
  List<EstimateItem> items,
});

/// A meal recognised from a voice note or a photo.
typedef VoiceMealParsed = ({
  String name,
  int kcal,
  int? protein,
  Nutrients? macros,
  List<EstimateItem> items,
});

/// What the AI read off a packet for a contribution. Anything the photos
/// don't show is null, or missing from [per100g], which is keyed by Open
/// Food Facts nutrient ids ([labelNutrientIds]).
typedef LabelReading = ({
  String? name,

  /// Two-letter code of the language the name is printed in.
  String? lang,
  String? brand,
  String? quantity,
  String? servingSize,
  Map<String, double> per100g,
});

/// The per-100 g figures a contribution carries, as Open Food Facts names
/// them: energy in kcal, the rest in grams.
const labelNutrientIds = [
  'energy-kcal',
  'proteins',
  'fat',
  'saturated-fat',
  'carbohydrates',
  'sugars',
  'fiber',
  'salt',
];

/// Reads the model's label reply, dropping blanks and odd values.
LabelReading parseLabelReading(Map<String, dynamic> map) {
  String? text(Object? value) =>
      value is String &&
          value.trim().isNotEmpty &&
          value.trim().toLowerCase() != 'null'
      ? value.trim()
      : null;
  final figures = map['per_100g'];
  return (
    name: text(map['name']),
    lang: switch (text(map['lang'])?.toLowerCase()) {
      final code? when RegExp(r'^[a-z]{2}$').hasMatch(code) => code,
      _ => null,
    },
    brand: text(map['brand']),
    quantity: text(map['quantity']),
    servingSize: text(map['serving_size']),
    per100g: {
      if (figures is Map)
        for (final id in labelNutrientIds)
          if (figures[id] case final num value when value >= 0)
            id: value.toDouble(),
    },
  );
}

/// Reads the model's `items` list, skipping anything malformed. An item's
/// options are kept at most 3, each at least [optionGap] kcal from the item
/// and from each other, not the item or an earlier option under the same
/// name, and keeping every word of the item's name the user [said]: the AI
/// is told to offer them rarely, and this catches it asking about nothing,
/// or arguing with the user (a soy latte for a large oat latte).
List<EstimateItem> parseEstimateItems(Object? raw, {String said = ''}) {
  if (raw is! List) return const [];
  final saidWords = _words(said);
  return [
    for (final entry in raw)
      if (_itemFrom(entry) case final item?)
        _withOptions(item, (entry as Map)['options'], saidWords),
  ];
}

/// The words of [text] of three letters or more, in lower case.
Set<String> _words(String text) => {
  for (final word in text.toLowerCase().split(
    RegExp(r'[^\p{L}\p{N}]+', unicode: true),
  ))
    if (word.length > 2) word,
};

/// An item's own figures; null when malformed.
EstimateItem? _itemFrom(Object? entry) {
  if (entry is! Map ||
      entry['item'] is! String ||
      (entry['item'] as String).trim().isEmpty ||
      entry['kcal'] is! num) {
    return null;
  }
  return EstimateItem(
    name: (entry['item'] as String).trim(),
    grams: switch (entry['grams']) {
      final num grams when grams > 0 => grams.round(),
      _ => null,
    },
    kcal: (entry['kcal'] as num).round(),
    protein: (entry['protein_g'] as num?)?.round(),
  );
}

EstimateItem _withOptions(EstimateItem item, Object? raw, Set<String> said) {
  if (raw is! List) return item;
  final kept = _words(item.name).intersection(said);
  final names = {item.name.toLowerCase()};
  final calories = [item.kcal];
  final options = <EstimateItem>[];
  for (final entry in raw) {
    final option = _itemFrom(entry);
    if (option == null ||
        calories.any((kcal) => (option.kcal - kcal).abs() < optionGap) ||
        !names.add(option.name.toLowerCase()) ||
        !_words(option.name).containsAll(kept)) {
      continue;
    }
    options.add(option);
    calories.add(option.kcal);
    if (options.length == 3) break;
  }
  if (options.isEmpty) return item;
  return EstimateItem(
    name: item.name,
    grams: item.grams,
    kcal: item.kcal,
    protein: item.protein,
    options: options,
  );
}

/// Reads the model's `macros` object, keeping non-negative numbers only.
/// None at all when saturates come out above fat or sugars above carbs,
/// which means the model mixed them up.
Nutrients? parseNutrients(Object? raw) {
  if (raw is! Map) return null;
  final values = [
    for (final key in ['fat', 'saturates', 'carbs', 'sugars', 'fibre', 'salt'])
      switch (raw[key]) {
        final num value when value >= 0 => value.toDouble(),
        _ => null,
      },
  ];
  final [fat, saturates, carbs, sugars, fibre, salt] = values;
  if (values.every((value) => value == null) ||
      (saturates ?? 0) > (fat ?? double.infinity) ||
      (sugars ?? 0) > (carbs ?? double.infinity)) {
    return null;
  }
  return Nutrients(
    fat: fat,
    saturates: saturates,
    carbs: carbs,
    sugars: sugars,
    fibre: fibre,
    salt: salt,
  );
}

/// [item] at [grams] instead of the AI's weight, its calories and protein
/// scaled to match, and settled. Unchanged when the AI gave no weight to
/// scale from.
EstimateItem resized(EstimateItem item, int grams) {
  final from = item.grams;
  if (from == null) return item;
  int scale(int value) => (value * grams / from).round();
  return EstimateItem(
    name: item.name,
    grams: grams,
    kcal: scale(item.kcal),
    protein: item.protein == null ? null : scale(item.protein!),
  );
}

/// The meal's figures from its items, for after a weight was changed.
({int kcal, int? protein}) totalOf(List<EstimateItem> items) {
  final proteins = items.map((item) => item.protein).nonNulls;
  return (
    kcal: items.fold(0, (sum, item) => sum + item.kcal),
    protein: proteins.isEmpty ? null : proteins.reduce((a, b) => a + b),
  );
}

class DailyLimitExceededException implements Exception {
  const DailyLimitExceededException();
}

class CalorieEstimateException implements Exception {
  const CalorieEstimateException(this.message);

  final String message;

  @override
  String toString() => 'CalorieEstimateException: $message';
}

/// Calls one of the AI's Cloud Functions (`functions/src/ai.ts`), which
/// counts the call, checks YumSum Star, asks Gemini and returns its JSON
/// reply. The prompts are there, never in the app. The phone's date goes
/// with every call, for the day's count.
Future<Map<String, dynamic>> callAi(
  FirebaseFunctions functions,
  String name,
  Map<String, Object?> data,
) async {
  await ensureAppCheck();
  final result = await functions.httpsCallable(name).call<Object?>({
    ...data,
    'dateKey': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  });
  return Map<String, dynamic>.from(result.data as Map);
}

/// What to tell the user when an AI call fails, in [l10n]'s language: the
/// server's code, and its `reason` where it gives one, else [fallback].
/// `resource-exhausted` is the day's allowance used up; the server answers
/// it before asking Gemini.
Exception aiCallError(Object error, String fallback, AppLocalizations l10n) {
  if (error is! FirebaseFunctionsException) {
    return CalorieEstimateException(fallback);
  }
  final reason = switch (error.details) {
    {'reason': final String reason} => reason,
    _ => null,
  };
  return switch ((error.code, reason)) {
    ('resource-exhausted', _) => const DailyLimitExceededException(),
    ('failed-precondition', 'off') => CalorieEstimateException(l10n.mealAiOff),
    ('failed-precondition', _) => CalorieEstimateException(l10n.mealAiPaused),
    ('unavailable', 'busy') => CalorieEstimateException(l10n.mealAiBusy),
    ('unavailable', 'transient') => CalorieEstimateException(
      l10n.mealAiBusyShort,
    ),
    // The app thought the account had YumSum Star; the server didn't.
    ('permission-denied', _) => CalorieEstimateException(l10n.mealAiNoStar),
    _ => CalorieEstimateException(fallback),
  };
}

class CalorieEstimateService {
  CalorieEstimateService(
    this._usageRepo,
    this._functions, {
    required String country,
    String language = 'en',
    int? dailyLimit = AiUsageRepository.dailyLimit,
    bool plus = false,
    AppLocalizations? l10n,
  }) : _country = country,
       _language = language,
       _dailyLimit = dailyLimit,
       _plus = plus,
       _l10n = l10n ?? lookupAppLocalizations(const Locale('en'));

  final AiUsageRepository _usageRepo;
  final FirebaseFunctions _functions;

  /// Estimates allowed a day; null for no limit (the owner's account).
  final int? _dailyLimit;

  /// Where the user lives (`countryProvider`).
  final String _country;

  /// The app's language ('en' or 'bg'), which the names come back in.
  final String _language;

  /// YumSum Star, whose estimates always come with macros. The server
  /// refuses macros to an account without it.
  final bool _plus;

  /// The language of the errors it throws: the app's (`l10nProvider`).
  final AppLocalizations _l10n;

  /// Asks `aiEstimate` for [kind] with the country, which the server's
  /// prompts open with.
  Future<Map<String, dynamic>> _ask(String kind, Map<String, Object?> data) =>
      callAi(_functions, 'aiEstimate', {
        'kind': kind,
        'country': _country,
        'language': _language,
        'macros': _plus,
        ...data,
      });

  /// Says the allowance is used up without a call. Only a shortcut: the
  /// server keeps the count and has the last word.
  Future<void> _checkAllowance(String uid) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _usageRepo.watchCount(uid, today).first;
    if (_dailyLimit case final limit? when count >= limit) {
      throw const DailyLimitExceededException();
    }
  }

  Future<CalorieEstimate> estimate(String uid, String description) async {
    await _checkAllowance(uid);

    try {
      final map = await _ask('meal', {'text': description.trim()});
      final kcal = (map['kcal'] as num).toInt();
      final protein = (map['protein_g'] as num?)?.round();

      return (
        kcal: kcal,
        protein: protein,
        macros: parseNutrients(map['macros']),
        items: parseEstimateItems(map['items'], said: description),
      );
    } catch (error, st) {
      debugPrint('CalorieEstimateService error: $error\n$st');
      throw aiCallError(error, _l10n.mealAiErrorEstimate, _l10n);
    }
  }

  /// Recognises the meal in a short WAV voice note, in English, Bulgarian
  /// or a mix; the model does the listening, so no language setting is
  /// needed. Counts towards the daily AI limit like [estimate].
  Future<VoiceMealParsed> parseVoiceAudio(String uid, Uint8List wav) async {
    await _checkAllowance(uid);

    try {
      final map = await _ask('voice', {'audio': base64Encode(wav)});
      if (map['error'] != null || map['kcal'] is! num) {
        throw CalorieEstimateException(_l10n.mealAiNoMeal);
      }
      return _mealFrom(map);
    } on CalorieEstimateException {
      rethrow;
    } catch (error, st) {
      debugPrint('CalorieEstimateService voice error: $error\n$st');
      throw aiCallError(error, _l10n.mealAiErrorVoice, _l10n);
    }
  }

  /// Recognises the meal in a JPEG photo. Counts towards the daily AI limit
  /// like [estimate].
  Future<VoiceMealParsed> estimateFromPhoto(String uid, Uint8List jpeg) async {
    await _checkAllowance(uid);

    try {
      final map = await _ask('photo', {'photo': base64Encode(jpeg)});
      if (map['error'] != null || map['kcal'] is! num) {
        throw CalorieEstimateException(_l10n.mealAiNoFood);
      }
      return _mealFrom(map);
    } on CalorieEstimateException {
      rethrow;
    } catch (error, st) {
      debugPrint('CalorieEstimateService photo error: $error\n$st');
      throw aiCallError(error, _l10n.mealAiErrorPhoto, _l10n);
    }
  }

  /// Reads a packet's nutrition table, and its front when given, for a
  /// contribution. Counts towards the daily AI limit like [estimate].
  Future<LabelReading> readLabel(
    String uid,
    Uint8List? front,
    Uint8List label,
  ) async {
    await _checkAllowance(uid);

    try {
      final map = await _ask('label', {
        if (front != null) 'front': base64Encode(front),
        'label': base64Encode(label),
      });
      if (map['error'] != null) {
        throw CalorieEstimateException(_l10n.mealAiNoLabel);
      }
      return parseLabelReading(map);
    } on CalorieEstimateException {
      rethrow;
    } catch (error, st) {
      debugPrint('CalorieEstimateService label error: $error\n$st');
      throw aiCallError(error, _l10n.contributeErrorRead, _l10n);
    }
  }

  /// Protein, and for YumSum Star the macros, for a meal logged by name and
  /// calories; null when the name says nothing about the food (e.g.
  /// "Lunch"). This doesn't count towards the daily AI limit: it costs a
  /// fraction of an estimate, comes with saving a meal, and counting it
  /// would use up the allowance unasked. The server caps it separately.
  Future<({int? protein, Nutrients? macros})> estimateNutrients(
    String name,
    int kcal,
  ) async {
    final map = await _ask('nutrients', {'name': name.trim(), 'kcal': kcal});
    return (
      protein: (map['protein_g'] as num?)?.round(),
      macros: parseNutrients(map['macros']),
    );
  }

  VoiceMealParsed _mealFrom(Map<String, dynamic> map) => (
    name: map['name'] as String,
    kcal: (map['kcal'] as num).toInt(),
    protein: (map['protein_g'] as num?)?.round(),
    macros: parseNutrients(map['macros']),
    items: parseEstimateItems(
      map['items'],
      said: switch (map['transcript']) {
        final String transcript => transcript,
        _ => '',
      },
    ),
  );
}
