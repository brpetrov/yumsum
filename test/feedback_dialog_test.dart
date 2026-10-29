import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/feedback_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/repositories/feedback_repository.dart';
import 'package:lean_streak/widgets/feedback_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'u1';

  @override
  String? get email => 'a@b.com';
}

class _FakeFeedbackRepository extends Fake implements FeedbackRepository {
  final sent = <({String uid, String email, String kind, String text})>[];
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<void> send({
    required String uid,
    required String email,
    required String kind,
    required String text,
  }) async {
    await gate?.future;
    if (fail) throw Exception('offline');
    sent.add((uid: uid, email: email, kind: kind, text: text));
  }
}

void main() {
  late _FakeFeedbackRepository repo;
  late SharedPreferences prefs;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> openDialog(
    WidgetTester tester, {
    Map<String, Object> stored = const {},
  }) async {
    repo = _FakeFeedbackRepository();
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(_User())),
          feedbackRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFeedbackDialog(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  FilledButton sendButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send'));

  testWidgets('Send is off until something is written', (tester) async {
    await openDialog(tester);
    expect(find.text('Replies go to a@b.com.'), findsOneWidget);
    expect(sendButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('feedback-text')), '   ');
    await tester.pump();
    expect(sendButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('feedback-text')), 'Hi');
    await tester.pump();
    expect(sendButton(tester).onPressed, isNotNull);
  });

  testWidgets('Sends the trimmed text and says thank you', (tester) async {
    await openDialog(tester);
    repo.gate = Completer<void>();
    await tester.enterText(
      find.byKey(const Key('feedback-text')),
      '  Love it  ',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump();

    // Off while sending, so it can't go twice.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sending…'))
          .onPressed,
      isNull,
    );
    repo.gate!.complete();
    await tester.pumpAndSettle();

    expect(repo.sent, [
      (uid: 'u1', email: 'a@b.com', kind: 'Problem', text: 'Love it'),
    ]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Feedback sent. Thank you.'), findsOneWidget);
    expect(prefs.getString('feedback.sent_day'), today);
    expect(prefs.getInt('feedback.sent_count'), 1);
  });

  testWidgets('Three a day, then Send is off until tomorrow', (tester) async {
    await openDialog(
      tester,
      stored: {'feedback.sent_day': today, 'feedback.sent_count': 3},
    );
    await tester.enterText(find.byKey(const Key('feedback-text')), 'More');
    await tester.pump();

    expect(sendButton(tester).onPressed, isNull);
    expect(
      find.text("You've sent 3 today. You can send more tomorrow."),
      findsOneWidget,
    );
  });

  testWidgets("Yesterday's count doesn't block today", (tester) async {
    await openDialog(
      tester,
      stored: {'feedback.sent_day': '2000-01-01', 'feedback.sent_count': 3},
    );
    await tester.enterText(find.byKey(const Key('feedback-text')), 'Hi');
    await tester.pump();

    expect(sendButton(tester).onPressed, isNotNull);
  });

  testWidgets('The chosen kind changes the prompt and is sent', (tester) async {
    await openDialog(tester);
    expect(
      find.text('What happened, and what did you expect?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Idea'));
    await tester.pump();
    expect(find.text('What would make YumSum better for you?'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('feedback-text')), 'Dark mode');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(repo.sent.single.kind, 'Idea');
  });

  testWidgets('A failed send keeps the text and says so', (tester) async {
    await openDialog(tester);
    repo.fail = true;
    await tester.enterText(find.byKey(const Key('feedback-text')), 'Bug');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();

    expect(find.text('Could not send. Try again.'), findsOneWidget);
    expect(find.text('Bug'), findsOneWidget);
    expect(sendButton(tester).onPressed, isNotNull);
  });
}
