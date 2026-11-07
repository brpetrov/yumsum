import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

import 'ai_fixtures.dart';

class _Usage extends Fake implements AiUsageRepository {
  _Usage(this.count);

  final int count;

  @override
  Stream<int> watchCount(String uid, String date) => Stream.value(count);
}

void main() {
  late FakeAiFunctions functions;

  CalorieEstimateService service({
    bool plus = false,
    int used = 0,
    int? dailyLimit = AiUsageRepository.dailyLimit,
  }) {
    functions = FakeAiFunctions();
    return CalorieEstimateService(
      _Usage(used),
      functions,
      country: 'Bulgaria',
      dailyLimit: dailyLimit,
      plus: plus,
    );
  }

  group('the AI functions', () {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    test(
      'an estimate sends the meal and the country, never a prompt',
      () async {
        final estimates = service(plus: true);
        functions.reply = {
          'items': [
            {'item': 'Musaka', 'grams': 350, 'kcal': 520, 'protein_g': 28},
          ],
          'kcal': 520,
          'protein_g': 28,
          'macros': {'fat': 30, 'saturates': 12, 'carbs': 35},
        };

        final result = await estimates.estimate('u1', ' Musaka ');

        final (name, data) = functions.calls.single;
        expect(name, 'aiEstimate');
        expect(data, {
          'kind': 'meal',
          'country': 'Bulgaria',
          'macros': true,
          'text': 'Musaka',
          'dateKey': today,
        });
        expect(result.kcal, 520);
        expect(result.protein, 28);
        expect(result.macros?.fat, 30);
        expect(result.items.single.name, 'Musaka');
      },
    );

    test('macros are asked for only with YumSum Star', () async {
      final estimates = service();
      functions.reply = {'kcal': 520, 'protein_g': 28};
      await estimates.estimate('u1', 'Musaka');
      await estimates.estimateNutrients(' Lunch ', 500);
      expect(functions.calls.map((call) => call.$2['macros']), [false, false]);
      expect(functions.calls.last.$2, containsPair('kind', 'nutrients'));
      expect(functions.calls.last.$2, containsPair('name', 'Lunch'));
      expect(functions.calls.last.$2, containsPair('kcal', 500));
    });

    test('a voice note, a photo and a label go in base64', () async {
      final estimates = service();
      final bytes = Uint8List.fromList([1, 2, 3]);
      functions.reply = {'name': 'Musaka', 'kcal': 640, 'protein_g': 28};
      await estimates.parseVoiceAudio('u1', bytes);
      await estimates.estimateFromPhoto('u1', bytes);
      functions.reply = {
        'name': 'Лютеница',
        'per_100g': {'proteins': 2},
      };
      await estimates.readLabel('u1', null, bytes);
      await estimates.readLabel('u1', bytes, bytes);

      final sent = [for (final call in functions.calls) call.$2];
      expect(sent[0], containsPair('audio', base64Encode(bytes)));
      expect(sent[1], containsPair('photo', base64Encode(bytes)));
      expect(sent[2], containsPair('label', base64Encode(bytes)));
      expect(sent[2], isNot(contains('front')));
      expect(sent[3], containsPair('front', base64Encode(bytes)));
      expect(
        [for (final data in sent) data['kind']],
        ['voice', 'photo', 'label', 'label'],
      );
    });

    test('a used-up allowance is said without a call', () async {
      await expectLater(
        service(used: 20).estimate('u1', 'Musaka'),
        throwsA(isA<DailyLimitExceededException>()),
      );
      expect(functions.calls, isEmpty);

      // The owner's account has no limit.
      final owner = service(used: 20, dailyLimit: null);
      functions.reply = {'kcal': 520};
      await owner.estimate('u1', 'Musaka');
      expect(functions.calls, hasLength(1));
    });

    test('no meal heard, and no food seen', () async {
      final estimates = service();
      functions.reply = {'error': 'no meal'};
      await expectLater(
        estimates.parseVoiceAudio('u1', Uint8List(4)),
        throwsA(
          isA<CalorieEstimateException>().having(
            (error) => error.message,
            'message',
            contains('Couldn\'t hear a meal'),
          ),
        ),
      );
      await expectLater(
        estimates.estimateFromPhoto('u1', Uint8List(4)),
        throwsA(
          isA<CalorieEstimateException>().having(
            (error) => error.message,
            'message',
            contains('No food found'),
          ),
        ),
      );
    });

    test('the server\'s errors become the messages the screens show', () async {
      Future<Object?> failure(String code, [String? reason]) async {
        final estimates = service();
        functions.error = serverError(code, reason);
        try {
          await estimates.estimate('u1', 'Musaka');
        } catch (error) {
          return error is CalorieEstimateException ? error.message : error;
        }
        return null;
      }

      expect(
        await failure('resource-exhausted'),
        isA<DailyLimitExceededException>(),
      );
      expect(
        await failure('failed-precondition', 'off'),
        aiNotSwitchedOnMessage,
      );
      expect(await failure('failed-precondition', 'paused'), aiPausedMessage);
      expect(await failure('unavailable', 'busy'), aiBusyMessage);
      expect(await failure('unavailable', 'transient'), contains('busy'));
      expect(await failure('permission-denied'), contains('YumSum Star'));
      expect(
        await failure('internal'),
        'Could not estimate calories. Try again.',
      );
      expect(
        await failure('unavailable'),
        'Could not estimate calories. Try again.',
      );
    });

    test('an answer that isn\'t an estimate is a failure', () async {
      final estimates = service();
      functions.reply = {'protein_g': 20};
      await expectLater(
        estimates.estimate('u1', 'Musaka'),
        throwsA(
          isA<CalorieEstimateException>().having(
            (error) => error.message,
            'message',
            'Could not estimate calories. Try again.',
          ),
        ),
      );
    });
  });

  group('macros', () {
    test('parseNutrients keeps the six figures', () {
      final macros = parseNutrients({
        'fat': 18,
        'saturates': 6,
        'carbs': 52.5,
        'sugars': 5,
        'fibre': 4,
        'salt': 2.1,
      })!;
      expect(
        [
          macros.fat,
          macros.saturates,
          macros.carbs,
          macros.sugars,
          macros.fibre,
          macros.salt,
        ],
        [18, 6, 52.5, 5, 4, 2.1],
      );
    });

    test('parseNutrients leaves out missing, negative and odd values', () {
      final macros = parseNutrients({
        'fat': 12,
        'carbs': -3,
        'sugars': '4',
        'salt': null,
      })!;
      expect(macros.fat, 12);
      expect(macros.carbs, isNull);
      expect(macros.sugars, isNull);
      expect(macros.salt, isNull);
      expect(parseNutrients(null), isNull);
      expect(parseNutrients('macros'), isNull);
      expect(parseNutrients(<String, dynamic>{}), isNull);
    });

    test('parseNutrients drops a set with the figures mixed up', () {
      expect(parseNutrients({'fat': 5, 'saturates': 8, 'carbs': 40}), isNull);
      expect(parseNutrients({'carbs': 10, 'sugars': 25}), isNull);
      // Saturates alone can't be checked against fat.
      expect(parseNutrients({'saturates': 8})?.saturates, 8);
    });
  });

  test('a label reading keeps printed figures and drops blanks', () {
    final reading = parseLabelReading({
      'name': 'Кисело мляко',
      'lang': 'BG',
      'brand': 'Верея',
      'quantity': '400 g',
      'serving_size': null,
      'per_100g': {
        'energy-kcal': 63,
        'proteins': 3.3,
        'fat': 3.6,
        'sugars': null,
        'salt': 'a little',
        'fiber': -1,
      },
    });

    expect(reading.name, 'Кисело мляко');
    expect(reading.lang, 'bg');
    expect(parseLabelReading({'lang': 'Bulgarian'}).lang, isNull);
    expect(reading.brand, 'Верея');
    expect(reading.quantity, '400 g');
    expect(reading.servingSize, isNull);
    expect(reading.per100g, {'energy-kcal': 63, 'proteins': 3.3, 'fat': 3.6});
    expect(parseLabelReading({}).per100g, isEmpty);
  });

  group('parseEstimateItems', () {
    test('reads the model items', () {
      expect(
        parseEstimateItems([
          {'item': 'Musaka', 'grams': 350, 'kcal': 520, 'protein_g': 28},
          {'item': ' Bread ', 'grams': 0, 'kcal': 80.4, 'protein_g': null},
        ]),
        const [
          EstimateItem(name: 'Musaka', grams: 350, kcal: 520, protein: 28),
          EstimateItem(name: 'Bread', kcal: 80),
        ],
      );
    });

    test('skips malformed entries and tolerates missing lists', () {
      expect(
        parseEstimateItems([
          {'item': 'Oil', 'kcal': 120},
          {'item': '', 'kcal': 50},
          {'kcal': 50},
          {'item': 'Mystery', 'kcal': 'lots'},
          'not a map',
        ]),
        const [EstimateItem(name: 'Oil', kcal: 120)],
      );
      expect(parseEstimateItems(null), isEmpty);
      expect(parseEstimateItems('items'), isEmpty);
    });

    test('a corrected weight rescales the item, and the totals follow', () {
      const chicken = EstimateItem(
        name: 'Chicken breast, cooked',
        grams: 150,
        kcal: 248,
        protein: 46,
      );
      const rice = EstimateItem(
        name: 'Rice, cooked',
        grams: 200,
        kcal: 260,
        protein: 5,
      );
      final bigger = resized(chicken, 220);
      expect(
        bigger,
        const EstimateItem(
          name: 'Chicken breast, cooked',
          grams: 220,
          kcal: 364,
          protein: 67,
        ),
      );
      expect(totalOf([bigger, rice]), (kcal: 624, protein: 72));

      const oil = EstimateItem(name: 'Oil', kcal: 120);
      expect(resized(oil, 30), oil);
      expect(totalOf([oil]), (kcal: 120, protein: null));
    });

    test('keeps an item\'s options at least $optionGap kcal from it and from '
        'each other, under new names, at most 3, as plain items', () {
      EstimateItem parse(List<Object?> options) => parseEstimateItems([
        {
          'item': 'Cappuccino',
          'grams': 250,
          'kcal': 110,
          'protein_g': 7,
          'options': options,
        },
      ]).single;
      final options = [
        {
          'item': 'Cappuccino with whole milk',
          'grams': 250,
          'kcal': 150,
          'protein_g': 8,
        },
        // Too close to the item, and to the whole milk one.
        {
          'item': 'Cappuccino with skimmed milk',
          'grams': 250,
          'kcal': 90,
          'protein_g': 7,
        },
        {
          'item': 'Cappuccino with oat milk',
          'grams': 250,
          'kcal': 145,
          'protein_g': 4,
        },
        {'item': '', 'kcal': 300},
        // The item again, and a repeat, with other figures.
        {'item': 'cappuccino', 'grams': 250, 'kcal': 160, 'protein_g': 7},
        {'item': 'Cappuccino with whole milk', 'grams': 250, 'kcal': 200},
        {
          'item': 'Large cappuccino',
          'grams': 350,
          'kcal': 200,
          'protein_g': 11,
        },
        {
          'item': 'Cappuccino with syrup',
          'grams': 250,
          'kcal': 260,
          'protein_g': 7,
        },
        // A fourth.
        {
          'item': 'Cappuccino with cream',
          'grams': 280,
          'kcal': 320,
          'protein_g': 8,
        },
      ];

      final item = parse(options);
      expect(item.options, const [
        EstimateItem(
          name: 'Cappuccino with whole milk',
          grams: 250,
          kcal: 150,
          protein: 8,
        ),
        EstimateItem(
          name: 'Large cappuccino',
          grams: 350,
          kcal: 200,
          protein: 11,
        ),
        EstimateItem(
          name: 'Cappuccino with syrup',
          grams: 250,
          kcal: 260,
          protein: 7,
        ),
      ]);
      const plain = EstimateItem(
        name: 'Cappuccino',
        grams: 250,
        kcal: 110,
        protein: 7,
      );
      expect(item.settled, plain);
      expect(resized(item, 250), plain);
      expect(parse([options[1]]), plain);
      expect(parse(['not a map']), plain);
    });

    test('an option that drops a word the user said is no option', () {
      final items = parseEstimateItems([
        {
          'item': 'Large oat latte',
          'grams': 450,
          'kcal': 210,
          'protein_g': 6,
          'options': [
            {
              'item': 'Large soy latte',
              'grams': 450,
              'kcal': 150,
              'protein_g': 9,
            },
            {'item': 'Large oat latte with syrup', 'grams': 470, 'kcal': 260},
          ],
        },
      ], said: 'a large OAT latte');
      expect(items.single.options.map((option) => option.name), [
        'Large oat latte with syrup',
      ]);
    });
  });
}
