import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/constants/app_info.dart';
import 'package:lean_streak/repositories/feedback_repository.dart';

import 'fake_functions.dart';

void main() {
  test('sends the message to the sendFeedback function', () async {
    final functions = FakeFunctions();

    await FeedbackRepository(functions).send(kind: 'Idea', text: 'Love it');

    final call = functions.calls.single;
    expect(call.name, 'sendFeedback');
    final data = call.data! as Map<String, Object?>;
    // The server adds the uid and email from the sign-in.
    expect(data.keys, unorderedEquals(['kind', 'text', 'app']));
    expect(data['kind'], 'Idea');
    expect(data['text'], 'Love it');
    expect(data['app'], startsWith('$appVersion, '));
  });

  test("the server's daily limit has its own exception", () async {
    final repo = FeedbackRepository(
      FakeFunctions()
        ..error = FirebaseFunctionsException(
          code: 'resource-exhausted',
          message: "That's all for today.",
        ),
    );

    expect(
      repo.send(kind: 'Other', text: 'Hi'),
      throwsA(isA<FeedbackLimitReached>()),
    );
  });

  test('throws when it could not be sent', () async {
    final repo = FeedbackRepository(
      FakeFunctions()
        ..error = FirebaseFunctionsException(
          code: 'unavailable',
          message: 'Could not reach Formspree.',
        ),
    );

    expect(
      repo.send(kind: 'Other', text: 'Hi'),
      throwsA(isA<FirebaseFunctionsException>()),
    );
  });
}
