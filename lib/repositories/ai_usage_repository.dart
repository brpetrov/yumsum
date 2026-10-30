import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks daily AI calorie estimate usage per user.
///
/// Document path: `users/{uid}/ai_usage/{yyyy-MM-dd}`
/// The date in the path acts as a natural daily reset —
/// a new day means a new document, no cron job needed.
class AiUsageRepository {
  AiUsageRepository(this._db);
  final FirebaseFirestore _db;

  static const int dailyLimit = 20;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String date) =>
      _db.collection('users').doc(uid).collection('ai_usage').doc(date);

  /// Streams today's usage count. Emits 0 if no document exists yet.
  Stream<int> watchCount(String uid, String date) => _doc(uid, date)
      .snapshots()
      .map((snap) => snap.exists ? ((snap.data()?['count'] as int?) ?? 0) : 0);

  /// Atomically increments the usage count for [date].
  Future<void> increment(String uid, String date) => _doc(
    uid,
    date,
  ).set({'count': FieldValue.increment(1)}, SetOptions(merge: true));
}
