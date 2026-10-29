import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:lean_streak/core/constants/app_info.dart';

/// Sends feedback by adding a document to `mail`, which the Firebase
/// "Trigger Email from Firestore" extension emails to [supportEmail].
/// `firestore.rules` only lets a user create one shaped exactly like this.
class FeedbackRepository {
  FeedbackRepository(this._db);
  final FirebaseFirestore _db;

  Future<void> send({
    required String uid,
    required String email,
    required String text,
  }) {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    return _db.collection('mail').add({
      'to': supportEmail,
      'replyTo': email,
      'message': {
        'subject': 'YumSum feedback',
        'text': '$text\n\n--\nUser: $uid\nApp: $appVersion, $platform',
      },
    });
  }
}
