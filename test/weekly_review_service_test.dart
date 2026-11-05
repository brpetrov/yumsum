import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/services/weekly_review_service.dart';

import 'ai_fixtures.dart';

const _facts =
    'Week: Monday 26 October to Sunday 1 November.\n'
    'Weekdays averaged 1,890 kcal; the weekend averaged 2,580 kcal.\n'
    'Saturday was the biggest day in 3 of the last 4 weeks.\n'
    'Salt: the UK guide is at most 6 g a day. Averaged 7.4 g on the 6 days '
    'with salt for every meal; over on 4 days.';

List<String> _parse(Object? raw) => [
  for (final point in parseReviewPoints(raw, facts: _facts)) point.text,
];

void main() {
  test('keeps the good mark; a bare string is not good', () {
    expect(
      parseReviewPoints([
        {'text': 'Fibre met the guide all week.', 'good': true},
        'Salt averaged 7.4 g.',
        {'text': 'Steady weekdays.', 'good': 'yes'},
      ], facts: _facts),
      [
        (text: 'Fibre met the guide all week.', good: true),
        (text: 'Salt averaged 7.4 g.', good: false),
        (text: 'Steady weekdays.', good: false),
      ],
    );
  });

  test('keeps at most 6 notes, in order', () {
    final notes = ['One.', 'Two.', 'Three.', 'Four.', 'Five.', 'Six.'];
    expect(_parse([...notes, 'Seven.']), notes);
  });

  test('drops a note over 160 characters', () {
    final long = 'Steady weekdays. ${'x' * 150}';
    expect(_parse([long, 'Short.']), ['Short.']);
    expect(_parse(['y' * 160, 'Short.']), hasLength(2));
  });

  test('drops a note with a number not in the facts', () {
    expect(
      _parse([
        'That\'s nearly 700 kcal more on weekend days.',
        'Weekdays were steady at about 1,890 kcal.',
      ]),
      ['Weekdays were steady at about 1,890 kcal.'],
    );
  });

  test('numbers match with or without the thousands comma, and decimals', () {
    expect(
      _parse([
        'Weekdays were steady at about 1890 kcal, the weekend 2,580.',
        'Salt averaged 7.4 g against the 6 g guide, over on 4 days.',
        'Salt averaged 7.5 g.',
      ]),
      [
        'Weekdays were steady at about 1890 kcal, the weekend 2,580.',
        'Salt averaged 7.4 g against the 6 g guide, over on 4 days.',
      ],
    );
  });

  test('drops a note with a shaming word', () {
    expect(
      _parse([
        'Saturday was a cheat day.',
        'No need to feel guilty about Saturday.',
        'Saturday was the biggest day in 3 of the last 4 weeks.',
      ]),
      ['Saturday was the biggest day in 3 of the last 4 weeks.'],
    );
  });

  test('drops non-strings and blanks', () {
    expect(
      _parse([
        42,
        null,
        '  ',
        ' Steady weekdays. ',
        {'a': 1},
      ]),
      ['Steady weekdays.'],
    );
  });

  test('nothing left is a failure', () {
    expect(
      () => _parse(['That\'s 700 kcal more.']),
      throwsA(isA<WeeklyReviewException>()),
    );
    expect(() => _parse(null), throwsA(isA<WeeklyReviewException>()));
    expect(() => _parse('One.'), throwsA(isA<WeeklyReviewException>()));
  });

  // The instruction's own rules are tested with it, in functions/test.
  test('the server writes the notes from the facts alone', () async {
    final functions = FakeAiFunctions()
      ..reply = {
        'points': [
          {'text': 'Salt averaged 7.4 g.', 'good': false},
        ],
      };

    final points = await WeeklyReviewService(functions).write(_facts);

    expect(points, [(text: 'Salt averaged 7.4 g.', good: false)]);
    expect(functions.calls.single.$1, 'aiWeeklyReview');
    expect(functions.calls.single.$2.keys, ['facts', 'dateKey']);
    expect(functions.calls.single.$2['facts'], _facts);
  });

  test('a refusal from the server is a failure', () async {
    final functions = FakeAiFunctions()
      ..error = serverError('permission-denied');
    await expectLater(
      WeeklyReviewService(functions).write(_facts),
      throwsA(isA<FirebaseFunctionsException>()),
    );
  });
}
