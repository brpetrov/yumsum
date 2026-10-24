import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/core/config/app_check.dart';

import 'package:lean_streak/repositories/ai_usage_repository.dart';

/// One component of an AI estimate; [grams] is the weight the AI assumed
/// (ml for drinks), null when it gave none.
typedef EstimateItem = ({String name, int? grams, int kcal, int? protein});
typedef CalorieEstimate = ({int kcal, int? protein, List<EstimateItem> items});

/// A meal recognised from a voice note or a photo.
typedef VoiceMealParsed = ({
  String name,
  int kcal,
  int? protein,
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

/// The opening of every prompt: where the user lives and what they usually
/// eat, so dish names and portions are read the way they mean them.
String nutritionContext({required String country, required String usualFood}) {
  final food = usualFood.trim();
  return 'You are a nutrition assistant. The user lives in $country'
      '${food.isEmpty ? '' : ' and often eats $food'}. Read dish names the '
      'way they are used there: the same name can mean a different dish in '
      'different cuisines. The user may write in English or their own '
      'language; write the meal name and item names in the language they '
      'used.\n';
}

const aiNotSwitchedOnMessage =
    'AI estimates are not switched on for this app yet.';
const aiBusyMessage = 'The AI is busy right now. Try again in a minute.';
const aiPausedMessage =
    'AI estimates are paused for now. You can still type the calories '
    'yourself.';

/// What to tell the user for a server-side AI error, from its wording.
/// "Firebase AI Logic API has not been used in project … or it is disabled"
/// and quota errors arrive as plain server errors. On the paid tier a
/// quota error is a per-minute limit, and an empty prepaid balance (402)
/// stops every call until it is topped up.
String aiErrorMessage(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('has not been used') ||
      lower.contains('is disabled') ||
      lower.contains('not enabled')) {
    return aiNotSwitchedOnMessage;
  }
  if (lower.contains('402') ||
      lower.contains('payment') ||
      lower.contains('prepay') ||
      lower.contains('credit') ||
      lower.contains('billing')) {
    return aiPausedMessage;
  }
  if (lower.contains('quota') ||
      lower.contains('429') ||
      lower.contains('resource_exhausted')) {
    return aiBusyMessage;
  }
  if (isTransientAiError(message)) {
    return 'The AI estimate service is busy right now. Try again in a few '
        'seconds.';
  }
  return 'Could not estimate calories right now.';
}

bool isTransientAiError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('503') ||
      lower.contains('500') ||
      lower.contains('unavailable') ||
      lower.contains('high demand') ||
      lower.contains('overloaded') ||
      lower.contains('timed out');
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

class CalorieEstimateService {
  CalorieEstimateService(
    this._usageRepo, {
    required String country,
    required String usualFood,
  }) : _country = country,
       _usualFood = usualFood;

  final AiUsageRepository _usageRepo;

  /// From the profile: where the user lives and what they usually eat.
  final String _country;
  final String _usualFood;

  static const String _modelId = 'gemini-3.5-flash-lite';
  static const int _maxServerRetries = 3;
  static final _generationConfig = GenerationConfig(
    responseMimeType: 'application/json',
  );

  // Through Firebase AI Logic (Gemini Developer API backend): no API key in
  // the app, and the project's quota and billing apply. The App Check token
  // proves the call comes from this app (enforced in the Firebase console).
  GenerativeModel get _model => FirebaseAI.googleAI(
    appCheck: appCheckAvailable ? FirebaseAppCheck.instance : null,
  ).generativeModel(model: _modelId, generationConfig: _generationConfig);

  String get _context =>
      nutritionContext(country: _country, usualFood: _usualFood);

  // The weights let the user correct a portion in the app without asking
  // the AI again.
  static const _weights =
      'Give each component\'s weight in grams (ml for drinks), and for '
      'meat, fish, rice and pasta say in the item whether that weight is '
      'cooked or raw.\n';

  // Listing each component before the total stops the model skipping the
  // oil, butter or gravy.
  String get _promptTemplate =>
      '$_context'
      'The user will describe a meal. List every component with its calories '
      'and protein, including cooking oil, butter, gravy, sauces, bread and '
      'drinks if mentioned. Use any amounts the user gives; otherwise assume a '
      'typical home portion. For home-cooked dishes, include the oil or fat '
      'they are usually cooked with. For branded or chain products use $_country '
      'nutrition figures. Then add them up.\n'
      '$_weights'
      'Respond with ONLY a JSON object: {"items": [{"item": "<component>", "grams": <integer>, '
      '"kcal": <integer>, "protein_g": <integer>}], "kcal": <integer total>, '
      '"protein_g": <integer total>}\n'
      'Do not include any other text.\n\n'
      'Meal: {input}';

  String get _voicePromptTemplate =>
      '$_context'
      'The user recorded a voice note about a meal, in English, Bulgarian or '
      'a mix of both. Listen to it and extract a short meal name, the total '
      'calories and the total protein. Keep any count or amount the user '
      'said in the name, e.g. "500 г мусака" or "3 пилешки филета", so the '
      'name says what the figures are for.\n'
      'List every component with its calories and protein. If the user stated '
      'a calorie or protein amount for something, use that exact number for '
      'it. Otherwise estimate it: use any amounts the user gives, assume a '
      'typical home portion if none, include the oil or fat home-cooked dishes '
      'are usually cooked with, and use $_country nutrition figures for branded or '
      'chain products. Then add them up.\n'
      'If the user gave calories but no protein, still estimate the protein '
      'from the food. Only if nothing in the note says what the food was '
      '(e.g. "400 calories for lunch"), set protein_g to null.\n'
      '$_weights'
      'If the recording contains no meal, respond with {"error": "no meal"}.\n'
      'Respond with ONLY a JSON object: {"transcript": "<what the user said>", '
      '"name": "<short meal name>", "items": [{"item": "<component>", "grams": <integer>, "kcal": '
      '<integer>, "protein_g": <integer or null>}], "kcal": <integer total>, '
      '"protein_g": <integer total or null>}\n'
      'Do not include any other text.';

  String get _photoPromptTemplate =>
      '$_context'
      'The user sent a photo of a meal. Identify the dishes and estimate the '
      'portions from what is visible. List every component with its calories '
      'and protein, including visible oil, sauces, bread and drinks, then add '
      'them up. Use $_country nutrition figures for branded or chain products. If the '
      'photo shows a packet rather than a plate, estimate one typical serving of '
      'that product, using its label figures if they can be read. If the '
      'photo shows no food, respond with {"error": "no food"}.\n'
      '$_weights'
      'Respond with ONLY a JSON object: {"name": "<short meal name>", '
      '"items": [{"item": "<component>", "grams": <integer>, "kcal": <integer>, "protein_g": '
      '<integer>}], "kcal": <integer total>, "protein_g": <integer total>}\n'
      'Do not include any other text.';

  // Contributed data is public, so the model must copy, not estimate.
  String get _labelPromptTemplate =>
      'The user photographed a food packet to add it to Open Food Facts: the '
      'first image is the front of the pack, the second the nutrition table. '
      'Copy what is printed; never guess or estimate. Use the per 100 g (or '
      'per 100 ml) column. If the table only gives figures per serving and '
      'states the serving size, convert them to per 100 g. If energy is only '
      'given in kJ, convert it to kcal by dividing by 4.184. Use null for '
      'anything the photos do not show. If the images do not show a food '
      'packet, respond with {"error": "no packet"}.\n'
      'Respond with ONLY a JSON object: {"name": "<product name as printed '
      'on the front, in the language printed, without the brand>", "lang": '
      '"<two-letter ISO 639-1 code of the language that name is in, e.g. en '
      'or bg>", "brand": '
      '"<brand or null>", "quantity": "<net quantity as printed, e.g. 400 g, '
      'or null>", "serving_size": "<serving size as printed, e.g. 30 g, or '
      'null>", "per_100g": {"energy-kcal": <number or null>, "proteins": '
      '<number or null>, "fat": <number or null>, "saturated-fat": <number '
      'or null>, "carbohydrates": <number or null>, "sugars": <number or '
      'null>, "fiber": <number or null>, "salt": <number or null>}}\n'
      'Do not include any other text.';

  String get _proteinPromptTemplate =>
      '$_context'
      'The user logged a meal by name with its calories. Assuming the '
      'calories are right, estimate how many grams of protein it contains.\n'
      'If the name gives no clue what the food was (e.g. "Lunch" or "Snack"), '
      'return null.\n'
      'Respond with ONLY a JSON object: {"protein_g": <integer or null>}\n'
      'Do not include any other text.\n\n'
      'Meal: {name}\nCalories: {kcal}';

  Future<CalorieEstimate> estimate(String uid, String description) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _usageRepo.watchCount(uid, today).first;
    if (count >= AiUsageRepository.dailyLimit) {
      throw const DailyLimitExceededException();
    }

    try {
      final prompt = _promptTemplate.replaceFirst(
        '{input}',
        description.trim(),
      );
      final map = _decode(
        await _generateWithRetries(_model, [Content.text(prompt)]),
      );
      final kcal = (map['kcal'] as num).toInt();
      final protein = (map['protein_g'] as num?)?.round();

      await _usageRepo.increment(uid, today);
      return (
        kcal: kcal,
        protein: protein,
        items: parseEstimateItems(map['items']),
      );
    } on DailyLimitExceededException {
      rethrow;
    } on CalorieEstimateException {
      rethrow;
    } on ServerException catch (error, st) {
      debugPrint('CalorieEstimateService server error: $error\n$st');
      throw CalorieEstimateException(_friendlyServerError(error.message));
    } catch (error, st) {
      debugPrint('CalorieEstimateService error: $error\n$st');
      throw CalorieEstimateException('Could not estimate calories right now.');
    }
  }

  /// Recognises the meal in a short WAV voice note, in English, Bulgarian
  /// or a mix; the model does the listening, so no language setting is
  /// needed. Counts towards the daily AI limit like [estimate].
  Future<VoiceMealParsed> parseVoiceAudio(String uid, Uint8List wav) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _usageRepo.watchCount(uid, today).first;
    if (count >= AiUsageRepository.dailyLimit) {
      throw const DailyLimitExceededException();
    }

    try {
      final map = _decode(
        await _generateWithRetries(_model, [
          Content.multi([
            TextPart(_voicePromptTemplate),
            InlineDataPart('audio/wav', wav),
          ]),
        ]),
      );
      if (map['error'] != null || map['kcal'] is! num) {
        throw const CalorieEstimateException(
          'Couldn\'t hear a meal in that. Tap the mic and try again.',
        );
      }
      final meal = _mealFrom(map);
      await _usageRepo.increment(uid, today);
      return meal;
    } on DailyLimitExceededException {
      rethrow;
    } on CalorieEstimateException {
      rethrow;
    } on ServerException catch (error, st) {
      debugPrint('CalorieEstimateService voice error: $error\n$st');
      throw CalorieEstimateException(_friendlyServerError(error.message));
    } catch (error, st) {
      debugPrint('CalorieEstimateService voice error: $error\n$st');
      throw const CalorieEstimateException(
        'Could not process voice input right now.',
      );
    }
  }

  /// Recognises the meal in a JPEG photo. Counts towards the daily AI limit
  /// like [estimate].
  Future<VoiceMealParsed> estimateFromPhoto(String uid, Uint8List jpeg) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _usageRepo.watchCount(uid, today).first;
    if (count >= AiUsageRepository.dailyLimit) {
      throw const DailyLimitExceededException();
    }

    try {
      final map = _decode(
        await _generateWithRetries(_model, [
          Content.multi([
            TextPart(_photoPromptTemplate),
            InlineDataPart('image/jpeg', jpeg),
          ]),
        ]),
      );
      if (map['error'] != null || map['kcal'] is! num) {
        throw const CalorieEstimateException(
          'No food found in that photo. Try again with the plate in view.',
        );
      }
      final meal = _mealFrom(map);
      await _usageRepo.increment(uid, today);
      return meal;
    } on DailyLimitExceededException {
      rethrow;
    } on CalorieEstimateException {
      rethrow;
    } on ServerException catch (error, st) {
      debugPrint('CalorieEstimateService photo error: $error\n$st');
      throw CalorieEstimateException(_friendlyServerError(error.message));
    } catch (error, st) {
      debugPrint('CalorieEstimateService photo error: $error\n$st');
      throw const CalorieEstimateException(
        'Could not read that photo right now.',
      );
    }
  }

  /// Reads a packet's front and nutrition table for a contribution. Counts
  /// towards the daily AI limit like [estimate].
  Future<LabelReading> readLabel(
    String uid,
    Uint8List front,
    Uint8List label,
  ) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _usageRepo.watchCount(uid, today).first;
    if (count >= AiUsageRepository.dailyLimit) {
      throw const DailyLimitExceededException();
    }

    try {
      final map = _decode(
        await _generateWithRetries(_model, [
          Content.multi([
            TextPart(_labelPromptTemplate),
            InlineDataPart('image/jpeg', front),
            InlineDataPart('image/jpeg', label),
          ]),
        ]),
      );
      if (map['error'] != null) {
        throw const CalorieEstimateException(
          'Those photos don\'t show a packet\'s label. Fill in the details '
          'from the packet yourself.',
        );
      }
      final reading = parseLabelReading(map);
      await _usageRepo.increment(uid, today);
      return reading;
    } on CalorieEstimateException {
      rethrow;
    } on ServerException catch (error, st) {
      debugPrint('CalorieEstimateService label error: $error\n$st');
      throw CalorieEstimateException(_friendlyServerError(error.message));
    } catch (error, st) {
      debugPrint('CalorieEstimateService label error: $error\n$st');
      throw const CalorieEstimateException(
        'Could not read the label right now. Fill in the details yourself.',
      );
    }
  }

  /// Protein for a meal logged by name and calories, or null when the name
  /// says nothing about the food (e.g. "Lunch"). This doesn't count towards
  /// the daily AI limit: it costs a fraction of an estimate, comes with
  /// saving a meal, and counting it would use up the allowance unasked.
  Future<int?> estimateProtein(String name, int kcal) async {
    final prompt = _proteinPromptTemplate
        .replaceFirst('{name}', name.trim())
        .replaceFirst('{kcal}', '$kcal');
    final map = _decode(
      await _generateWithRetries(_model, [Content.text(prompt)]),
    );
    return (map['protein_g'] as num?)?.round();
  }

  VoiceMealParsed _mealFrom(Map<String, dynamic> map) => (
    name: map['name'] as String,
    kcal: (map['kcal'] as num).toInt(),
    protein: (map['protein_g'] as num?)?.round(),
    items: parseEstimateItems(map['items']),
  );

  /// The model's JSON reply as a map; code fences are stripped just in case.
  Map<String, dynamic> _decode(GenerateContentResponse response) {
    final raw = response.text?.trim() ?? '';
    if (raw.isEmpty) {
      throw const CalorieEstimateException('Empty response from model.');
    }
    final jsonStr = raw
        .replaceAll(RegExp(r'```(?:json)?\s*'), '')
        .replaceAll('```', '')
        .trim();
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<GenerateContentResponse> _generateWithRetries(
    GenerativeModel model,
    List<Content> content,
  ) async {
    for (var attempt = 1; attempt <= _maxServerRetries; attempt++) {
      try {
        final response = await model.generateContent(content);
        // Token use is what the AI costs; logged to check the estimates.
        final usage = response.usageMetadata;
        debugPrint(
          'AI tokens: in ${usage?.promptTokenCount}, '
          'out ${usage?.candidatesTokenCount}, '
          'thinking ${usage?.thoughtsTokenCount}',
        );
        return response;
      } on ServerException catch (error) {
        if (!_isTransientServerError(error.message) ||
            attempt == _maxServerRetries) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      } on FirebaseAIException catch (error) {
        // Quota, API not enabled, bad key, unsupported location: none of
        // these clear up on retry, so say what it is.
        throw CalorieEstimateException(_firebaseAiMessage(error));
      } on SocketException {
        if (attempt == _maxServerRetries) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      }
    }

    throw const CalorieEstimateException('Could not reach the AI service.');
  }

  bool _isTransientServerError(String message) => isTransientAiError(message);

  /// The package doesn't export its quota / not-enabled exception types, so
  /// they are told apart by name, or by the server's wording.
  String _firebaseAiMessage(FirebaseAIException error) {
    final type = error.runtimeType.toString();
    if (type == 'ServiceApiNotEnabled' || error is InvalidApiKey) {
      return aiNotSwitchedOnMessage;
    }
    // Quota errors (QuotaExceeded) are told apart by their wording, which
    // also separates an empty prepaid balance from a busy minute.
    return aiErrorMessage(error.message);
  }

  String _friendlyServerError(String message) => aiErrorMessage(message);
}
