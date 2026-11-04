import 'package:cloud_firestore/cloud_firestore.dart';

/// The AI Coach's notes on a week, kept in `weekly_reviews/{Monday}` with
/// the facts they were written from: the notes are shown again for as long
/// as the facts haven't changed.
class WeeklyReview {
  const WeeklyReview({
    required this.points,
    required this.basis,
    required this.createdAt,
  });

  final List<String> points;

  /// The prompt version and the facts, exactly as sent.
  final String basis;
  final DateTime createdAt;

  factory WeeklyReview.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return WeeklyReview(
      points: [for (final point in data['points'] as List) point as String],
      basis: data['basis'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'points': points,
    'basis': basis,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
