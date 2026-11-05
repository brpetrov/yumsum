import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// Raise whenever the instruction or the facts change: it is the first line
/// of each cached review's `basis`, so the notes are written again. The
/// instruction (plan 09) is `weeklyReviewInstruction` in
/// `functions/src/prompts.ts`, on the server with its response schema.
const weeklyReviewPromptVersion = 5;

/// The AI's answer had no note worth showing.
class WeeklyReviewException implements Exception {
  const WeeklyReviewException();

  @override
  String toString() => 'WeeklyReviewException: no usable notes';
}

// "Bad" isn't here, as "not bad" would trip it; the instruction covers it.
final _shaming = RegExp(
  r'\b(cheat|guilt|naughty|junk|sinful|failed|failure|lazy)',
  caseSensitive: false,
);
final _thousands = RegExp(r'(\d),(?=\d{3}(?!\d))');
final _number = RegExp(r'\d+(\.\d+)?');

Set<double> _numbersIn(String text) => {
  for (final match in _number.allMatches(
    text.replaceAllMapped(_thousands, (m) => m[1]!),
  ))
    double.parse(match[0]!),
};

/// The notes worth showing from the AI's `points`, at most 6, in order:
/// each a `{text, good}` (or a bare string, not good) whose text is
/// non-empty and at most 160 characters (140 asked for), with every number
/// in [facts] and no shaming word. Throws [WeeklyReviewException] when none
/// is left.
List<ReviewPoint> parseReviewPoints(Object? raw, {required String facts}) {
  final known = _numbersIn(facts);
  final points = [
    if (raw is List)
      for (final entry in raw)
        if (reviewPointFrom(entry) case final point?)
          if (point.text.trim() case final note
              when note.isNotEmpty &&
                  note.length <= 160 &&
                  _numbersIn(note).every(known.contains) &&
                  !_shaming.hasMatch(note))
            (text: note, good: point.good),
  ].take(6).toList();
  if (points.isEmpty) throw const WeeklyReviewException();
  return points;
}

/// Writes the AI Coach's notes from a week's facts, through the
/// `aiWeeklyReview` Cloud Function, which checks YumSum Star. It never
/// touches the daily AI allowance: it's one automatic call a week, not
/// something the user asks for each time. The server caps it at 10 a day.
class WeeklyReviewService {
  WeeklyReviewService([this._functions]);

  final FirebaseFunctions? _functions;

  Future<List<ReviewPoint>> write(String facts) async {
    try {
      final map = await callAi(
        _functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
        'aiWeeklyReview',
        {'facts': facts},
      );
      return parseReviewPoints(map['points'], facts: facts);
    } catch (error, st) {
      // The card says the same for every failure; the detail is here.
      debugPrint('WeeklyReviewService error: $error\n$st');
      rethrow;
    }
  }
}
