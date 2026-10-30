import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lean_streak/services/food_contribution_service.dart';

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

  test('details first, then the front and nutrition photos', () async {
    final sent = <http.Request>[];
    final service = FoodContributionService(
      appUuid: 'install-1',
      userId: 'leanstreak-app',
      password: 'secret',
      host: 'world.openfoodfacts.net',
      client: MockClient((request) async {
        sent.add(request);
        // Details reply with a number, photos with words.
        return request.url.path.endsWith('jqm2.pl')
            ? http.Response('{"status": 1}', 200)
            : http.Response('{"status": "status ok", "imgid": 1}', 200);
      }),
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

    expect(sent.map((request) => request.url.path), [
      '/cgi/product_jqm2.pl',
      '/cgi/product_image_upload.pl',
      '/cgi/product_image_upload.pl',
    ]);
    final details = sent.first.bodyFields;
    expect(details['user_id'], 'leanstreak-app');
    expect(details['app_uuid'], 'install-1');
    expect(details['code'], '3800000000017');
    expect(details['comment'], contains('install-1'));
    // The test server's own shared password.
    expect(
      sent.first.headers['Authorization'],
      'Basic ${base64Encode(utf8.encode('off:off'))}',
    );
    final front = utf8.decode(sent[1].bodyBytes, allowMalformed: true);
    expect(details['lang'], 'sr');
    expect(front, contains('front_sr'));
    expect(front, contains('name="imgupload_front_sr"'));
    final label = utf8.decode(sent[2].bodyBytes, allowMalformed: true);
    expect(label, contains('nutrition_sr'));
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
    final paths = <String>[];
    final service = FoodContributionService(
      appUuid: 'install-1',
      userId: 'yumsum-app',
      password: 'secret',
      client: MockClient((request) async {
        paths.add(request.url.path);
        return request.url.path.endsWith('jqm2.pl')
            ? http.Response('{"status": 1}', 200)
            : http.Response('{"status": "status ok", "imgid": 1}', 200);
      }),
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

    await service.addNutrition(withPhoto(Uint8List.fromList([3, 4])));
    expect(paths, ['/cgi/product_jqm2.pl', '/cgi/product_image_upload.pl']);
    paths.clear();
    await service.addNutrition(withPhoto(null));
    expect(paths, ['/cgi/product_jqm2.pl']);
  });

  test('a dry run sends nothing, even without an account', () async {
    final service = FoodContributionService(
      appUuid: 'install-1',
      userId: '',
      password: '',
      dryRun: true,
      client: MockClient((_) async => fail('nothing should be sent')),
    );
    expect(service.isConfigured, isTrue);
    await service.contribute(_lyutenitsa);
  });

  test('a refusal or a dropped connection says so', () async {
    FoodContributionService replying(Future<http.Response> Function() reply) =>
        FoodContributionService(
          appUuid: 'install-1',
          userId: 'leanstreak-app',
          password: 'secret',
          client: MockClient((_) => reply()),
        );

    await expectLater(
      replying(
        () async => http.Response('{"status": 0}', 200),
      ).contribute(_lyutenitsa),
      throwsA(isA<FoodContributionException>()),
    );
    // A wrong account password: an HTML page, not JSON.
    await expectLater(
      replying(
        () async => http.Response('<html>Incorrect user name</html>', 403),
      ).contribute(_lyutenitsa),
      throwsA(isA<FoodContributionException>()),
    );
    await expectLater(
      replying(
        () async => throw http.ClientException('offline'),
      ).contribute(_lyutenitsa),
      throwsA(isA<FoodContributionException>()),
    );
    expect(
      FoodContributionService(
        appUuid: 'x',
        userId: '',
        password: '',
      ).isConfigured,
      isFalse,
    );
  });
}
