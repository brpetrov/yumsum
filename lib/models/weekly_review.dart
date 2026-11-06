import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One of the AI Coach's notes: a short [title], [text] on what the facts
/// show, and [good] when it's about something that went well, which the
/// page marks with a green dot. Since prompt version 7 the rest comes in
/// pieces: [why] it matters in one sentence, one or two [tips] to act on,
/// and the library [recipes] that fit, by name. Older notes have it all in
/// [text].
class ReviewPoint {
  const ReviewPoint({
    required this.title,
    required this.text,
    required this.good,
    this.why = '',
    this.tips = const [],
    this.recipes = const [],
  });

  final String title;
  final String text;
  final bool good;
  final String why;
  final List<String> tips;
  final List<String> recipes;

  Map<String, Object?> toMap() => {
    'title': title,
    'text': text,
    'good': good,
    'why': why,
    'tips': tips,
    'recipes': recipes,
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewPoint &&
      other.title == title &&
      other.text == text &&
      other.good == good &&
      other.why == why &&
      listEquals(other.tips, tips) &&
      listEquals(other.recipes, recipes);

  @override
  int get hashCode => Object.hash(
    title,
    text,
    good,
    why,
    Object.hashAll(tips),
    Object.hashAll(recipes),
  );

  @override
  String toString() => 'ReviewPoint($title: $text)';
}

/// A note as saved or as the AI wrote it: `{title, text, good}` with `why`,
/// `tips` and `recipes` since prompt version 7; from before version 6
/// without a title, and before 4 a bare string, which isn't good. Null for
/// anything else.
ReviewPoint? reviewPointFrom(Object? raw) => switch (raw) {
  {'text': final String text} && final Map<Object?, Object?> map => ReviewPoint(
    title: switch (map['title']) {
      final String title => title,
      _ => '',
    },
    text: text,
    good: map['good'] == true,
    why: switch (map['why']) {
      final String why => why,
      _ => '',
    },
    tips: _strings(map['tips']),
    recipes: _strings(map['recipes']),
  ),
  final String text => ReviewPoint(title: '', text: text, good: false),
  _ => null,
};

List<String> _strings(Object? raw) => [
  if (raw is List)
    for (final item in raw)
      if (item is String) item,
];

/// The AI Coach's notes on a week, kept in `weekly_reviews/{Monday}` with
/// the facts they were written from: the notes are shown again for as long
/// as the facts haven't changed.
class WeeklyReview {
  const WeeklyReview({
    required this.points,
    required this.basis,
    required this.createdAt,
  });

  final List<ReviewPoint> points;

  /// The prompt version and the facts, exactly as sent.
  final String basis;
  final DateTime createdAt;

  factory WeeklyReview.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return WeeklyReview(
      points: [
        for (final point in data['points'] as List) reviewPointFrom(point)!,
      ],
      basis: data['basis'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'points': [for (final point in points) point.toMap()],
    'basis': basis,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
