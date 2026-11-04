import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/weekly_review.dart';

/// The AI Coach's notes, one document per week.
///
/// Document path: `users/{uid}/weekly_reviews/{yyyy-MM-dd}`, keyed by the
/// week's Monday.
class WeeklyReviewRepository {
  WeeklyReviewRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String week) =>
      _db.collection('users').doc(uid).collection('weekly_reviews').doc(week);

  Future<WeeklyReview?> fetch(String uid, String week) async {
    final snapshot = await _doc(uid, week).get();
    return snapshot.exists ? WeeklyReview.fromFirestore(snapshot) : null;
  }

  Future<void> save(String uid, String week, WeeklyReview review) =>
      _doc(uid, week).set(review.toFirestore());
}
