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
          'language': 'en',
          'macros': true,
          'hour': DateTime.now().hour,
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
        'AI estimates aren\'t switched on yet.',
      );
      expect(
        await failure('failed-precondition', 'paused'),
        'AI estimates are paused for now. You can still type the calories '
        'yourself.',
      );
      expect(
        await failure('unavailable', 'busy'),
        'The AI is busy right now. Try again in a minute.',
      );
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
            {'item': 'Large oat latte with syrup', 'grams': 470, 'kcal': 300},
          ],
        },
      ], said: 'a large OAT latte');
      expect(items.single.options.map((option) => option.name), [
        'Large oat latte with syrup',
      ]);
    });

    Map<String, Object?> sarmi({
      Object? grams = 300,
      List<Object?> amounts = const [],
      List<Object?> options = const [],
    }) => {
      'item': 'Sarmi with meat',
      'grams': grams,
      'kcal': 420,
      'protein_g': 21,
      'amount': '5 pieces',
      'amounts': amounts,
      'options': options,
    };

    test('keeps an item\'s amounts at least $optionGap kcal apart and drops '
        'the assumed one', () {
      final item = parseEstimateItems([
        sarmi(
          amounts: [
            {'amount': '3 pieces', 'grams': 180},
            // The assumed weight, and under 30 kcal from it.
            {'amount': '5 pieces', 'grams': 300},
            {'amount': '5 bigger pieces', 'grams': 310},
            {'amount': '', 'grams': 400},
            {'amount': 'a lot', 'grams': 0},
            'not a map',
            {'amount': '8 pieces', 'grams': 480},
            {'amount': '10 pieces', 'grams': 600},
            // A fourth.
            {'amount': '12 pieces', 'grams': 700},
          ],
        ),
      ]).single;
      expect(item.amount, '5 pieces');
      expect(item.amounts, [
        (label: '3 pieces', grams: 180),
        (label: '8 pieces', grams: 480),
        (label: '10 pieces', grams: 600),
      ]);
      expect(item.settled.amounts, isEmpty);
      expect(item.settled.amount, isNull);
    });

    test('no amounts without a weight to scale from, or with none kept', () {
      for (final entry in [
        sarmi(
          grams: null,
          amounts: [
            {'amount': '3 pieces', 'grams': 180},
          ],
        ),
        sarmi(
          amounts: [
            {'amount': '5 bigger pieces', 'grams': 310},
          ],
        ),
      ]) {
        final item = parseEstimateItems([entry]).single;
        expect(item.amount, isNull);
        expect(item.amounts, isEmpty);
      }
    });

    test('a row that cannot move the item by askBarFor is dropped', () {
      expect(askBarFor(110), 80);
      expect(askBarFor(420), 126);
      // A cappuccino: small, large and whole milk are all under 80 kcal away.
      final cappuccino = parseEstimateItems([
        {
          'item': 'Cappuccino',
          'grams': 250,
          'kcal': 110,
          'protein_g': 7,
          'amount': 'regular',
          'amounts': [
            {'amount': 'small', 'grams': 180},
            {'amount': 'large', 'grams': 350},
          ],
          'options': [
            {'item': 'Cappuccino with whole milk', 'grams': 250, 'kcal': 150},
          ],
        },
      ]).single;
      expect(cappuccino.amount, isNull);
      expect(cappuccino.amounts, isEmpty);
      expect(cappuccino.options, isEmpty);
      // Sarmi: 3 pieces is 168 kcal under, so the row stays.
      final sarmiItem = parseEstimateItems([
        sarmi(
          amounts: [
            {'amount': '3 pieces', 'grams': 180},
          ],
          options: [
            // 100 kcal under: under a third of 420, so this row goes.
            {'item': 'Sarmi without meat', 'grams': 300, 'kcal': 320},
          ],
        ),
      ]).single;
      expect(sarmiItem.amounts, [(label: '3 pieces', grams: 180)]);
      expect(sarmiItem.options, isEmpty);
    });

    test('a sandwich, wrap or burger is never asked how much', () {
      for (final name in [
        'Tuna sandwich',
        'chicken wrap',
        'Сандвич с кашкавал',
      ]) {
        final item = parseEstimateItems([
          {
            ...sarmi(
              amounts: [
                {'amount': 'small', 'grams': 200},
                {'amount': 'large', 'grams': 400},
              ],
            ),
            'item': name,
            'amount': 'regular',
          },
        ]).single;
        expect(item.amount, isNull, reason: name);
        expect(item.amounts, isEmpty, reason: name);
      }
    });

    test('no amounts when the user said the amount, but a vague one counts '
        'as none', () {
      final three = [
        {'amount': '3 pieces', 'grams': 180},
      ];
      expect(
        parseEstimateItems([
          sarmi(amounts: three),
        ], said: '5 sarmi').single.amounts,
        isEmpty,
      );
      final soup = {
        'item': 'Tomato soup',
        'grams': 300,
        'kcal': 300,
        'amount': '1 bowl',
        'amounts': [
          {'amount': 'small bowl', 'grams': 200},
        ],
      };
      expect(
        parseEstimateItems([
          soup,
        ], said: 'a bowl of tomato soup').single.amounts,
        [(label: 'small bowl', grams: 200)],
      );
      expect(
        parseEstimateItems([
          {...soup, 'amount': 'large'},
        ], said: 'a large tomato soup').single.amounts,
        isEmpty,
      );
    });

    test('"a fried egg" is one egg; "a bowl" is still asked; chain sizes '
        'count as sizes', () {
      List<EstimateAmount> amounts(String said, String amount, String other) =>
          parseEstimateItems([
            {
              'item': said,
              'grams': 100,
              'kcal': 200,
              'amount': amount,
              'amounts': [
                {'amount': other, 'grams': 200},
              ],
            },
          ], said: said).single.amounts;
      expect(amounts('a fried egg', '1 piece', '2 pieces'), isEmpty);
      expect(amounts('a kiwi', '1', '2'), isEmpty);
      expect(amounts('една ябълка', '1 брой', '2 броя'), isEmpty);
      expect(amounts('fried eggs', '1 piece', '2 pieces'), hasLength(1));
      expect(amounts('a bowl of soup', '1 bowl', 'large bowl'), hasLength(1));
      expect(amounts('tall cappuccino', 'tall', 'grande'), isEmpty);
      expect(amounts('cappuccino', 'tall', 'grande'), hasLength(1));
    });

    test('both rows keep up to 3 besides the ticked one', () {
      final item = parseEstimateItems([
        sarmi(
          amounts: [
            {'amount': '3 pieces', 'grams': 180},
            {'amount': '8 pieces', 'grams': 480},
            {'amount': '10 pieces', 'grams': 600},
          ],
          options: [
            {'item': 'Sarmi without meat', 'grams': 300, 'kcal': 300},
            {'item': 'Sarmi with pork', 'grams': 300, 'kcal': 480},
            {'item': 'Sarmi with rice only', 'grams': 300, 'kcal': 250},
          ],
        ),
      ]).single;
      expect(item.amounts, hasLength(3));
      expect(item.options, hasLength(3));
    });

    test('a portion row is asked when small to large spans the bar, though '
        'neither alone does', () {
      // 650 kcal: the bar is 195; small is 130 under, large 160 over.
      final item = parseEstimateItems([
        {
          'item': 'Spaghetti bolognese',
          'grams': 450,
          'kcal': 650,
          'amount': 'regular',
          'amounts': [
            {'amount': 'small', 'grams': 360},
            {'amount': 'large', 'grams': 561},
          ],
        },
      ]).single;
      expect(item.amounts.map((amount) => amount.label), ['small', 'large']);
    });

    test('a typed weight or volume is an amount the user gave', () {
      final rice = {
        'item': 'Cooked basmati rice',
        'grams': 100,
        'kcal': 300,
        'amount': 'regular',
        'amounts': [
          {'amount': 'small', 'grams': 60},
          {'amount': 'large', 'grams': 150},
        ],
      };
      for (final said in [
        '100 g cooked basmati rice',
        '100g rice',
        '200 гр ориз',
      ]) {
        expect(
          parseEstimateItems([rice], said: said).single.amounts,
          isEmpty,
          reason: said,
        );
      }
      expect(
        parseEstimateItems([rice], said: 'basmati rice').single.amounts,
        hasLength(2),
      );
    });

    test('"two eggs" and "a handful" are amounts the user gave', () {
      final eggs = {
        'item': 'Scrambled eggs on toast',
        'grams': 200,
        'kcal': 380,
        'amount': '2 eggs',
        'amounts': [
          {'amount': '1 egg', 'grams': 140},
          {'amount': '3 eggs', 'grams': 260},
        ],
      };
      expect(
        parseEstimateItems([
          eggs,
        ], said: 'two scrambled eggs on toast').single.amounts,
        isEmpty,
      );
      expect(
        parseEstimateItems([eggs], said: 'две бъркани яйца').single.amounts,
        isEmpty,
      );
      expect(
        parseEstimateItems([
          {
            'item': 'Almonds',
            'grams': 28,
            'kcal': 165,
            'amount': 'a handful',
            'amounts': [
              {'amount': '14 g', 'grams': 14},
              {'amount': '56 g', 'grams': 56},
            ],
          },
        ], said: 'a handful of almonds').single.amounts,
        isEmpty,
      );
    });

    test('answered: the kind picked, at the amount picked', () {
      const without = EstimateItem(
        name: 'Sarmi without meat',
        grams: 300,
        kcal: 300,
        protein: 9,
      );
      const item = EstimateItem(
        name: 'Sarmi with meat',
        grams: 300,
        kcal: 420,
        protein: 21,
        amount: '5 pieces',
        amounts: [(label: '3 pieces', grams: 180)],
        options: [without],
      );
      expect(answered(item), item.settled);
      expect(answered(item, kind: without), without);
      expect(answered(item, grams: 180), resized(item, 180));
      expect(
        answered(item, kind: without, grams: 180),
        const EstimateItem(
          name: 'Sarmi without meat',
          grams: 180,
          kcal: 180,
          protein: 5,
        ),
      );
      // A kind at another weight keeps its own weight in the same ratio.
      const large = EstimateItem(name: 'Large sarmi', grams: 400, kcal: 600);
      expect(
        answered(item, kind: large, grams: 150),
        const EstimateItem(name: 'Large sarmi', grams: 200, kcal: 300),
      );
    });
  });
}
