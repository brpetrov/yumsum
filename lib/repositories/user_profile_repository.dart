import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// One-time fetch. Returns null if the document does not exist yet.
  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromFirestore(snap);
  }

  /// Real-time stream. Emits null when the document does not exist, and
  /// again only when the data changes.
  Stream<UserProfile?> watchProfile(String uid) async* {
    // Metadata changes are listened to so that a missing document read from
    // the cache waits for the server's word. Snapshots that change only the
    // metadata are dropped, so watchers don't run again for the same profile.
    var yielded = false;
    Map<String, dynamic>? last;
    await for (final snap in _doc(
      uid,
    ).snapshots(includeMetadataChanges: true)) {
      final data = snap.exists ? snap.data() : null;
      if (data == null && snap.metadata.isFromCache) continue;
      if (yielded && _sameData(data, last)) continue;
      yielded = true;
      last = data;
      yield data == null ? null : UserProfile.fromFirestore(snap);
    }
  }

  /// Creates (or overwrites) the user's profile document.
  Future<void> createProfile(UserProfile profile) {
    return _doc(profile.uid).set(profile.toFirestore());
  }

  /// Partially updates the user's profile document.
  /// Always stamps [updatedAt] via server timestamp.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return _doc(
      uid,
    ).update({...fields, 'updatedAt': FieldValue.serverTimestamp()});
  }
}

/// Whether two Firestore values hold the same data: maps and lists by what
/// is in them, the rest (numbers, strings, timestamps) by ==.
bool _sameData(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && _sameData(a[key], b[key]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameData(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
