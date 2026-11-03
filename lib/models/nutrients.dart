/// The rest of a food label beside calories and protein, in grams: fat,
/// saturates, carbohydrate (without fibre, as UK labels give it), sugars,
/// fibre and salt (never sodium). Each is null when unknown.
class Nutrients {
  const Nutrients({
    this.fat,
    this.saturates,
    this.carbs,
    this.sugars,
    this.fibre,
    this.salt,
  });

  final double? fat;
  final double? saturates;
  final double? carbs;
  final double? sugars;
  final double? fibre;
  final double? salt;

  List<double?> get _values => [fat, saturates, carbs, sugars, fibre, salt];

  static const _fields = [
    'fatGrams',
    'saturatesGrams',
    'carbsGrams',
    'sugarsGrams',
    'fibreGrams',
    'saltGrams',
  ];

  static Nutrients? _of(List<double?> values) => values.every((v) => v == null)
      ? null
      : Nutrients(
          fat: values[0],
          saturates: values[1],
          carbs: values[2],
          sugars: values[3],
          fibre: values[4],
          salt: values[5],
        );

  /// Reads the flat fields a meal or a daily summary stores; null when it
  /// has none.
  static Nutrients? fromFields(Map<String, dynamic> data) =>
      _of([for (final field in _fields) (data[field] as num?)?.toDouble()]);

  /// The known values only, to 0.1 g, for a Firestore document.
  Map<String, double> toFields() => {
    for (final (i, value) in _values.indexed)
      if (value != null) _fields[i]: (value * 10).round() / 10,
  };

  /// Every figure times [factor], for portions and changed calories.
  Nutrients scaled(double factor) {
    double? scale(double? value) => value == null ? null : value * factor;
    return Nutrients(
      fat: scale(fat),
      saturates: scale(saturates),
      carbs: scale(carbs),
      sugars: scale(sugars),
      fibre: scale(fibre),
      salt: scale(salt),
    );
  }

  /// Each nutrient summed over the entries that have it; null when none
  /// has any.
  static Nutrients? total(Iterable<Nutrients?> all) {
    final known = all.nonNulls.toList();
    return _of([
      for (var i = 0; i < _fields.length; i++)
        known
            .map((n) => n._values[i])
            .nonNulls
            .fold<double?>(null, (sum, value) => (sum ?? 0) + value),
    ]);
  }
}

/// Reads Open Food Facts' nutrient ids from [map]: a product's `nutriments`
/// (with [suffix] `_100g`) or a label reading's figures. Salt falls back to
/// sodium × 2.5, the UK labelling rule. Null when none is there.
Nutrients? nutrientsFromOff(Map<dynamic, dynamic> map, {String suffix = ''}) {
  double? read(String id) => switch (map['$id$suffix']) {
    final num n when n >= 0 => n.toDouble(),
    final String s => switch (double.tryParse(s)) {
      final double n when n >= 0 => n,
      _ => null,
    },
    _ => null,
  };
  final sodium = read('sodium');
  return Nutrients._of([
    read('fat'),
    read('saturated-fat'),
    read('carbohydrates'),
    read('sugars'),
    read('fiber'),
    read('salt') ?? (sodium == null ? null : sodium * 2.5),
  ]);
}
