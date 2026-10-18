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
    test('tells setup, quota and busy errors apart', () {
      expect(
        aiErrorMessage(
          'Firebase AI Logic API has not been used in project 1 before or '
          'it is disabled. Enable it by visiting https://…',
        ),
        aiNotSwitchedOnMessage,
      );
      expect(
        aiErrorMessage('Quota exceeded for quota metric'),
        aiQuotaUsedMessage,
      );
      expect(aiErrorMessage('503 Service Unavailable'), contains('busy'));
      expect(
        aiErrorMessage('Something odd'),
        'Could not estimate calories right now.',
      );
    });
  });

  group('parseEstimateItems', () {
    test('reads the model items', () {
      expect(
        parseEstimateItems([
          {'item': 'Musaka', 'kcal': 520, 'protein_g': 28},
          {'item': ' Bread ', 'kcal': 80.4, 'protein_g': null},
        ]),
        [
          (name: 'Musaka', kcal: 520, protein: 28),
          (name: 'Bread', kcal: 80, protein: null),
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
        [(name: 'Oil', kcal: 120, protein: null)],
      );
      expect(parseEstimateItems(null), isEmpty);
      expect(parseEstimateItems('items'), isEmpty);
    });
  });
}
