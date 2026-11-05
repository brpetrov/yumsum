import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';

/// One component of an AI estimate; [grams] is the weight the AI assumed
/// (ml for drinks), null when it gave none.
typedef EstimateItem = ({String name, int? grams, int kcal, int? protein});

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

/// Reads the model's `items` list, skipping anything malformed.
List<EstimateItem> parseEstimateItems(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final entry in raw)
      if (entry is Map &&
          entry['item'] is String &&
          (entry['item'] as String).trim().isNotEmpty &&
          entry['kcal'] is num)
        (
          name: (entry['item'] as String).trim(),
          grams: switch (entry['grams']) {
            final num grams when grams > 0 => grams.round(),
            _ => null,
          },
          kcal: (entry['kcal'] as num).round(),
          protein: (entry['protein_g'] as num?)?.round(),
        ),
  ];
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
/// scaled to match. Unchanged when the AI gave no weight to scale from.
EstimateItem resized(EstimateItem item, int grams) {
  final from = item.grams;
  if (from == null) return item;
  int scale(int value) => (value * grams / from).round();
  return (
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

const aiNotSwitchedOnMessage = 'AI estimates aren\'t switched on yet.';
const aiBusyMessage = 'The AI is busy right now. Try again in a minute.';
const aiPausedMessage =
    'AI estimates are paused for now. You can still type the calories '
    'yourself.';

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
  final result = await functions.httpsCallable(name).call<Object?>({
    ...data,
    'dateKey': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  });
  return Map<String, dynamic>.from(result.data as Map);
}

/// What to tell the user when an AI call fails: the server's code, and its
/// `reason` where it gives one, else [fallback]. `resource-exhausted` is the
/// day's allowance used up; the server answers it before asking Gemini.
Exception aiCallError(Object error, String fallback) {
  if (error is! FirebaseFunctionsException) {
    return CalorieEstimateException(fallback);
  }
  final reason = switch (error.details) {
    {'reason': final String reason} => reason,
    _ => null,
  };
  return switch ((error.code, reason)) {
    ('resource-exhausted', _) => const DailyLimitExceededException(),
    ('failed-precondition', 'off') => const CalorieEstimateException(
      aiNotSwitchedOnMessage,
    ),
    ('failed-precondition', _) => const CalorieEstimateException(
      aiPausedMessage,
    ),
    ('unavailable', 'busy') => const CalorieEstimateException(aiBusyMessage),
    ('unavailable', 'transient') => const CalorieEstimateException(
      'The AI is busy. Try again in a few seconds.',
    ),
    // The app thought the account had YumSum Star; the server didn't.
    ('permission-denied', _) => const CalorieEstimateException(
      'YumSum Star isn\'t on for this account. Try again.',
    ),
    _ => CalorieEstimateException(fallback),
  };
}

class CalorieEstimateService {
  CalorieEstimateService(
    this._usageRepo,
    this._functions, {
    required String country,
    required String usualFood,
    int? dailyLimit = AiUsageRepository.dailyLimit,
    bool plus = false,
  }) : _country = country,
       _usualFood = usualFood,
       _dailyLimit = dailyLimit,
       _plus = plus;

  final AiUsageRepository _usageRepo;
  final FirebaseFunctions _functions;

  /// Estimates allowed a day; null for no limit (the owner's account).
  final int? _dailyLimit;

  /// From the profile: where the user lives and what they usually eat.
  final String _country;
  final String _usualFood;

  /// YumSum Star, whose estimates always come with macros. The server
  /// refuses macros to an account without it.
  final bool _plus;

  /// Asks `aiEstimate` for [kind] with the profile, which the server's
  /// prompts open with.
  Future<Map<String, dynamic>> _ask(String kind, Map<String, Object?> data) =>
      callAi(_functions, 'aiEstimate', {
        'kind': kind,
        'country': _country,
        'usualFood': _usualFood,
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
        items: parseEstimateItems(map['items']),
      );
    } catch (error, st) {
      debugPrint('CalorieEstimateService error: $error\n$st');
      throw aiCallError(error, 'Could not estimate calories. Try again.');
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
        throw const CalorieEstimateException(
          'Couldn\'t hear a meal in that. Tap the mic and try again.',
        );
      }
      return _mealFrom(map);
    } on CalorieEstimateException {
      rethrow;
    } catch (error, st) {
      debugPrint('CalorieEstimateService voice error: $error\n$st');
      throw aiCallError(
        error,
        'Could not understand the recording. Try again.',
      );
    }
  }

  /// Recognises the meal in a JPEG photo. Counts towards the daily AI limit
  /// like [estimate].
  Future<VoiceMealParsed> estimateFromPhoto(String uid, Uint8List jpeg) async {
    await _checkAllowance(uid);

    try {
      final map = await _ask('photo', {'photo': base64Encode(jpeg)});
      if (map['error'] != null || map['kcal'] is! num) {
        throw const CalorieEstimateException(
          'No food found in that photo. Try again with the plate in view.',
        );
      }
      return _mealFrom(map);
    } on CalorieEstimateException {
      rethrow;
    } catch (error, st) {
      debugPrint('CalorieEstimateService photo error: $error\n$st');
      throw aiCallError(error, 'Could not read that photo. Try again.');
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
        throw const CalorieEstimateException(
          'Those photos don\'t show a label. Fill in the details yourself.',
        );
      }
      return parseLabelReading(map);
    } on CalorieEstimateException {
      rethrow;
    } catch (error, st) {
      debugPrint('CalorieEstimateService label error: $error\n$st');
      throw aiCallError(
        error,
        'Could not read the label. Fill in the details yourself.',
      );
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
    items: parseEstimateItems(map['items']),
  );
}
