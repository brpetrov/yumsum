import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/units_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/widgets/measure_field.dart';

import 'adaptive_fixtures.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final bg = lookupAppLocalizations(const Locale('bg'));

  test('pounds and inches convert both ways', () {
    expect(kgToLb(1), closeTo(2.20462, 1e-5));
    expect(lbToKg(kgToLb(79.8)), closeTo(79.8, 1e-9));
    expect(14 * kgPerLb, closeTo(6.35, 0.001));
  });

  test('weights show in each unit', () {
    expect(formatWeight(79.8, WeightUnit.kg, en), '79.8 kg');
    expect(formatWeight(79.8, WeightUnit.lb, en), '175.9 lb');
    expect(formatWeight(79.8, WeightUnit.st, en), '12 st 8 lb');
    expect(formatWeight(lbToKg(168), WeightUnit.st, en), '12 st 0 lb');
  });

  test('a change is signed, and in stones only past a stone', () {
    expect(formatWeightChange(-0.8, WeightUnit.kg, en), '-0.8 kg');
    expect(formatWeightChange(1.2, WeightUnit.kg, en), '+1.2 kg');
    expect(formatWeightChange(-0.8, WeightUnit.lb, en), '-1.8 lb');
    expect(formatWeightChange(-0.8, WeightUnit.st, en), '-1.8 lb');
    expect(formatWeightChange(lbToKg(-16), WeightUnit.st, en), '-1 st 2 lb');
  });

  test('paces', () {
    expect(formatPace(0.5, WeightUnit.kg, en), '0.5 kg');
    expect(formatPace(0.25, WeightUnit.kg, en), '0.25 kg');
    expect(formatPace(0.5, WeightUnit.lb, en), '1.1 lb');
    expect(formatPace(0.75, WeightUnit.st, en), '1.65 lb');
  });

  test('in Bulgarian: decimal commas, кг and см, imperial symbols kept', () {
    expect(formatWeight(80.5, WeightUnit.kg, bg), '80,5 кг');
    expect(formatWeight(79.8, WeightUnit.lb, bg), '175,9 lb');
    expect(formatWeight(79.8, WeightUnit.st, bg), '12 st 8 lb');
    expect(formatWeightChange(-0.8, WeightUnit.kg, bg), '-0,8 кг');
    expect(formatPace(0.25, WeightUnit.kg, bg), '0,25 кг');
    expect(formatPace(0.75, WeightUnit.st, bg), '1,65 lb');
    expect(weightRange(30, 300, WeightUnit.kg, bg), '30–300 кг');
    expect(heightRange(100, 250, HeightUnit.cm, bg), '100–250 см');
  });

  test('ranges round inwards, so both ends are allowed', () {
    expect(weightRange(30, 300, WeightUnit.kg, en), '30–300 kg');
    expect(weightRange(30, 300, WeightUnit.lb, en), '67–661 lb');
    expect(weightRange(30, 300, WeightUnit.st, en), '4 st 11 lb–47 st 3 lb');
    expect(
      weightRange(25, 400, WeightUnit.kg, en, between: ' and '),
      '25 and 400 kg',
    );
    expect(heightRange(100, 250, HeightUnit.cm, en), '100–250 cm');
    expect(heightRange(100, 250, HeightUnit.ftin, en), '3 ft 4 in–8 ft 2 in');
    expect(lbToKg(67), greaterThanOrEqualTo(30));
    expect(lbToKg(661), lessThanOrEqualTo(300));
    expect(40 * cmPerInch, greaterThanOrEqualTo(100));
    expect(98 * cmPerInch, lessThanOrEqualTo(250));
  });

  group('the boxes', () {
    test('a stored weight comes back exactly until a box changes', () {
      final input = WeightInput(WeightUnit.st)..show(79.8, en);
      expect((input.whole.text, input.part.text), ('12', '7.9'));
      expect(input.value, 79.8);
      input.part.text = '8';
      expect(input.value, closeTo(lbToKg(176), 1e-9));
      input.dispose();
    });

    test('switching unit keeps the value', () {
      final input = WeightInput(WeightUnit.kg)..show(79.8, en);
      input.switchTo(WeightUnit.lb, en);
      expect(input.whole.text, '175.9');
      input.switchTo(WeightUnit.st, en);
      input.switchTo(WeightUnit.kg, en);
      expect(input.whole.text, '79.8');
      expect(input.value, 79.8);
      input.dispose();
    });

    test('in Bulgarian the boxes show a decimal comma', () {
      final input = WeightInput(WeightUnit.kg)..show(79.8, bg);
      expect(input.whole.text, '79,8');
      expect(input.value, 79.8);
      input.whole.text = '80,5';
      expect(input.value, 80.5);
      input.switchTo(WeightUnit.st, bg);
      expect((input.whole.text, input.part.text), ('12', '9,5'));
      input.dispose();
    });

    test('stones and feet: an empty second box is nought', () {
      final weight = WeightInput(WeightUnit.st);
      expect(weight.value, isNull);
      weight.whole.text = '12';
      expect(weight.value, closeTo(lbToKg(168), 1e-9));
      final height = HeightInput(HeightUnit.ftin);
      height.whole.text = '5';
      height.part.text = '7';
      expect(height.value, closeTo(67 * cmPerInch, 1e-9));
      height.show(170, en);
      expect((height.whole.text, height.part.text), ('5', '6.9'));
      weight.dispose();
      height.dispose();
    });

    test('one box parses as it is, in its unit', () {
      final input = WeightInput(WeightUnit.lb);
      input.whole.text = '176';
      expect(input.value, closeTo(lbToKg(176), 1e-9));
      input.whole.text = '85,2';
      expect(input.value, closeTo(lbToKg(85.2), 1e-9));
      input.whole.text = 'x';
      expect(input.value, isNull);
      input.dispose();
    });
  });

  test('the units survive a save and load', () {
    final profile = planProfile().copyWith(
      weightUnit: WeightUnit.st,
      heightUnit: HeightUnit.ftin,
    );
    final data = profile.toFirestore();
    expect(data['weightUnit'], 'st');
    expect(data['heightUnit'], 'ftin');
    final loaded = UserProfile.fromMap(data);
    expect(loaded.weightUnit, WeightUnit.st);
    expect(loaded.heightUnit, HeightUnit.ftin);

    // Never chosen: nothing stored, and null back.
    final unset = UserProfile.fromMap(
      data
        ..remove('weightUnit')
        ..remove('heightUnit'),
    );
    expect(unset.weightUnit, isNull);
    expect(unset.heightUnit, isNull);
  });

  group('the units in use', () {
    Future<(WeightUnit, HeightUnit)> unitsFor(
      String? region, {
      WeightUnit? weight,
      HeightUnit? height,
    }) async {
      final profile = UserProfile.fromMap(
        planProfile().toFirestore()
          ..remove('weightUnit')
          ..remove('heightUnit'),
      ).copyWith(weightUnit: weight, heightUnit: height);
      final container = ProviderContainer(
        overrides: [
          deviceRegionProvider.overrideWithValue(region),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(weightUnitProvider, (_, _) {});
      container.listen(heightUnitProvider, (_, _) {});
      await container.read(userProfileProvider.future);
      return (
        container.read(weightUnitProvider),
        container.read(heightUnitProvider),
      );
    }

    test('unchosen, kg and cm wherever the user is', () async {
      expect(await unitsFor('GB'), (WeightUnit.kg, HeightUnit.cm));
      expect(await unitsFor('US'), (WeightUnit.kg, HeightUnit.cm));
      expect(await unitsFor('BG'), (WeightUnit.kg, HeightUnit.cm));
    });

    test('chosen, whatever the country', () async {
      expect(
        await unitsFor('BG', weight: WeightUnit.st, height: HeightUnit.ftin),
        (WeightUnit.st, HeightUnit.ftin),
      );
    });
  });
}
