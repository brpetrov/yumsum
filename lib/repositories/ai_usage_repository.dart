import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads daily AI calorie estimate usage per user, which the AI's Cloud
/// Functions count (`functions/src/ai.ts`); the app can't write it.
///
/// Document path: `users/{uid}/ai_usage/{yyyy-MM-dd}`
/// The date in the path acts as a natural daily reset —
/// a new day means a new document, no cron job needed.
class AiUsageRepository {
  AiUsageRepository(this._db);
  final FirebaseFirestore _db;

  /// The same as the server's `limits.estimate` in `functions/src/ai.ts`:
  /// [dailyLimit] free, [starDailyLimit] with YumSum Star.
  static const int dailyLimit = 10;
  static const int starDailyLimit = 30;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String date) =>
      _db.collection('users').doc(uid).collection('ai_usage').doc(date);

  /// Streams today's usage count. Emits 0 if no document exists yet.
  Stream<int> watchCount(String uid, String date) => _doc(uid, date)
      .snapshots()
      .map((snap) => snap.exists ? ((snap.data()?['count'] as int?) ?? 0) : 0);
}
