import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/weight_entry.dart';

class WeightEntryRepository {
  WeightEntryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String uid) {
    return _db.collection('users').doc(uid).collection('weight_entries');
  }

  /// Creates or overwrites the entry for its day (doc id is the date key).
  Future<void> upsertEntry(String uid, WeightEntry entry) {
    return _entries(uid).doc(entry.dateKey).set(entry.toFirestore());
  }

  /// Real-time stream of all entries, oldest first — ready to plot.
  Stream<List<WeightEntry>> watchEntries(String uid) {
    return _entries(uid).orderBy('dateKey').snapshots().map((snapshot) {
      return snapshot.docs.map(WeightEntry.fromFirestore).toList();
    });
  }

  /// Removes every entry, so progress counts from the next weigh-in.
  Future<void> deleteAll(String uid) async {
    while (true) {
      final snapshot = await _entries(uid).limit(200).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Real-time stream of the newest entry only, or null when there is none.
  Stream<WeightEntry?> watchLatestEntry(String uid) {
    return _entries(
      uid,
    ).orderBy('dateKey', descending: true).limit(1).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WeightEntry.fromFirestore(snapshot.docs.first);
    });
  }
}
