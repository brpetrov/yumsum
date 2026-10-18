import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/repositories/ai_usage_repository.dart';

/// One component of a meal as the model broke it down.
typedef EstimateItem = ({String name, int kcal, int? protein});
typedef CalorieEstimate = ({
  int kcal,
  int? protein,
  String note,
  List<EstimateItem> items,
});

/// A meal recognised from a voice note or a photo.
typedef VoiceMealParsed = ({
  String name,
  int kcal,
  int? protein,
  List<EstimateItem> items,
});

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
          kcal: (entry['kcal'] as num).round(),
          protein: (entry['protein_g'] as num?)?.round(),
        ),
  ];
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
const aiQuotaUsedMessage =
    'The AI has reached its limit for today. Add the calories yourself, '
    'e.g. "wrap 450".';

/// What to tell the user for a server-side AI error, from its wording.
/// "Firebase AI Logic API has not been used in project … or it is disabled"
/// and quota errors arrive as plain server errors.
String aiErrorMessage(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('has not been used') ||
      lower.contains('is disabled') ||
      lower.contains('not enabled')) {
    return aiNotSwitchedOnMessage;
  }
  if (lower.contains('quota') ||
      lower.contains('429') ||
      lower.contains('resource_exhausted')) {
    return aiQuotaUsedMessage;
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
  // the app, and the project's quota and billing apply.
  GenerativeModel get _model => FirebaseAI.googleAI().generativeModel(
    model: _modelId,
    generationConfig: _generationConfig,
  );

  String get _context =>
      nutritionContext(country: _country, usualFood: _usualFood);

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
      'Respond with ONLY a JSON object: {"items": [{"item": "<component>", '
      '"kcal": <integer>, "protein_g": <integer>}], "kcal": <integer total>, '
      '"protein_g": <integer total>, "note": "<one short sentence explaining '
      'the estimate>"}\n'
      'Do not include any other text.\n\n'
      'Meal: {input}';

  String get _voicePromptTemplate =>
      '$_context'
      'The user recorded a voice note about a meal, in English, Bulgarian or '
      'a mix of both. Listen to it and extract a short meal name, the total '
      'calories and the total protein.\n'
      'List every component with its calories and protein. If the user stated '
      'a calorie or protein amount for something, use that exact number for '
      'it. Otherwise estimate it: use any amounts the user gives, assume a '
      'typical home portion if none, include the oil or fat home-cooked dishes '
      'are usually cooked with, and use $_country nutrition figures for branded or '
      'chain products. Then add them up.\n'
      'If the user gave calories but no protein, still estimate the protein '
      'from the food. Only if nothing in the note says what the food was '
      '(e.g. "400 calories for lunch"), set protein_g to null.\n'
      'If the recording contains no meal, respond with {"error": "no meal"}.\n'
      'Respond with ONLY a JSON object: {"transcript": "<what the user said>", '
      '"name": "<short meal name>", "items": [{"item": "<component>", "kcal": '
      '<integer>, "protein_g": <integer or null>}], "kcal": <integer total>, '
      '"protein_g": <integer total or null>}\n'
      'Do not include any other text.';

  String get _photoPromptTemplate =>
      '$_context'
      'The user sent a photo of a meal. Identify the dishes and estimate the '
      'portions from what is visible. List every component with its calories '
      'and protein, including visible oil, sauces, bread and drinks, then add '
      'them up. Use $_country nutrition figures for branded or chain products. If the '
      'photo shows no food, respond with {"error": "no food"}.\n'
      'Respond with ONLY a JSON object: {"name": "<short meal name>", '
      '"items": [{"item": "<component>", "kcal": <integer>, "protein_g": '
      '<integer>}], "kcal": <integer total>, "protein_g": <integer total>, '
      '"note": "<one short sentence explaining the estimate>"}\n'
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
      final note = map['note'] as String;

      await _usageRepo.increment(uid, today);
      return (
        kcal: kcal,
        protein: protein,
        note: note,
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
  /// needed. Doesn't count towards the daily AI limit (one call per note,
  /// as before).
  Future<VoiceMealParsed> parseVoiceAudio(Uint8List wav) async {
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
      return _mealFrom(map);
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

  /// Protein for a meal logged by name and calories, or null when the name
  /// says nothing about the food (e.g. "Lunch"). Like [parseVoice], this
  /// doesn't count towards the daily AI limit.
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
        return await model.generateContent(content);
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
    if (type == 'QuotaExceeded') return aiQuotaUsedMessage;
    return aiErrorMessage(error.message);
  }

  String _friendlyServerError(String message) => aiErrorMessage(message);
}
