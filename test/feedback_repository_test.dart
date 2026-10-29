import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lean_streak/core/constants/app_info.dart';
import 'package:lean_streak/repositories/feedback_repository.dart';

void main() {
  test('posts the message to the Formspree form as JSON', () async {
    late http.Request sent;
    final repo = FeedbackRepository(
      MockClient((request) async {
        sent = request;
        return http.Response('{"ok":true}', 200);
      }),
    );

    await repo.send(uid: 'u1', email: 'a@b.com', kind: 'Idea', text: 'Love it');

    expect(sent.method, 'POST');
    expect(sent.url, FeedbackRepository.endpoint);
    expect(sent.headers['Accept'], 'application/json');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['_subject'], 'YumSum feedback: Idea');
    expect(body['email'], 'a@b.com');
    expect(body['message'], 'Love it');
    expect(body['user'], 'u1');
    expect(body['app'], startsWith('$appVersion, '));
  });

  test('throws when Formspree refuses it', () async {
    final repo = FeedbackRepository(
      MockClient((_) async => http.Response('{"errors":[]}', 422)),
    );

    expect(
      repo.send(uid: 'u1', email: 'a@b.com', kind: 'Other', text: 'Hi'),
      throwsA(isA<http.ClientException>()),
    );
  });
}
