import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/units_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/widgets/measure_field.dart';

import 'adaptive_fixtures.dart';

void main() {
  test('pounds and inches convert both ways', () {
    expect(kgToLb(1), closeTo(2.20462, 1e-5));
    expect(lbToKg(kgToLb(79.8)), closeTo(79.8, 1e-9));
    expect(14 * kgPerLb, closeTo(6.35, 0.001));
  });

  test('weights show in each unit', () {
    expect(formatWeight(79.8, WeightUnit.kg), '79.8 kg');
    expect(formatWeight(79.8, WeightUnit.lb), '175.9 lb');
    expect(formatWeight(79.8, WeightUnit.st), '12 st 8 lb');
    expect(formatWeight(lbToKg(168), WeightUnit.st), '12 st 0 lb');
  });

  test('a change is signed, and in stones only past a stone', () {
    expect(formatWeightChange(-0.8, WeightUnit.kg), '-0.8 kg');
    expect(formatWeightChange(1.2, WeightUnit.kg), '+1.2 kg');
    expect(formatWeightChange(-0.8, WeightUnit.lb), '-1.8 lb');
    expect(formatWeightChange(-0.8, WeightUnit.st), '-1.8 lb');
    expect(formatWeightChange(lbToKg(-16), WeightUnit.st), '-1 st 2 lb');
  });

  test('paces and heights', () {
    expect(formatPace(0.5, WeightUnit.kg), '0.5 kg');
    expect(formatPace(0.25, WeightUnit.kg), '0.25 kg');
    expect(formatPace(0.5, WeightUnit.lb), '1.1 lb');
    expect(formatPace(0.75, WeightUnit.st), '1.65 lb');
    expect(formatHeight(180, HeightUnit.cm), '180 cm');
    expect(formatHeight(180, HeightUnit.ftin), '5 ft 11 in');
  });

  test('ranges round inwards, so both ends are allowed', () {
    expect(weightRange(30, 300, WeightUnit.kg), '30–300 kg');
    expect(weightRange(30, 300, WeightUnit.lb), '67–661 lb');
    expect(weightRange(30, 300, WeightUnit.st), '4 st 11 lb–47 st 3 lb');
    expect(
      weightRange(25, 400, WeightUnit.kg, between: ' and '),
      '25 and 400 kg',
    );
    expect(heightRange(100, 250, HeightUnit.cm), '100–250 cm');
    expect(heightRange(100, 250, HeightUnit.ftin), '3 ft 4 in–8 ft 2 in');
    expect(lbToKg(67), greaterThanOrEqualTo(30));
    expect(lbToKg(661), lessThanOrEqualTo(300));
    expect(40 * cmPerInch, greaterThanOrEqualTo(100));
    expect(98 * cmPerInch, lessThanOrEqualTo(250));
  });

  test('the default follows the country', () {
    expect(defaultWeightUnitFor('United Kingdom'), WeightUnit.st);
    expect(defaultHeightUnitFor('United Kingdom'), HeightUnit.ftin);
    expect(defaultWeightUnitFor('United States'), WeightUnit.lb);
    expect(defaultHeightUnitFor('United States'), HeightUnit.ftin);
    expect(defaultWeightUnitFor('Bulgaria'), WeightUnit.kg);
    expect(defaultHeightUnitFor('Bulgaria'), HeightUnit.cm);
    expect(defaultWeightUnitFor('XX'), WeightUnit.kg);
  });

  group('the boxes', () {
    test('a stored weight comes back exactly until a box changes', () {
      final input = WeightInput(WeightUnit.st)..show(79.8);
      expect((input.whole.text, input.part.text), ('12', '7.9'));
      expect(input.value, 79.8);
      input.part.text = '8';
      expect(input.value, closeTo(lbToKg(176), 1e-9));
      input.dispose();
    });

    test('switching unit keeps the value', () {
      final input = WeightInput(WeightUnit.kg)..show(79.8);
      input.switchTo(WeightUnit.lb);
      expect(input.whole.text, '175.9');
      input.switchTo(WeightUnit.st);
      input.switchTo(WeightUnit.kg);
      expect(input.whole.text, '79.8');
      expect(input.value, 79.8);
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
      height.show(170);
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

    test('unchosen, from the country', () async {
      expect(await unitsFor('GB'), (WeightUnit.st, HeightUnit.ftin));
      expect(await unitsFor('US'), (WeightUnit.lb, HeightUnit.ftin));
      expect(await unitsFor('BG'), (WeightUnit.kg, HeightUnit.cm));
    });

    test('chosen, whatever the country', () async {
      expect(
        await unitsFor('GB', weight: WeightUnit.kg, height: HeightUnit.cm),
        (WeightUnit.kg, HeightUnit.cm),
      );
    });
  });
}
