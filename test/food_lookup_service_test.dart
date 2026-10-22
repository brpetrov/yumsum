import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/services/food_lookup_service.dart';

Map<String, dynamic> _reply(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

void main() {
  test('search hits: local products first, no-calorie ones dropped', () {
    final foods = parseSearchHits(
      _reply('''
      {"hits": [
        {"product_name": "Chicken Tikka Wrap", "brands": ["Daily Delight"],
          "countries_tags": ["en:united-states"],
          "nutriments": {"energy-kcal_100g": 189}},
        {"product_name": "Tikka Wrap", "nutriments": {}},
        {"product_name": "Chicken tikka wrap", "brands": ["Myprotein"],
          "countries_tags": ["en:united-kingdom"], "quantity": "175 g",
          "nutriments": {"energy-kcal_100g": 162, "proteins_100g": 12.1}}
      ]}'''),
      country: 'United Kingdom',
    );

    expect(foods.map((food) => food.brand), ['Myprotein', 'Daily Delight']);
    expect(foods.first.servingGrams, 175);
    expect(foods.first.proteinPer100g, 12);
  });

  group('parsePackagedFood', () {
    test('reads name, brand, calories, protein and the serving', () {
      final food = parsePackagedFood(
        _reply('''
        {"status": 1, "product": {
          "product_name": "Chicken Tikka Wrap", "brands": "Tesco, Tesco Finest",
          "serving_size": "1 wrap (220 g)", "quantity": "220 g",
          "nutriments": {"energy-kcal_100g": 215, "proteins_100g": 9.4}
        }}'''),
      );

      expect(food, isNotNull);
      expect(food!.name, 'Chicken Tikka Wrap');
      expect(food.brand, 'Tesco');
      expect(food.kcalPer100g, 215);
      expect(food.proteinPer100g, 9);
      expect(food.servingGrams, 220);
    });

    test('prefers the English name and drops a brand already in it', () {
      final food = parsePackagedFood(
        _reply('''
        {"product": {"product_name": "Нутела", "product_name_en": "Nutella",
          "brands": "Nutella, Ferrero", "quantity": "400 g e",
          "nutriments": {"energy-kcal_100g": 539, "proteins_100g": 6.3}}}'''),
      );

      expect(food!.name, 'Nutella');
      expect(food.brand, isNull);
      expect(food.servingGrams, 400);
    });

    test('converts kilojoules when no kcal figure is given', () {
      final food = parsePackagedFood(
        _reply('''
        {"product": {"product_name": "Oats",
          "nutriments": {"energy_100g": 1540, "proteins_100g": "11"}}}'''),
      );

      expect(food!.kcalPer100g, 368);
      expect(food.proteinPer100g, 11);
      expect(food.servingGrams, isNull);
    });

    test('is null for unknown products or ones without calories', () {
      expect(
        parsePackagedFood(_reply('{"status": 0, "status_verbose": "no code"}')),
        isNull,
      );
      expect(
        parsePackagedFood(
          _reply('{"product": {"product_name": "Mystery", "nutriments": {}}}'),
        ),
        isNull,
      );
      expect(
        parsePackagedFood(
          _reply('{"product": {"nutriments": {"energy-kcal_100g": 100}}}'),
        ),
        isNull,
      );
    });
  });

  group('gramsIn', () {
    test('finds the first amount written with its unit', () {
      expect(gramsIn('30 g'), 30);
      expect(gramsIn('30g'), 30);
      expect(gramsIn('1 wrap (220 g)'), 220);
      expect(gramsIn('4 x 25 g'), 25);
      expect(gramsIn('330 ml'), 330);
      expect(gramsIn('1,5 g'), 2);
    });

    test('ignores kilograms, bare numbers and empty labels', () {
      expect(gramsIn('1 kg'), isNull);
      expect(gramsIn('2 slices'), isNull);
      expect(gramsIn(null), isNull);
      expect(gramsIn('0 g'), isNull);
    });
  });
}
