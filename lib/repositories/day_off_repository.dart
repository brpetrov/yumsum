import 'package:cloud_firestore/cloud_firestore.dart';

/// Days the user has taken off (holidays, birthdays): meals are logged as
/// usual but the day isn't judged against the target.
///
/// Document path: `users/{uid}/days_off/{yyyy-MM-dd}`. Kept apart from the
/// daily summary, which is rewritten on every meal change and deleted when a
/// day has none; the summary copies the flag each time it is recomputed.
class DayOffRepository {
  DayOffRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String date) =>
      _db.collection('users').doc(uid).collection('days_off').doc(date);

  Stream<bool> watch(String uid, String date) =>
      _doc(uid, date).snapshots().map((snap) => snap.exists);

  Future<bool> isDayOff(String uid, String date) async =>
      (await _doc(uid, date).get()).exists;

  Future<void> setDayOff(String uid, String date, bool off) =>
      off ? _doc(uid, date).set({'date': date}) : _doc(uid, date).delete();
}
