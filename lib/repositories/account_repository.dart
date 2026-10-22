import 'package:cloud_firestore/cloud_firestore.dart';

class AccountRepository {
  AccountRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  /// Everything the user has logged. The profile document stays.
  Future<void> resetAllData(String uid) async {
    final userDoc = _userDoc(uid);
    for (final name in const [
      'meals',
      'daily_summaries',
      'weight_entries',
      'day_edits',
      'days_off',
      'ai_usage',
    ]) {
      await _deleteCollection(userDoc.collection(name));
    }
  }

  /// [resetAllData], legacy check-in data, then the user document itself.
  Future<void> deleteAccountData(String uid) async {
    await resetAllData(uid);
    final userDoc = _userDoc(uid);
    await _deleteCollection(userDoc.collection('check_ins'));
    await _deleteCollection(userDoc.collection('check_in_prompt_status'));
    await userDoc.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(200).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
