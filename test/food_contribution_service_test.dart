import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/constants/app_info.dart';
import 'package:lean_streak/services/food_contribution_service.dart';

import 'fake_functions.dart';

final ProductContribution _lyutenitsa = (
  barcode: '3800000000017',
  name: 'Лютеница',
  brand: 'Първа преса',
  quantity: '260 g',
  servingSize: null,
  per100g: {'energy-kcal': 95, 'proteins': 2.1, 'salt': 1.2},
  frontPhoto: Uint8List.fromList([1, 2]),
  labelPhoto: Uint8List.fromList([3, 4]),
  country: 'Bulgaria',
  lang: null,
);

void main() {
  test('the product goes out in its language, adding to brands', () {
    final fields = productFields(_lyutenitsa, productLanguage('Лютеница'));

    expect(fields['lc'], 'bg');
    expect(fields['lang'], 'bg');
    expect(fields['cc'], 'bg');
    expect(fields['product_name_bg'], 'Лютеница');
    expect(fields['add_brands'], 'Първа преса');
    expect(fields['add_countries'], 'en:bulgaria');
    expect(fields['quantity'], '260 g');
    expect(fields.containsKey('serving_size'), isFalse);
    expect(fields['nutrition_data_per'], '100g');
    expect(fields['nutriment_energy-kcal'], '95');
    expect(fields['nutriment_energy-kcal_unit'], 'kcal');
    expect(fields['nutriment_proteins'], '2.1');
    expect(fields['nutriment_proteins_unit'], 'g');
    expect(productLanguage('Tikka wrap'), 'en');

    final uk = productFields((
      barcode: '5000000000001',
      name: 'Tikka wrap',
      brand: null,
      quantity: null,
      servingSize: null,
      per100g: const {},
      frontPhoto: Uint8List(0),
      labelPhoto: Uint8List(0),
      country: 'England',
      lang: null,
    ), 'en');
    expect(uk['cc'], 'uk');
    expect(uk['add_countries'], 'en:united-kingdom');
    expect(uk.containsKey('add_brands'), isFalse);
    expect(uk['nutrition_data_per'], '100g');

    // A drink is per 100 ml; a country the app doesn't map is left out.
    final drink = productFields((
      barcode: '5000000000002',
      name: 'Orange juice',
      brand: null,
      quantity: '1 l',
      servingSize: '250 ml',
      per100g: const {},
      frontPhoto: Uint8List(0),
      labelPhoto: Uint8List(0),
      country: 'London, UK',
      lang: null,
    ), 'en');
    expect(drink['nutrition_data_per'], '100ml');
    expect(drink.containsKey('add_countries'), isFalse);
    expect(drink.containsKey('cc'), isFalse);
  });

  test('the function gets the details, then the front and nutrition '
      'photos', () async {
    final functions = FakeFunctions();
    final service = FoodContributionService(
      appUuid: 'install-1',
      functions: functions,
    );

    // The AI read the name as Serbian, not Bulgarian.
    await service.contribute((
      barcode: _lyutenitsa.barcode,
      name: _lyutenitsa.name,
      brand: _lyutenitsa.brand,
      quantity: _lyutenitsa.quantity,
      servingSize: _lyutenitsa.servingSize,
      per100g: _lyutenitsa.per100g,
      frontPhoto: _lyutenitsa.frontPhoto,
      labelPhoto: _lyutenitsa.labelPhoto,
      country: _lyutenitsa.country,
      lang: 'sr',
    ));

    final call = functions.calls.single;
    expect(call.name, 'contributeProduct');
    // Three requests to Open Food Facts, one after another.
    expect(call.timeout, const Duration(minutes: 2));
    final data = call.data! as Map<String, Object?>;
    expect(data['appUuid'], 'install-1');
    expect(data['appVersion'], appVersion);
    final fields = data['fields']! as Map<String, String>;
    expect(fields['code'], '3800000000017');
    expect(fields['lang'], 'sr');
    expect(fields.containsKey('password'), isFalse);
    expect(data['photos'], [
      {
        'field': 'front_sr',
        'jpeg': base64Encode([1, 2]),
      },
      {
        'field': 'nutrition_sr',
        'jpeg': base64Encode([3, 4]),
      },
    ]);
  });

  test('adding nutrition sends the figures and nothing it already has', () {
    final fields = nutritionFields((
      barcode: '3800000000024',
      lang: 'bg',
      name: null,
      servingSize: null,
      perVolume: false,
      per100g: const {'energy-kcal': 95, 'salt': 1.2},
      labelPhoto: null,
    ));
    expect(fields, {
      'code': '3800000000024',
      'nutrition_data_per': '100g',
      'nutriment_energy-kcal': '95',
      'nutriment_energy-kcal_unit': 'kcal',
      'nutriment_salt': '1.2',
      'nutriment_salt_unit': 'g',
    });

    // A product with no name or serving gets the ones the user checked.
    final drink = nutritionFields((
      barcode: '5000000000002',
      lang: 'en',
      name: 'Orange juice',
      servingSize: '250 ml',
      perVolume: true,
      per100g: const {},
      labelPhoto: null,
    ));
    expect(drink['product_name_en'], 'Orange juice');
    expect(drink['serving_size'], '250 ml');
    expect(drink['nutrition_data_per'], '100ml');
    expect(soldByVolume('1 l', null), isTrue);
    expect(soldByVolume('400 g', '30 g'), isFalse);
  });

  test('the nutrition photo goes only when the product has none', () async {
    final functions = FakeFunctions();
    final service = FoodContributionService(
      appUuid: 'install-1',
      functions: functions,
    );
    NutritionContribution withPhoto(Uint8List? photo) => (
      barcode: '3800000000024',
      lang: 'bg',
      name: null,
      servingSize: null,
      perVolume: false,
      per100g: const {'energy-kcal': 95},
      labelPhoto: photo,
    );
    List<Object?> photosSent() =>
        (functions.calls.removeLast().data! as Map)['photos'] as List<Object?>;

    await service.addNutrition(withPhoto(Uint8List.fromList([3, 4])));
    expect(photosSent(), [
      {
        'field': 'nutrition_bg',
        'jpeg': base64Encode([3, 4]),
      },
    ]);
    await service.addNutrition(withPhoto(null));
    expect(photosSent(), isEmpty);
  });

  test('a dry run sends nothing', () async {
    final functions = FakeFunctions();
    final service = FoodContributionService(
      appUuid: 'install-1',
      functions: functions,
      dryRun: true,
    );
    expect(service.isConfigured, isTrue);
    await service.contribute(_lyutenitsa);
    expect(functions.calls, isEmpty);
  });

  test('a refusal, the daily limit or a dropped connection says so', () async {
    Future<String> messageFor(Exception error) async {
      final service = FoodContributionService(
        appUuid: 'install-1',
        functions: FakeFunctions()..error = error,
      );
      try {
        await service.contribute(_lyutenitsa);
      } on FoodContributionException catch (error) {
        return error.message;
      }
      fail('nothing was thrown');
    }

    expect(
      await messageFor(
        FirebaseFunctionsException(code: 'aborted', message: ''),
      ),
      "Open Food Facts didn't accept it. Try again in a moment.",
    );
    expect(
      await messageFor(
        FirebaseFunctionsException(code: 'resource-exhausted', message: ''),
      ),
      "You've sent all you can today. You can send more tomorrow.",
    );
    for (final offline in [
      FirebaseFunctionsException(code: 'unavailable', message: ''),
      FirebaseFunctionsException(code: 'internal', message: ''),
      Exception('offline'),
    ]) {
      expect(
        await messageFor(offline),
        'Could not reach Open Food Facts. Check your connection and try '
        'again.',
      );
    }
  });
}
