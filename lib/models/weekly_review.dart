import 'package:cloud_firestore/cloud_firestore.dart';

/// One of the AI Coach's notes; [good] when it's about something that went
/// well, which the card marks with a green dot.
typedef ReviewPoint = ({String text, bool good});

/// A note as saved or as the AI wrote it: `{text, good}`, or a bare string
/// from before prompt version 4, which isn't good. Null for anything else.
ReviewPoint? reviewPointFrom(Object? raw) => switch (raw) {
  {'text': final String text, 'good': final bool good} => (
    text: text,
    good: good,
  ),
  {'text': final String text} => (text: text, good: false),
  final String text => (text: text, good: false),
  _ => null,
};

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
    'points': [
      for (final point in points) {'text': point.text, 'good': point.good},
    ],
    'basis': basis,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
