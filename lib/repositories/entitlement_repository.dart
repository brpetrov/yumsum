import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/entitlement.dart';

/// Reads `entitlements/{uid}`. There is nothing to write: the server sets
/// it from Google Play, or the owner by hand.
class EntitlementRepository {
  EntitlementRepository(this._db);
  final FirebaseFirestore _db;

  Stream<Entitlement?> watch(String uid) => _db
      .collection('entitlements')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? Entitlement.fromFirestore(snap) : null);
}
