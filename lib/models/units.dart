import 'package:intl/intl.dart';

/// How weights are shown and typed. Stored weights are always in kg.
enum WeightUnit {
  kg('kg'),
  lb('lb'),
  st('st');

  const WeightUnit(this.value);
  final String value;

  static WeightUnit? tryParse(String? s) =>
      values.where((unit) => unit.value == s).firstOrNull;
}

/// How heights are shown and typed. Stored heights are always in cm.
enum HeightUnit {
  cm('cm'),
  ftin('ftin');

  const HeightUnit(this.value);
  final String value;

  static HeightUnit? tryParse(String? s) =>
      values.where((unit) => unit.value == s).firstOrNull;
}

const kgPerLb = 0.45359237;
const cmPerInch = 2.54;

double kgToLb(double kg) => kg / kgPerLb;
double lbToKg(double lb) => lb * kgPerLb;

/// The units for a profile that hasn't chosen, from its [country] (as
/// `countryNameFor` names it): stones and feet in the UK, pounds and feet
/// in the US, metric anywhere else.
WeightUnit defaultWeightUnitFor(String country) => switch (country) {
  'United Kingdom' => WeightUnit.st,
  'United States' => WeightUnit.lb,
  _ => WeightUnit.kg,
};

HeightUnit defaultHeightUnitFor(String country) => switch (country) {
  'United Kingdom' || 'United States' => HeightUnit.ftin,
  _ => HeightUnit.cm,
};

String _stones(int pounds) => '${pounds ~/ 14} st ${pounds % 14} lb';

/// [kg] as shown in [unit]: "80.0 kg", "176.4 lb" or "12 st 8 lb".
String formatWeight(double kg, WeightUnit unit) => switch (unit) {
  WeightUnit.kg => '${kg.toStringAsFixed(1)} kg',
  WeightUnit.lb => '${kgToLb(kg).toStringAsFixed(1)} lb',
  WeightUnit.st => _stones(kgToLb(kg).round()),
};

/// A change of [kg], signed: "+1.2 kg", "-2.6 lb", and in stones "-1 st
/// 2 lb", or pounds alone under a stone.
String formatWeightChange(double kg, WeightUnit unit) {
  final sign = kg >= 0 ? '+' : '-';
  final pounds = kgToLb(kg.abs());
  return switch (unit) {
    WeightUnit.kg => '$sign${kg.abs().toStringAsFixed(1)} kg',
    WeightUnit.st when pounds.round() >= 14 =>
      '$sign${_stones(pounds.round())}',
    _ => '$sign${pounds.toStringAsFixed(1)} lb',
  };
}

/// A pace of [kgPerWeek], without the "a week": "0.5 kg" or "1.1 lb"
/// (pounds for stones too).
String formatPace(double kgPerWeek, WeightUnit unit) {
  final number = NumberFormat('0.0#');
  return unit == WeightUnit.kg
      ? '${number.format(kgPerWeek)} kg'
      : '${number.format(kgToLb(kgPerWeek))} lb';
}

/// [cm] as shown in [unit]: "180 cm" or "5 ft 11 in".
String formatHeight(double cm, HeightUnit unit) => switch (unit) {
  HeightUnit.cm => '${cm.round()} cm',
  HeightUnit.ftin => _feet((cm / cmPerInch).round()),
};

String _feet(int inches) => '${inches ~/ 12} ft ${inches % 12} in';

/// The range [minKg] to [maxKg] in [unit], rounded inwards so both ends are
/// allowed: "30–300 kg", "67–661 lb", "4 st 11 lb–47 st 3 lb". [between]
/// joins the ends.
String weightRange(
  double minKg,
  double maxKg,
  WeightUnit unit, {
  String between = '–',
}) {
  if (unit == WeightUnit.kg) {
    return '${minKg.ceil()}$between${maxKg.floor()} kg';
  }
  final low = kgToLb(minKg).ceil();
  final high = kgToLb(maxKg).floor();
  return unit == WeightUnit.lb
      ? '$low$between$high lb'
      : '${_stones(low)}$between${_stones(high)}';
}

/// The range [minCm] to [maxCm] in [unit], rounded inwards: "100–250 cm"
/// or "3 ft 4 in–8 ft 2 in".
String heightRange(
  double minCm,
  double maxCm,
  HeightUnit unit, {
  String between = '–',
}) => unit == HeightUnit.cm
    ? '${minCm.ceil()}$between${maxCm.floor()} cm'
    : '${_feet((minCm / cmPerInch).ceil())}$between'
          '${_feet((maxCm / cmPerInch).floor())}';
