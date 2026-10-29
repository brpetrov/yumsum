import 'package:cloud_firestore/cloud_firestore.dart';

class AccountRepository {
  AccountRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  /// Everything the user has logged. The profile document stays, and so do
  /// the AI and past-day edit counters, which the security rules only let go
  /// with the account.
  Future<void> resetAllData(String uid) async {
    final userDoc = _userDoc(uid);
    for (final name in const [
      'meals',
      'daily_summaries',
      'weight_entries',
      'days_off',
    ]) {
      await _deleteCollection(userDoc.collection(name));
    }
  }

  /// [resetAllData], legacy check-in data, the user document, then the
  /// counters, which the rules only let go once the profile is gone.
  Future<void> deleteAccountData(String uid) async {
    await resetAllData(uid);
    final userDoc = _userDoc(uid);
    await _deleteCollection(userDoc.collection('check_ins'));
    await _deleteCollection(userDoc.collection('check_in_prompt_status'));
    await userDoc.delete();
    await _deleteCollection(userDoc.collection('day_edits'));
    await _deleteCollection(userDoc.collection('ai_usage'));
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
