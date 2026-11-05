import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AccountRepository {
  AccountRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  /// Everything the user has logged. The profile document stays, and so do
  /// the AI and past-day edit counters, which only [deleteAccount] deletes.
  Future<void> resetAllData(String uid) async {
    final userDoc = _userDoc(uid);
    for (final name in const [
      'meals',
      'daily_summaries',
      'weight_entries',
      'days_off',
      'weekly_reviews',
    ]) {
      await _deleteCollection(userDoc.collection(name));
    }
  }

  /// [resetAllData], legacy check-in data and the user document.
  Future<void> deleteAccountData(String uid) async {
    await resetAllData(uid);
    final userDoc = _userDoc(uid);
    await _deleteCollection(userDoc.collection('check_ins'));
    await _deleteCollection(userDoc.collection('check_in_prompt_status'));
    await userDoc.delete();
  }

  /// Has the server delete the counters, which the app can't, and then the
  /// signed-in account itself. Call it after [deleteAccountData].
  Future<void> deleteAccount() =>
      _functions.httpsCallable('deleteAccount').call<Object?>({});

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
