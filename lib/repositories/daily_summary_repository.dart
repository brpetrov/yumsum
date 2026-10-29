import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/daily_summary.dart';

class DailySummaryRepository {
  DailySummaryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _dailySummaries(String uid) {
    return _db.collection('users').doc(uid).collection('daily_summaries');
  }

  Future<void> saveSummary(String uid, DailySummary summary) async {
    await _dailySummaries(uid).doc(summary.date).set(summary.toFirestore());
  }

  Future<void> deleteSummary(String uid, String date) async {
    await _dailySummaries(uid).doc(date).delete();
  }

  Future<List<DailySummary>> fetchSummariesInRange(
    String uid, {
    required String startDate,
    required String endDate,
  }) async {
    final snapshot = await _dailySummaries(uid)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date')
        .get();

    return snapshot.docs.map((doc) => DailySummary.fromFirestore(doc)).toList();
  }

  /// The earliest day with a summary, or null when nothing is logged yet.
  Future<DateTime?> fetchFirstSummaryDate(String uid) async {
    final snapshot = await _dailySummaries(uid).orderBy('date').limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return DateTime.parse(snapshot.docs.first.data()['date'] as String);
  }

  Stream<DailySummary?> watchSummary(String uid, String date) {
    return _dailySummaries(uid).doc(date).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return DailySummary.fromFirestore(snapshot);
    });
  }
}
