import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:lean_streak/core/constants/app_info.dart';

/// Sends feedback to a Formspree form, which emails it to [supportEmail]
/// with the user's address to reply to.
class FeedbackRepository {
  FeedbackRepository([http.Client? client]) : _client = client ?? http.Client();
  final http.Client _client;

  static final endpoint = Uri.parse('https://formspree.io/f/mqppllqo');

  Future<void> send({
    required String uid,
    required String email,
    required String text,
  }) async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    final response = await _client.post(
      endpoint,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        '_subject': 'YumSum feedback',
        'email': email,
        'message': text,
        'user': uid,
        'app': '$appVersion, $platform',
      }),
    );
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Feedback failed: ${response.statusCode}',
        endpoint,
      );
    }
  }
}
