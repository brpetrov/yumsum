import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// Raise whenever the instruction or the facts change: it is the first line
/// of each new review's `basis`. Saved weeks keep their original notes. The
/// instruction (plan 09) is `weeklyReviewInstruction` in
/// `functions/src/prompts.ts`, on the server with its response schema.
const weeklyReviewPromptVersion = 10;

/// The AI's answer had no note worth showing.
class WeeklyReviewException implements Exception {
  const WeeklyReviewException();

  @override
  String toString() => 'WeeklyReviewException: no usable notes';
}

// "Bad" isn't here, as "not bad" would trip it; the instruction covers it.
// The Bulgarian words have no \b, which only knows Latin letters.
final _shaming = RegExp(
  r'\b(cheat|guilt|naughty|junk|sinful|failed|failure|lazy)'
  r'|провал|виновн|мързел|боклук|боклучав',
  caseSensitive: false,
);
final _thousands = RegExp(r'(\d),(?=\d{3}(?!\d))');
// Bulgarian notes write 1850 or 10 000, and 7,4 for the facts' 7.4.
final _spacedThousands = RegExp(r'(\d)[ \u00A0](?=\d{3}(?!\d))');
final _decimalComma = RegExp(r'(\d),(?=\d)');
final _number = RegExp(r'\d+(\.\d+)?');

Set<double> _numbersIn(String text) => {
  for (final match in _number.allMatches(
    text
        .replaceAllMapped(_thousands, (m) => m[1]!)
        .replaceAllMapped(_spacedThousands, (m) => m[1]!)
        .replaceAllMapped(_decimalComma, (m) => '${m[1]}.'),
  ))
    double.parse(match[0]!),
};

/// The notes worth showing from the AI's `points`, at most 8, in order:
/// each a `{title, text, good}` (or a bare string, untitled and not good)
/// whose text is non-empty and at most 600 characters (220 asked for) and
/// whose title is at most 80 (40 asked for), with every number in [facts]
/// and no shaming word in either. The `why` (at most 300) and each of the
/// `tips` (at most 200, 3 kept) are held to the same and dropped on their
/// own; `recipes` are kept as named, 3 at most. Throws
/// [WeeklyReviewException] when no note is left.
List<ReviewPoint> parseReviewPoints(Object? raw, {required String facts}) {
  final known = _numbersIn(facts);
  bool fine(String note, int max) =>
      note.length <= max &&
      _numbersIn(note).every(known.contains) &&
      !_shaming.hasMatch(note);
  List<String> kept(List<String> lines, int max) => [
    for (final line in lines)
      if (line.trim() case final line when line.isNotEmpty && fine(line, max))
        line,
  ].take(3).toList();
  final points = [
    if (raw is List)
      for (final entry in raw)
        if (reviewPointFrom(entry) case final point?)
          if ((point.title.trim(), point.text.trim()) case (
            final title,
            final note,
          ) when note.isNotEmpty && fine(note, 600) && fine(title, 80))
            ReviewPoint(
              title: title,
              text: note,
              good: point.good,
              why: fine(point.why.trim(), 300) ? point.why.trim() : '',
              tips: kept(point.tips, 200),
              recipes: [
                for (final name in point.recipes)
                  if (name.trim().isNotEmpty) name.trim(),
              ].take(3).toList(),
            ),
  ].take(8).toList();
  if (points.isEmpty) throw const WeeklyReviewException();
  return points;
}

/// Writes the AI Coach's notes from a week's facts, through the
/// `aiWeeklyReview` Cloud Function, which checks YumSum Star. It never
/// touches the daily AI allowance: it's one automatic call a week, not
/// something the user asks for each time. The server caps it at 10 a day.
/// The notes are written in [_language], the app's ('en' or 'bg').
class WeeklyReviewService {
  WeeklyReviewService([this._functions, this._language = 'en']);

  final FirebaseFunctions? _functions;
  final String _language;

  Future<List<ReviewPoint>> write(String facts) async {
    try {
      final map = await callAi(
        _functions ?? FirebaseFunctions.instanceFor(region: 'europe-west10'),
        'aiWeeklyReview',
        {'facts': facts, 'language': _language},
      );
      return parseReviewPoints(map['points'], facts: facts);
    } catch (error, st) {
      // The page says the same for every failure; the detail is here.
      debugPrint('WeeklyReviewService error: $error\n$st');
      rethrow;
    }
  }
}
