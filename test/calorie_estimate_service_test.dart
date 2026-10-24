import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

void main() {
  group('nutritionContext', () {
    test('names the country and the usual food', () {
      final context = nutritionContext(
        country: 'Bulgaria',
        usualFood: ' vegetarian home cooking ',
      );
      expect(
        context,
        startsWith(
          'You are a nutrition assistant. The user lives in Bulgaria and '
          'often eats vegetarian home cooking.',
        ),
      );
      expect(context, isNot(contains('UK')));
    });

    test('leaves the food out when none is given', () {
      expect(
        nutritionContext(country: 'Germany', usualFood: ''),
        startsWith(
          'You are a nutrition assistant. The user lives in Germany. Read',
        ),
      );
    });
  });

  group('aiErrorMessage', () {
    test('tells setup, paused, quota and busy errors apart', () {
      expect(
        aiErrorMessage(
          'Firebase AI Logic API has not been used in project 1 before or '
          'it is disabled. Enable it by visiting https://…',
        ),
        aiNotSwitchedOnMessage,
      );
      expect(aiErrorMessage('Quota exceeded for quota metric'), aiBusyMessage);
      expect(
        aiErrorMessage('Your prepayment credits are depleted.'),
        aiPausedMessage,
      );
      expect(aiErrorMessage('503 Service Unavailable'), contains('busy'));
      expect(
        aiErrorMessage('Something odd'),
        'Could not estimate calories right now.',
      );
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
        [
          (name: 'Musaka', grams: 350, kcal: 520, protein: 28),
          (name: 'Bread', grams: null, kcal: 80, protein: null),
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
        [(name: 'Oil', grams: null, kcal: 120, protein: null)],
      );
      expect(parseEstimateItems(null), isEmpty);
      expect(parseEstimateItems('items'), isEmpty);
    });

    test('a corrected weight rescales the item, and the totals follow', () {
      const chicken = (
        name: 'Chicken breast, cooked',
        grams: 150,
        kcal: 248,
        protein: 46,
      );
      const rice = (name: 'Rice, cooked', grams: 200, kcal: 260, protein: 5);
      final bigger = resized(chicken, 220);
      expect(bigger, (
        name: 'Chicken breast, cooked',
        grams: 220,
        kcal: 364,
        protein: 67,
      ));
      expect(totalOf([bigger, rice]), (kcal: 624, protein: 72));

      const oil = (name: 'Oil', grams: null, kcal: 120, protein: null);
      expect(resized(oil, 30), oil);
      expect(totalOf([oil]), (kcal: 120, protein: null));
    });
  });
}
