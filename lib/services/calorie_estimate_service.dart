import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/config/app_check.dart';
import 'package:lean_streak/core/config/crash_reports.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';

/// One component of an AI estimate; [grams] is the weight the AI assumed
/// (ml for drinks), null when it gave none. Where the user left out what
/// swings the calories, the AI went with the usual version and offers the
/// others, as chips in `EstimateBreakdown`: [amounts], other amounts of it, with
/// [amount] the one it went with ("5 pieces"; null when it didn't say,
/// shown as Regular), and [options], the other
/// likely kinds (the milk, takeaway or homemade), complete items at the
/// same amount, with [assumed] the kind it went with in a few words ("with
/// meat", "homemade"; null when it didn't say, shown as the item's name).
/// Empty, and [amount] and [assumed] null, when there's nothing to ask.
class EstimateItem {
  const EstimateItem({
    required this.name,
    this.grams,
    required this.kcal,
    this.protein,
    this.amount,
    this.amounts = const [],
    this.assumed,
    this.options = const [],
  });

  final String name;
  final int? grams;
  final int kcal;
  final int? protein;
  final String? amount;
  final List<EstimateAmount> amounts;
  final String? assumed;
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
      other.amount == amount &&
      listEquals(other.amounts, amounts) &&
      other.assumed == assumed &&
      listEquals(other.options, options);

  @override
  int get hashCode => Object.hash(
    name,
    grams,
    kcal,
    protein,
    amount,
    Object.hashAll(amounts),
    assumed,
    Object.hashAll(options),
  );

  @override
  String toString() => 'EstimateItem($name, $kcal kcal)';
}

/// Another amount the AI offers for an item: a few words and the grams of
/// the whole item at that amount, for `EstimateBreakdown`'s chips.
typedef EstimateAmount = ({String label, int grams});

/// An option closer than this to the item's calories isn't worth asking
/// about.
const optionGap = 30;

/// The least an amount or kind row must be able to move an item's
/// calories to be worth a question: a third of them, and at least 80 kcal.
/// Below that the row is dropped, whatever the model offered (10 November
/// 2026: a large cappuccino or sugar in tea isn't worth asking).
int askBarFor(int kcal) => max(80, (kcal * 0.3).round());

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
/// amounts and options are each kept at most 3, at least [optionGap]
/// kcal from the item (amounts also from each other), under new labels and names:
/// the AI is told to offer them rarely, and this catches it asking about
/// nothing, or arguing with the user. Options keep every word of the item's
/// name the user [said] (no soy latte for a large oat latte) and add a word
/// of their own beside sizes and numbers (no "Pizza" for "Medium pizza"),
/// and there are
/// no amounts when theirs repeat a number or size the user said ("5
/// meatballs", "two eggs", "a pint", "large", "a handful"). Each row has
/// at most 3 besides the ticked one.
List<EstimateItem> parseEstimateItems(Object? raw, {String said = ''}) {
  if (raw is! List) return const [];
  final saidWords = _words(said);
  final heard = _tokens(said);
  return [
    for (final entry in raw)
      if (_itemFrom(entry) case final item?)
        _withOptions(
          _withAmounts(item, entry as Map, said, heard),
          entry,
          saidWords,
        ),
  ];
}

/// The words of an amount that say how much, beside its numbers: when the
/// AI's amounts repeat one the user said, the user gave the amount. Not the
/// food's name ("5 сърми" for "сърми") or a vague measure ("a bowl").
const _sizeWords = {
  'small', 'medium', 'regular', 'large', 'big', 'half', 'quarter', 'whole',
  'double', 'single', 'pint', 'pints', 'short', 'tall', 'grande', 'venti', //
  'малка', 'малък', 'средна', 'среден', 'средно', 'голяма', 'голям', 'голямо',
  'половин', 'половинка', 'цяла', 'цял', 'цяло', 'двойна', 'двоен', 'двойно',
};

/// "a fried egg" is one egg: the user's "a" or "an" (Bulgarian "един",
/// "една", "едно") before a food, where the AI assumed one of it. Not where
/// the AI's amount is a vague measure ("1 bowl" for "a bowl of soup"),
/// which is still asked.
final _oneArticle = RegExp(
  r'(^|\s)(a|an|един|една|едно)\s',
  caseSensitive: false,
);
final _oneAssumed = RegExp(
  r'^(1|one|един|една|едно)\b(?!\s*(bowl|plate|handful|portion|serving|cup|glass|купа|купичка|чиния|шепа|порция|чаша))',
  caseSensitive: false,
);

/// The numbers of any length in [text], and its words of three letters or
/// more when [sizesOnly] is false, else only its [_sizeWords], in lower case.

/// Number words read as their digits ("two eggs" is "2 eggs").
Set<String> _tokens(String text, {bool sizesOnly = false}) => {
  for (final word in text.toLowerCase().split(
    RegExp(r'[^\p{L}\p{N}]+', unicode: true),
  ))
    if (_numberWords[word] ?? word case final token
        when RegExp(r'^\p{N}+$', unicode: true).hasMatch(token) ||
            (sizesOnly ? _sizeWords.contains(token) : token.length > 2))
      token,
};

const _numberWords = {
  'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5', //
  'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10',
  'eleven': '11', 'twelve': '12', 'един': '1', 'една': '1', 'едно': '1',
  'два': '2', 'две': '2', 'три': '3', 'четири': '4', 'пет': '5',
  'шест': '6', 'седем': '7', 'осем': '8', 'девет': '9', 'десет': '10',
};

/// [item] with what's left to ask in place of its own.
EstimateItem _asking(
  EstimateItem item, {
  String? amount,
  List<EstimateAmount> amounts = const [],
  String? assumed,
  List<EstimateItem> options = const [],
}) => EstimateItem(
  name: item.name,
  grams: item.grams,
  kcal: item.kcal,
  protein: item.protein,
  amount: amount,
  amounts: amounts,
  assumed: assumed,
  options: options,
);

/// One item whose amount is one: a sandwich is never "regular, small or
/// large", whatever the model offers (the prompt says so too; it still did
/// in 2 of 12 eval runs on 10 November 2026). What's in it is a kind.
final _singleItem = RegExp(
  r'(^|[^\p{L}])(sandwich|toastie|panini|burger|wrap|bagel|сандвич|бургер|дюнер|тост)',
  caseSensitive: false,
  unicode: true,
);

/// "A handful" is an amount the user gave: one usual handful. Offering
/// "14 g" or "42 g" beside it means nothing to anyone (10 November 2026).
final _handful = RegExp(r'handful|шепа', caseSensitive: false);

/// A weight or volume the user typed ("100 g", "330ml", "200 гр"): the
/// amount is given, whatever size words the AI offers.
final _measure = RegExp(
  r'\d\s*(g|kg|ml|l|гр|г|кг|мл|л)(?![\p{L}])',
  caseSensitive: false,
  unicode: true,
);

/// The other amounts the AI offers, by grams, which need the item's own
/// weight to scale from.
EstimateItem _withAmounts(
  EstimateItem item,
  Map entry,
  String said,
  Set<String> heard,
) {
  final from = item.grams;
  final amount = switch (entry['amount']) {
    final String words => words.trim(),
    _ => '',
  };
  final raw = entry['amounts'];
  if (from == null || raw is! List) return item;
  final theirs = [
    amount,
    for (final other in raw)
      if (other case {'amount': final String label}) label,
  ];
  if (_tokens(theirs.join(' '), sizesOnly: true).any(heard.contains)) {
    return item;
  }
  if (_oneArticle.hasMatch(said) && _oneAssumed.hasMatch(amount)) return item;
  if (_singleItem.hasMatch(item.name) ||
      _handful.hasMatch(said) ||
      _measure.hasMatch(said)) {
    return item;
  }
  final labels = {amount.toLowerCase()};
  final calories = [item.kcal];
  final amounts = <EstimateAmount>[];
  for (final entry in raw) {
    if (entry is! Map || entry['amount'] is! String || entry['grams'] is! num) {
      continue;
    }
    final label = (entry['amount'] as String).trim();
    final grams = (entry['grams'] as num).round();
    final kcal = (item.kcal * grams / from).round();
    if (label.isEmpty ||
        grams <= 0 ||
        grams == from ||
        calories.any((other) => (kcal - other).abs() < optionGap) ||
        !labels.add(label.toLowerCase())) {
      continue;
    }
    amounts.add((label: label, grams: grams));
    calories.add(kcal);
    if (amounts.length == 3) break;
  }
  if (amounts.isEmpty || !_worthAsking(item.kcal, calories)) return item;
  return _asking(
    item,
    amount: amount.isEmpty ? null : amount,
    amounts: amounts,
  );
}

/// Whether a row's [calories] (the item's own among them) span
/// [askBarFor], lowest to highest: small to large, so a regular portion
/// in the middle is asked every time, not only when large comes out big.
bool _worthAsking(int kcal, List<int> calories) =>
    calories.reduce(max) - calories.reduce(min) >= askBarFor(kcal);

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

/// The words that make an option only another amount, or filler, not
/// another kind: "Pizza" for "Medium pizza", "2 slices from a small 10 inch
/// pizza" for "Pizza" (10 November 2026). Not "whole", which is a milk.
const _amountWords = {
  'small', 'medium', 'regular', 'large', 'big', 'slice', 'slices', //
  'piece', 'pieces', 'portion', 'portions', 'half', 'quarter', 'double',
  'single', 'inch', 'inches', 'from', 'the', 'and', 'малка', 'малък',
  'малко', 'средна', 'среден', 'средно', 'голяма', 'голям', 'голямо',
  'парче', 'парчета', 'филия', 'филии', 'порция', 'порции', 'половин',
};

/// Whether [option] names a word that [item] doesn't, beside numbers and
/// [_amountWords]: another kind, not the same food in other words.
bool _anotherKind(EstimateItem item, EstimateItem option) =>
    _tokens(option.name)
        .difference(_tokens(item.name))
        .any(
          (word) =>
              !RegExp(r'^\p{N}+$', unicode: true).hasMatch(word) &&
              !_amountWords.contains(word),
        );

EstimateItem _withOptions(EstimateItem item, Map entry, Set<String> said) {
  final raw = entry['options'];
  if (raw is! List) return item;
  final kept = _words(item.name).intersection(said);
  final names = {item.name.toLowerCase()};
  final calories = [item.kcal];
  final options = <EstimateItem>[];
  for (final entry in raw) {
    final option = _itemFrom(entry);
    if (option == null ||
        !_anotherKind(item, option) ||
        (option.kcal - item.kcal).abs() < optionGap ||
        !names.add(option.name.toLowerCase()) ||
        !_words(option.name).containsAll(kept)) {
      continue;
    }
    options.add(option);
    calories.add(option.kcal);
    if (options.length == 3) break;
  }
  if (options.isEmpty || !_worthAsking(item.kcal, calories)) return item;
  return _asking(
    item,
    amount: item.amount,
    amounts: item.amounts,
    assumed: switch (entry['assumed']) {
      final String words when words.trim().isNotEmpty => words.trim(),
      _ => null,
    },
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

/// [item] as the user answered: [kind] is one of its options (null keeps
/// the item's own), [grams] one of its amounts' grams (null keeps the
/// item's). A kind at a different weight is scaled in the same ratio.
EstimateItem answered(EstimateItem item, {EstimateItem? kind, int? grams}) {
  final base = (kind ?? item).settled;
  final from = item.grams;
  if (grams == null || from == null) return base;
  final weight = base.grams ?? from;
  return resized(
    EstimateItem(
      name: base.name,
      grams: weight,
      kcal: base.kcal,
      protein: base.protein,
    ),
    (weight * grams / from).round(),
  );
}

/// Words that say nothing on their own, so a chip of only these shows the
/// option's whole name.
const _filler = {
  'with', 'without', 'and', 'or', 'of', 'in', 'on', 'a', 'an', 'the', //
  'from', 'с', 'със', 'без', 'и', 'или', 'на', 'в', 'във', 'от', 'за',
};

/// What [option]'s chip says: only what sets it apart from [item], the
/// words both names start and end with left out ("Takeaway" beside
/// "chicken curry with rice"). Where it swaps words inside the name, the
/// words after the swap stay, so it reads on its own ("whole milk" beside
/// "cappuccino with semi-skimmed milk", "without meat" beside "sarmi with
/// meat"). Case and punctuation don't count. The option's whole name when
/// nothing but filler would be left.
String choiceLabel(EstimateItem item, EstimateItem option) {
  final word = RegExp(r'[\p{L}\p{N}]+', unicode: true);
  final theirs = word.allMatches(option.name).toList();
  final ours = [
    for (final match in word.allMatches(item.name)) match[0]!.toLowerCase(),
  ];
  String theirWord(int index) => theirs[index][0]!.toLowerCase();
  var start = 0;
  while (start < theirs.length &&
      start < ours.length &&
      theirWord(start) == ours[start]) {
    start++;
  }
  var end = theirs.length;
  var ourEnd = ours.length;
  while (end > start &&
      ourEnd > start &&
      theirWord(end - 1) == ours[ourEnd - 1]) {
    end--;
    ourEnd--;
  }
  // A swap inside the name keeps the words after it.
  if (start > 0 && ourEnd > start) end = theirs.length;
  final real = RegExp(r'\p{L}', unicode: true);
  final says = [
    for (var index = start; index < end; index++) theirWord(index),
  ].any((word) => real.hasMatch(word) && !_filler.contains(word));
  if (!says) return option.name;
  return option.name.substring(theirs[start].start, theirs[end - 1].end);
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
  /// prompts open with, and the hour where the user is: "eggs" at 8 is a
  /// breakfast, "toast" at 23 a slice.
  Future<Map<String, dynamic>> _ask(String kind, Map<String, Object?> data) =>
      callAi(_functions, 'aiEstimate', {
        'kind': kind,
        'country': _country,
        'language': _language,
        'macros': _plus,
        'hour': DateTime.now().hour,
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
      reportError(error, st, 'AI estimate');
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
      reportError(error, st, 'AI voice estimate');
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
      reportError(error, st, 'AI photo estimate');
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
      reportError(error, st, 'AI label reading');
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
