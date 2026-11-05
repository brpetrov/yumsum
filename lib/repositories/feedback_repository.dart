import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:lean_streak/core/constants/app_info.dart';

/// The account has sent today's feedback, on this device or another.
class FeedbackLimitReached implements Exception {
  const FeedbackLimitReached();
}

/// Sends feedback through the `sendFeedback` function, which emails it to
/// [supportEmail] from a Formspree form, with the account's address to reply
/// to.
class FeedbackRepository {
  FeedbackRepository(this._functions);
  final FirebaseFunctions _functions;

  /// [kind] (Problem, Idea or Other) goes in the subject, for sorting mail.
  /// The server adds the account's uid and email. Throws
  /// [FeedbackLimitReached] once today's are sent.
  Future<void> send({required String kind, required String text}) async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    try {
      await _functions.httpsCallable('sendFeedback').call<Object?>({
        'kind': kind,
        'text': text,
        'app': '$appVersion, $platform',
      });
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'resource-exhausted') {
        throw const FeedbackLimitReached();
      }
      rethrow;
    }
  }
}
