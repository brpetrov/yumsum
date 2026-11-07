import 'package:intl/intl.dart';

import 'package:lean_streak/l10n/l10n.dart';

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

// Shown in [AppLocalizations]' language: "80.5 kg" and "180 cm" in English,
// "80,5 кг" and "180 см" in Bulgarian. Imperial units keep their Latin
// symbols in both.

String _stones(int pounds, AppLocalizations l10n) =>
    l10n.unitsStLb(pounds ~/ 14, pounds % 14);

/// [kg] as shown in [unit]: "80.0 kg", "176.4 lb" or "12 st 8 lb".
String formatWeight(double kg, WeightUnit unit, AppLocalizations l10n) =>
    switch (unit) {
      WeightUnit.kg => l10n.unitsKg(l10n.decimal(kg)),
      WeightUnit.lb => l10n.unitsLb(l10n.decimal(kgToLb(kg))),
      WeightUnit.st => _stones(kgToLb(kg).round(), l10n),
    };

/// A change of [kg], signed: "+1.2 kg", "-2.6 lb", and in stones "-1 st
/// 2 lb", or pounds alone under a stone.
String formatWeightChange(double kg, WeightUnit unit, AppLocalizations l10n) {
  final sign = kg >= 0 ? '+' : '-';
  final pounds = kgToLb(kg.abs());
  return switch (unit) {
    WeightUnit.kg => '$sign${l10n.unitsKg(l10n.decimal(kg.abs()))}',
    WeightUnit.st when pounds.round() >= 14 =>
      '$sign${_stones(pounds.round(), l10n)}',
    _ => '$sign${l10n.unitsLb(l10n.decimal(pounds))}',
  };
}

/// A pace of [kgPerWeek], without the "a week": "0.5 kg" or "1.1 lb"
/// (pounds for stones too).
String formatPace(double kgPerWeek, WeightUnit unit, AppLocalizations l10n) {
  final number = NumberFormat('0.0#', l10n.localeName);
  return unit == WeightUnit.kg
      ? l10n.unitsKg(number.format(kgPerWeek))
      : l10n.unitsLb(number.format(kgToLb(kgPerWeek)));
}

/// [cm] as shown in [unit]: "180 cm" or "5 ft 11 in".
String formatHeight(double cm, HeightUnit unit, AppLocalizations l10n) =>
    switch (unit) {
      HeightUnit.cm => l10n.unitsCm('${cm.round()}'),
      HeightUnit.ftin => _feet((cm / cmPerInch).round(), l10n),
    };

String _feet(int inches, AppLocalizations l10n) =>
    l10n.unitsFtIn(inches ~/ 12, inches % 12);

/// The range [minKg] to [maxKg] in [unit], rounded inwards so both ends are
/// allowed: "30–300 kg", "67–661 lb", "4 st 11 lb–47 st 3 lb". [between]
/// joins the ends.
String weightRange(
  double minKg,
  double maxKg,
  WeightUnit unit,
  AppLocalizations l10n, {
  String between = '–',
}) {
  if (unit == WeightUnit.kg) {
    return l10n.unitsKg('${minKg.ceil()}$between${maxKg.floor()}');
  }
  final low = kgToLb(minKg).ceil();
  final high = kgToLb(maxKg).floor();
  return unit == WeightUnit.lb
      ? l10n.unitsLb('$low$between$high')
      : '${_stones(low, l10n)}$between${_stones(high, l10n)}';
}

/// The range [minCm] to [maxCm] in [unit], rounded inwards: "100–250 cm"
/// or "3 ft 4 in–8 ft 2 in".
String heightRange(
  double minCm,
  double maxCm,
  HeightUnit unit,
  AppLocalizations l10n, {
  String between = '–',
}) => unit == HeightUnit.cm
    ? l10n.unitsCm('${minCm.ceil()}$between${maxCm.floor()}')
    : '${_feet((minCm / cmPerInch).ceil(), l10n)}$between'
          '${_feet((maxCm / cmPerInch).floor(), l10n)}';
