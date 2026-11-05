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

Map<String, Object?> _note(String title, String text) => {
  'title': title,
  'text': text,
  'good': false,
};

void main() {
  test('keeps the title and the good mark; a bare string has neither', () {
    expect(
      parseReviewPoints([
        {
          'title': 'Fibre on track',
          'text': 'Fibre met the guide.',
          'good': true,
        },
        'Salt averaged 7.4 g.',
        {'text': 'Steady weekdays.', 'good': 'yes'},
      ], facts: _facts),
      [
        (title: 'Fibre on track', text: 'Fibre met the guide.', good: true),
        (title: '', text: 'Salt averaged 7.4 g.', good: false),
        (title: '', text: 'Steady weekdays.', good: false),
      ],
    );
  });

  test('keeps at most 8 notes, in order', () {
    final notes = [
      'One.',
      'Two.',
      'Three.',
      'Four.',
      'Five.',
      'Six.',
      'Seven.',
      'Eight.',
    ];
    expect(_parse([...notes, 'Nine.']), notes);
  });

  test('drops a note over 600 characters, or a title over 80', () {
    final long = 'Steady weekdays. ${'x' * 590}';
    expect(_parse([long, 'Short.']), ['Short.']);
    expect(_parse(['y' * 600, 'Short.']), hasLength(2));
    expect(_parse([_note('t' * 81, 'Short.'), _note('t' * 80, 'Fine.')]), [
      'Fine.',
    ]);
  });

  test('drops a note with a number not in the facts, in the text or the '
      'title', () {
    expect(
      _parse([
        'That\'s nearly 700 kcal more on weekend days.',
        _note('700 kcal more', 'Weekend days ran higher.'),
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

  test('drops a note with a shaming word, in the text or the title', () {
    expect(
      _parse([
        'Saturday was a cheat day.',
        'No need to feel guilty about Saturday.',
        _note('A lazy weekend', 'Saturday ran high.'),
        'Saturday was the biggest day in 3 of the last 4 weeks.',
      ]),
      ['Saturday was the biggest day in 3 of the last 4 weeks.'],
    );
  });

  test('drops non-strings and blanks, and trims', () {
    expect(
      parseReviewPoints([
        42,
        null,
        '  ',
        ' Steady weekdays. ',
        {'a': 1},
        _note(' Weekends ', 'Higher.'),
      ], facts: _facts),
      [
        (title: '', text: 'Steady weekdays.', good: false),
        (title: 'Weekends', text: 'Higher.', good: false),
      ],
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
          {
            'title': 'Salt over the guide',
            'text': 'Salt averaged 7.4 g.',
            'good': false,
          },
        ],
      };

    final points = await WeeklyReviewService(functions).write(_facts);

    expect(points, [
      (title: 'Salt over the guide', text: 'Salt averaged 7.4 g.', good: false),
    ]);
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
