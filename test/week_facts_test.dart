import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/week_facts.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/user_profile.dart';

import 'adaptive_fixtures.dart';

DailySummary _day(
  String date,
  int kcal, {
  int target = 1900,
  bool dayOff = false,
}) {
  final ratio = (kcal - target).abs() / target;
  return DailySummary(
    date: date,
    totalCalories: kcal,
    targetCalories: target,
    calorieDelta: kcal - target,
    mealCount: 4,
    status: ratio <= 0.10
        ? DailyStatus.green
        : ratio <= 0.20
        ? DailyStatus.yellow
        : DailyStatus.red,
    dayOff: dayOff,
    updatedAt: DateTime(2026, 11, 2),
  );
}

/// A week's summaries from Monday [monday], one figure a day (null: not
/// logged), with [off] the weekdays (1 to 7) taken off.
List<DailySummary> _week(
  DateTime monday,
  List<int?> kcal, {
  Set<int> off = const {},
}) => [
  for (var i = 0; i < 7; i++)
    if (kcal[i] case final value?)
      _day(
        _key(DateTime(monday.year, monday.month, monday.day + i)),
        value,
        dayOff: off.contains(i + 1),
      ),
];

String _key(DateTime day) =>
    '${day.year}-${'${day.month}'.padLeft(2, '0')}-'
    '${'${day.day}'.padLeft(2, '0')}';

Meal _meal(
  String date,
  int slot,
  String name, {
  double? protein,
  Nutrients? macros,
  DateTime? createdAt,
}) {
  final day = DateTime.parse(date);
  final at = DateTime(day.year, day.month, day.day, 8 + 4 * slot);
  return Meal(
    id: '$date-$slot',
    date: date,
    timestamp: at,
    name: name,
    calories: 400,
    proteinGrams: protein,
    macros: macros,
    createdAt: createdAt ?? at,
    updatedAt: at,
  );
}

/// One day's four meals: breakfast first, then lunch, dinner and a snack,
/// adding up to the day's [protein] and nutrients. Breakfast and lunch have
/// set figures; dinner and the snack share the rest. [noMacros] leaves the
/// snack's out; [addedNextDay] logs dinner the day after.
List<Meal> _dayMeals(
  String date, {
  required String breakfast,
  required double? firstProtein,
  required double protein,
  required String lunch,
  required double lunchSalt,
  required double fibre,
  required double salt,
  required double sugars,
  required double saturates,
  bool noMacros = false,
  bool addedNextDay = false,
}) {
  final weekday = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][DateTime.parse(date).weekday - 1];
  final rest = (protein - (firstProtein ?? 0)) / 3;
  final half = Nutrients(
    fat: 10,
    saturates: (saturates - 9) / 2,
    carbs: 50,
    sugars: (sugars - 20) / 2,
    fibre: (fibre - 6) / 2,
    salt: (salt - 0.3 - lunchSalt) / 2,
  );
  final day = DateTime.parse(date);
  return [
    _meal(
      date,
      0,
      breakfast,
      protein: firstProtein,
      macros: const Nutrients(
        fat: 8,
        saturates: 3,
        carbs: 40,
        sugars: 15,
        fibre: 3,
        salt: 0.3,
      ),
    ),
    _meal(
      date,
      1,
      lunch,
      protein: rest,
      macros: Nutrients(
        fat: 12,
        saturates: 6,
        carbs: 45,
        sugars: 5,
        fibre: 3,
        salt: lunchSalt,
      ),
    ),
    _meal(
      date,
      2,
      'Dinner on $weekday',
      protein: rest,
      macros: half,
      createdAt: addedNextDay
          ? DateTime(day.year, day.month, day.day + 1, 9)
          : null,
    ),
    _meal(
      date,
      3,
      'Snack on $weekday',
      protein: rest,
      macros: noMacros ? null : half,
    ),
  ];
}

Recipe _recipe(
  String id,
  String name,
  RecipeCategory category, {
  required int kcal,
  required int protein,
  required double fibre,
  required double salt,
}) => Recipe(
  id: id,
  name: name,
  cuisine: 'British',
  category: category,
  tags: const [],
  servings: 2,
  minutes: 20,
  prepMinutes: 10,
  kcalPerPortion: kcal,
  proteinPerPortion: protein,
  macrosPerPortion: Nutrients(
    fat: 10,
    saturates: 3,
    carbs: 30,
    sugars: 8,
    fibre: fibre,
    salt: salt,
  ),
  ingredients: const [
    (item: 'Oats', amount: '80 g', kcal: null, protein: null, macros: null),
  ],
  steps: const ['Mix.'],
);

final _recipes = [
  _recipe(
    'menemen',
    'Menemen',
    RecipeCategory.breakfast,
    kcal: 443,
    protein: 29,
    fibre: 7.8,
    salt: 2,
  ),
  _recipe(
    'pea-and-ham-soup',
    'Pea and ham soup',
    RecipeCategory.lunch,
    kcal: 297,
    protein: 27,
    fibre: 10.8,
    salt: 2.8,
  ),
  _recipe(
    'lighter-full-english',
    'Lighter full English',
    RecipeCategory.breakfast,
    kcal: 408,
    protein: 36,
    fibre: 8.6,
    salt: 2.9,
  ),
  _recipe(
    'skyr-overnight-oats',
    'Skyr overnight oats',
    RecipeCategory.breakfast,
    kcal: 417,
    protein: 28,
    fibre: 9.8,
    salt: 0.3,
  ),
  _recipe(
    'cod-chorizo-white-beans',
    'Cod with chorizo and white beans',
    RecipeCategory.dinner,
    kcal: 375,
    protein: 44,
    fibre: 10,
    salt: 1.8,
  ),
  _recipe(
    'chilli-edamame',
    'Chilli edamame',
    RecipeCategory.snack,
    kcal: 186,
    protein: 17,
    fibre: 7.6,
    salt: 1,
  ),
  _recipe(
    'greek-yoghurt-berry-bowl',
    'Greek yoghurt berry bowl',
    RecipeCategory.breakfast,
    kcal: 332,
    protein: 30,
    fibre: 6.1,
    salt: 0.3,
  ),
  _recipe(
    'tuna-white-bean-salad',
    'Tuna and white bean salad',
    RecipeCategory.lunch,
    kcal: 327,
    protein: 37,
    fibre: 9.8,
    salt: 1.6,
  ),
  _recipe(
    'quark-pancakes',
    'Quark pancakes',
    RecipeCategory.breakfast,
    kcal: 345,
    protein: 26,
    fibre: 3.7,
    salt: 0.5,
  ),
];

/// A woman with a 70 kg goal who trains once or twice a week: a 112 g
/// protein target and a 1,200 kcal minimum.
final _profile = planProfile(
  gender: Gender.female,
  targetKg: 70,
  training: TrainingFrequency.oneToTwo,
);

// The plan's example: 26 October to 1 November 2026, a big weekend, a
// light breakfast, too much salt and too little fibre.
final _monday = DateTime(2026, 10, 26);

final _summaries = [
  ..._week(DateTime(2026, 10, 5), [1800, 1850, 1900, null, 2000, 2400, null]),
  ..._week(DateTime(2026, 10, 12), [1850, 1900, null, 1950, 2300, null, 2100]),
  ..._week(DateTime(2026, 10, 19), [1900, null, 1850, null, 2050, 2500, 2200]),
  ..._week(_monday, [1846, 1921, 1778, 1884, 2012, 2705, 2448]),
];

final _meals = [
  ..._dayMeals(
    '2026-10-26',
    breakfast: 'Porridge with banana',
    firstProtein: 10,
    protein: 80,
    lunch: 'Ham and cheese toastie',
    lunchSalt: 1.8,
    fibre: 15,
    salt: 8.1,
    sugars: 55,
    saturates: 18,
  ),
  ..._dayMeals(
    '2026-10-27',
    breakfast: 'Toast with jam',
    firstProtein: 12,
    protein: 85,
    lunch: 'Jacket potato with beans',
    lunchSalt: 1.0,
    fibre: 18,
    salt: 5.2,
    sugars: 60,
    saturates: 22,
  ),
  ..._dayMeals(
    '2026-10-28',
    breakfast: 'Skyr with honey',
    firstProtein: 27,
    protein: 90,
    lunch: 'Ham and cheese toastie',
    lunchSalt: 1.7,
    fibre: 20,
    salt: 9.0,
    sugars: 90,
    saturates: 17,
  ),
  ..._dayMeals(
    '2026-10-29',
    breakfast: 'Cereal with milk',
    firstProtein: 11,
    protein: 82,
    lunch: 'Chicken noodle soup',
    lunchSalt: 1.9,
    fibre: 16,
    salt: 7.5,
    sugars: 58,
    saturates: 24,
    addedNextDay: true,
  ),
  ..._dayMeals(
    '2026-10-30',
    breakfast: 'Toast with jam',
    firstProtein: 11,
    protein: 86,
    lunch: 'Chicken noodle soup',
    lunchSalt: 1.9,
    fibre: 17,
    salt: 5.8,
    sugars: 50,
    saturates: 16,
  ),
  ..._dayMeals(
    '2026-10-31',
    breakfast: 'Bagel with cream cheese',
    firstProtein: 12,
    protein: 115,
    lunch: 'Ham and cheese toastie',
    lunchSalt: 1.7,
    fibre: 16,
    salt: 8.8,
    sugars: 53,
    saturates: 17,
  ),
  ..._dayMeals(
    '2026-11-01',
    breakfast: 'Pancakes',
    firstProtein: 12,
    protein: 78,
    lunch: 'Roast chicken',
    lunchSalt: 1.2,
    fibre: 15,
    salt: 6.0,
    sugars: 60,
    saturates: 20,
    noMacros: true,
  ),
];

WeekFacts _facts({
  DateTime? monday,
  List<DailySummary>? summaries,
  List<Meal>? meals,
  int weighIns = 3,
  UserProfile? profile,
  String country = 'United Kingdom',
  List<Recipe>? recipes,
}) => buildWeekFacts(
  monday: monday ?? _monday,
  summaries: summaries ?? _summaries,
  meals: meals ?? _meals,
  weighIns: weighIns,
  profile: profile ?? _profile,
  country: country,
  recipes: recipes ?? _recipes,
);

/// [lines] starting with [prefix].
Iterable<String> _starting(List<String> lines, String prefix) =>
    lines.where((line) => line.startsWith(prefix));

/// The last line: the whole library, by id.
const _library =
    'Recipes in the app\'s library, per portion: '
    '"Chilli edamame" (snack; 186 kcal; 17 g protein; 8 g fibre; 1 g salt; '
    '8 g sugars; 3 g saturates); '
    '"Cod with chorizo and white beans" (dinner; 375 kcal; 44 g protein; '
    '10 g fibre; 1.8 g salt; 8 g sugars; 3 g saturates); '
    '"Greek yoghurt berry bowl" (breakfast; 332 kcal; 30 g protein; 6 g '
    'fibre; 0.3 g salt; 8 g sugars; 3 g saturates); '
    '"Lighter full English" (breakfast; 408 kcal; 36 g protein; 9 g fibre; '
    '2.9 g salt; 8 g sugars; 3 g saturates); '
    '"Menemen" (breakfast; 443 kcal; 29 g protein; 8 g fibre; 2 g salt; '
    '8 g sugars; 3 g saturates); '
    '"Pea and ham soup" (lunch; 297 kcal; 27 g protein; 11 g fibre; 2.8 g '
    'salt; 8 g sugars; 3 g saturates); '
    '"Quark pancakes" (breakfast; 345 kcal; 26 g protein; 4 g fibre; 0.5 g '
    'salt; 8 g sugars; 3 g saturates); '
    '"Skyr overnight oats" (breakfast; 417 kcal; 28 g protein; 10 g fibre; '
    '0.3 g salt; 8 g sugars; 3 g saturates); '
    '"Tuna and white bean salad" (lunch; 327 kcal; 37 g protein; 10 g '
    'fibre; 1.6 g salt; 8 g sugars; 3 g saturates).';

void main() {
  test('the plan\'s example week, line by line', () {
    final facts = _facts();
    expect(facts.judgedDays, 7);
    expect(facts.lines, [
      'The user lives in United Kingdom.',
      'Week: Monday 26 October to Sunday 1 November.',
      'On track means within 10% of the daily target; close means within '
          '20%.',
      'Logged 7 of 7 days.',
      'Daily calorie target: 1,900 kcal. Minimum: 1,200 kcal a day.',
      'Already on the card: 5 days on track, 0 close, 2 off track; average '
          '2,085 kcal.',
      'Day by day: Monday 1,846 kcal (on track, 54 under); Tuesday 1,921 '
          'kcal (on track, 21 over); Wednesday 1,778 kcal (on track, 122 '
          'under); Thursday 1,884 kcal (on track, 16 under); Friday 2,012 '
          'kcal (on track, 112 over); Saturday 2,705 kcal (off track, 805 '
          'over); Sunday 2,448 kcal (off track, 548 over).',
      'Weekdays averaged 1,890 kcal; the weekend averaged 2,580 kcal.',
      'Every weekday logged was on track.',
      'Biggest day: Saturday, 2,705 kcal.',
      'Saturday was the biggest day in 3 of the last 4 weeks.',
      'Last week averaged 2,100 kcal over 5 days logged; this week is 15 '
          'kcal a day lower.',
      'Protein target: 112 g a day. Averaged 88 g on the 7 days with protein '
          'for every meal; reached on 1 day.',
      'The first meal of the day averaged 14 g of protein, on 6 days.',
      'Recipes from the app\'s library: "Greek yoghurt berry bowl" (332 '
          'kcal, 30 g protein); "Lighter full English" (408 kcal, 36 g '
          'protein).',
      'Fibre: the guide is at least 25 g a day. Averaged 17 g on the 6 '
          'days with fibre for every meal; reached on 0 days.',
      'Salt: the UK guide is at most 6 g a day. Averaged 7.4 g on the 6 days '
          'with salt for every meal; over on 4 days.',
      'Sugars: the guide is at most 86 g a day. Averaged 61 g on the 6 days '
          'with sugars for every meal; over on 1 day.',
      'Saturates: the guide is at most 21 g a day. Averaged 19 g on the 6 '
          'days with saturates for every meal; over on 2 days.',
      'Most salt came from "Ham and cheese toastie" (5.2 g over 3 meals) and '
          '"Chicken noodle soup" (3.8 g over 2 meals).',
      'Recipes high in fibre from the app\'s library: "Tuna and white bean '
          'salad" (327 kcal, 10 g fibre); "Cod with chorizo and white beans" '
          '(375 kcal, 10 g fibre).',
      'Weigh-ins this week: 3.',
      _library,
    ]);
  });

  test('the country comes first; the stored country and usual food never '
      'do', () {
    final lines = _facts(
      profile: _profile.copyWith(
        country: 'Germany',
        usualFood: 'Bulgarian home cooking',
      ),
      country: 'Bulgaria',
    ).lines;
    expect(lines.take(2), [
      'The user lives in Bulgaria.',
      'Week: Monday 26 October to Sunday 1 November.',
    ]);
    expect(lines.where((line) => line.contains('home cooking')), isEmpty);
  });

  test('last week is compared only when both weeks have 4 judged days', () {
    final thinLastWeek = [
      for (final day in _summaries)
        if (!const ['2026-10-21', '2026-10-23'].contains(day.date)) day,
    ];
    expect(
      _starting(_facts(summaries: thinLastWeek).lines, 'Last week'),
      isEmpty,
    );
  });

  group('the nutrients over the weeks', () {
    /// Every logged day of the three earlier weeks with the same meals:
    /// [fibre] and [salt] g a day, 80 g protein, 60 g sugars and 18 g
    /// saturates.
    List<Meal> earlier({required double fibre, required double salt}) => [
      for (final day in _summaries)
        if (day.date.compareTo('2026-10-26') < 0)
          ..._dayMeals(
            day.date,
            breakfast: 'Toast',
            firstProtein: 12,
            protein: 80,
            lunch: 'Soup',
            lunchSalt: 1.0,
            fibre: fibre,
            salt: salt,
            sugars: 60,
            saturates: 18,
          ),
    ];

    /// This week with plenty of protein and fibre and little salt.
    final thisWeekFine = [
      for (final day in _summaries)
        if (day.date.compareTo('2026-10-26') >= 0)
          ..._dayMeals(
            day.date,
            breakfast: 'Oats',
            firstProtein: 30,
            protein: 120,
            lunch: 'Soup',
            lunchSalt: 1.0,
            fibre: 34,
            salt: 5.0,
            sugars: 60,
            saturates: 18,
          ),
    ];

    test('off the guide for weeks running', () {
      // This week: protein 88 of 112, fibre 17 of 25, salt 7.4 over 6;
      // sugars and saturates within their guides.
      final lines = _facts(
        meals: [...earlier(fibre: 12, salt: 8), ..._meals],
      ).lines;
      expect(
        lines,
        containsAll([
          'Protein has been below target for 4 weeks running.',
          'Fibre has been under the guide for 4 weeks running.',
          'Salt has been over the guide for 4 weeks running.',
        ]),
      );
      expect(_starting(lines, 'Sugars has been'), isEmpty);
      expect(_starting(lines, 'Saturates has been'), isEmpty);
    });

    test('back on the guide after weeks off', () {
      final lines = _facts(
        meals: [...earlier(fibre: 12, salt: 8), ...thisWeekFine],
      ).lines;
      expect(
        lines,
        containsAll([
          'Protein was on target this week, after 3 weeks below target.',
          'Fibre met the guide this week, after 3 weeks under the guide.',
          'Salt was under the guide this week, after 3 weeks over the guide.',
        ]),
      );
    });

    test('a week without the nutrient ends the run', () {
      final lastWeekOnly = [
        for (final meal in earlier(fibre: 12, salt: 8))
          if (meal.date.compareTo('2026-10-19') >= 0) meal,
      ];
      final weekBeforeOnly = [
        for (final meal in earlier(fibre: 12, salt: 8))
          if (meal.date.compareTo('2026-10-19') < 0 &&
              meal.date.compareTo('2026-10-12') >= 0)
            meal,
      ];
      expect(
        _facts(meals: [...lastWeekOnly, ..._meals]).lines,
        contains('Fibre has been under the guide for 2 weeks running.'),
      );
      expect(
        _facts(meals: [...lastWeekOnly, ...thisWeekFine]).lines,
        contains(
          'Fibre met the guide this week, after 1 week under the guide.',
        ),
      );
      expect(
        _starting(
          _facts(meals: [...weekBeforeOnly, ..._meals]).lines,
          'Fibre has been',
        ),
        isEmpty,
      );
    });

    test('nothing without earlier weeks, or when they were fine', () {
      expect(_starting(_facts().lines, 'Fibre has been'), isEmpty);
      final lines = _facts(
        meals: [...earlier(fibre: 32, salt: 4), ..._meals],
      ).lines;
      expect(_starting(lines, 'Fibre has been'), isEmpty);
      expect(_starting(lines, 'Salt has been'), isEmpty);
    });
  });

  test('an ordinary week: a day off, steady weekdays and a formula change', () {
    final monday = DateTime(2026, 10, 19);
    final facts = _facts(
      monday: monday,
      summaries: _week(
        monday,
        [1880, 1950, 1820, null, 2010, 2600, 2150],
        off: {6},
      ),
      meals: [
        for (final (date, first, protein, fibre, salt, sugars, saturates) in [
          ('2026-10-19', 28.0, 118.0, 31.0, 5.1, 70.0, 18.0),
          ('2026-10-20', 30.0, 105.0, 28.0, 6.4, 92.0, 20.0),
          ('2026-10-21', 26.0, 112.0, 34.0, 4.8, 65.0, 23.0),
          ('2026-10-23', 32.0, 120.0, 30.0, 5.5, 60.0, 17.0),
          ('2026-10-24', 10.0, 60.0, 10.0, 9.0, 120.0, 30.0),
          ('2026-10-25', 22.0, 95.0, 26.0, 5.2, 75.0, 19.0),
        ])
          ..._dayMeals(
            date,
            breakfast: 'Eggs on toast',
            firstProtein: first,
            protein: protein,
            lunch: 'Chicken salad',
            lunchSalt: 1.0,
            fibre: fibre,
            salt: salt,
            sugars: sugars,
            saturates: saturates,
          ),
      ],
      weighIns: 4,
      profile: _profile.copyWith(
        adaptiveChanges: [
          (week: '2026-10-12', from: 1800, to: 1850),
          (week: '2026-10-19', from: 1850, to: 1900),
        ],
      ),
    );
    expect(facts.judgedDays, 5);
    expect(facts.lines, [
      'The user lives in United Kingdom.',
      'Week: Monday 19 October to Sunday 25 October.',
      'On track means within 10% of the daily target; close means within '
          '20%.',
      'Logged 6 of 7 days.',
      'Daily calorie target: 1,900 kcal. Minimum: 1,200 kcal a day.',
      'Already on the card: 4 days on track, 1 close, 0 off track; 1 day '
          'off; average 2,068 kcal.',
      'Day by day: Monday 1,880 kcal (on track, 20 under); Tuesday 1,950 '
          'kcal (on track, 50 over); Wednesday 1,820 kcal (on track, 80 '
          'under); Thursday not logged; Friday 2,010 kcal (on track, 110 '
          'over); Saturday day off; Sunday 2,150 kcal (close, 250 over).',
      'Every weekday logged was on track.',
      'Protein target: 112 g a day. Averaged 110 g on the 5 days with '
          'protein for every meal; reached on 3 days.',
      'Fibre: the guide is at least 25 g a day. Averaged 30 g on the 5 '
          'days with fibre for every meal; reached on 5 days.',
      'Salt: the UK guide is at most 6 g a day. Averaged 5.4 g on the 5 days '
          'with salt for every meal; over on 1 day.',
      'Sugars: the guide is at most 86 g a day. Averaged 72 g on the 5 days '
          'with sugars for every meal; over on 1 day.',
      'Saturates: the guide is at most 21 g a day. Averaged 19 g on the 5 '
          'days with saturates for every meal; over on 1 day.',
      'Weigh-ins this week: 4.',
      'On Monday the Adaptive formula changed the daily target from 1,850 to '
          '1,900 kcal, from the user\'s weigh-ins and logged food.',
      _library,
    ]);
  });

  test('fewer than 4 judged days, and a day off doesn\'t count', () {
    final facts = _facts(
      summaries: _week(
        _monday,
        [1800, null, 1900, null, 2000, 2600, null],
        off: {6},
      ),
    );
    expect(facts.judgedDays, 3);
    expect(facts.lines, contains('Logged 4 of 7 days.'));
  });

  test('days off are left out of the weekend and the biggest day', () {
    final facts = _facts(
      summaries: _week(
        _monday,
        [1900, 2400, 1850, 1880, 1900, 3200, 2300],
        off: {6},
      ),
    );
    expect(_starting(facts.lines, 'Weekdays averaged'), isEmpty);
    expect(facts.lines, contains('Biggest day: Tuesday, 2,400 kcal.'));
    expect(facts.lines, contains(contains('Saturday day off')));
  });

  test('the biggest day is only named when it was off track over', () {
    final facts = _facts(
      summaries: _week(_monday, [1900, 2050, 1850, 1880, 1900, null, null]),
    );
    expect(_starting(facts.lines, 'Biggest day'), isEmpty);
  });

  test('the weekend line needs both days judged and a 15% gap', () {
    // Weekdays average 1,900; 15% of the target is 285.
    List<String> weekend(int? saturday, int? sunday) => _facts(
      summaries: _week(_monday, [
        1900,
        1900,
        1900,
        1900,
        1900,
        saturday,
        sunday,
      ]),
    ).lines;
    expect(_starting(weekend(2180, 2180), 'Weekdays averaged'), isEmpty);
    expect(
      weekend(2190, 2180),
      contains(
        'Weekdays averaged 1,900 kcal; the weekend averaged 2,190 kcal.',
      ),
    );
    expect(_starting(weekend(2600, null), 'Weekdays averaged'), isEmpty);
  });

  test('days under the minimum may not have been fully logged', () {
    final facts = _facts(
      summaries: _week(_monday, [1900, 980, 1850, 1150, 1900, null, null]),
    );
    expect(
      facts.lines,
      contains(
        'Under the 1,200 kcal minimum: Tuesday 980 kcal; Thursday 1,150 kcal. '
        'They may not have been fully logged.',
      ),
    );
  });

  group('the usual big day', () {
    final earlier = _summaries.where((s) => s.date.compareTo('2026-10-26') < 0);

    test('a tie in a week gives no winner that week', () {
      final tied = [
        for (final summary in earlier)
          // 24 October: Saturday ties with Sunday's 2,200.
          summary.date == '2026-10-24' ? _day(summary.date, 2200) : summary,
        ..._summaries.where((s) => s.date.compareTo('2026-10-26') >= 0),
      ];
      expect(
        _starting(_facts(summaries: tied).lines, 'Saturday was the biggest'),
        isEmpty,
      );
    });

    test('a Saturday taken off doesn\'t count', () {
      final off = [
        for (final summary in _summaries)
          summary.date == '2026-10-10'
              ? _day(summary.date, 2400, dayOff: true)
              : summary,
      ];
      expect(
        _starting(_facts(summaries: off).lines, 'Saturday was the biggest'),
        isEmpty,
      );
    });

    test('a week with fewer than 4 judged days doesn\'t count', () {
      final thin = [
        for (final summary in _summaries)
          if (!['2026-10-05', '2026-10-06'].contains(summary.date)) summary,
      ];
      expect(
        _starting(_facts(summaries: thin).lines, 'Saturday was the biggest'),
        isEmpty,
      );
    });
  });

  test('with protein off: no protein, first-meal or idea lines', () {
    final lines = _facts(profile: _profile.copyWith(trackProtein: false)).lines;
    expect(_starting(lines, 'Protein'), isEmpty);
    expect(_starting(lines, 'The first meal'), isEmpty);
    expect(_starting(lines, 'The user\'s own'), isEmpty);
    expect(_starting(lines, 'Recipes from the app\'s library'), isEmpty);
    // Fibre isn't protein.
    expect(_starting(lines, 'Recipes high in fibre'), hasLength(1));
  });

  test('the first meal skips a day whose first meal has no protein', () {
    final meals = [
      for (final meal in _meals)
        meal.id == '2026-10-26-0'
            ? _meal(meal.date, 0, meal.name!, macros: meal.macros)
            : meal,
    ];
    final lines = _facts(meals: meals).lines;
    // Tuesday to Sunday but Thursday: 12, 27, 11, 12 and 12.
    expect(
      lines,
      contains(
        'The first meal of the day averaged 15 g of protein, on 5 days.',
      ),
    );
    // Thursday, with dinner added the next day, was already left out.
    expect(_facts().lines, contains(contains('on 6 days.')));
  });

  test('no first-meal fact, and no ideas, once breakfasts have protein', () {
    final meals = [
      for (final meal in _meals)
        meal.id.endsWith('-0')
            ? _meal(meal.date, 0, meal.name!, protein: 22, macros: meal.macros)
            : meal,
    ];
    final lines = _facts(meals: meals).lines;
    expect(_starting(lines, 'The first meal'), isEmpty);
    expect(_starting(lines, 'Recipes from the app\'s library'), isEmpty);
  });

  test('recipe ideas keep their order whatever the library\'s', () {
    expect(_facts(recipes: _recipes.reversed.toList()).lines, _facts().lines);
  });

  test('the formula line only for a change on this week\'s Monday', () {
    String? formula(List<AdaptiveChange> changes) => _starting(
      _facts(profile: _profile.copyWith(adaptiveChanges: changes)).lines,
      'On Monday the Adaptive formula',
    ).firstOrNull;
    expect(formula([(week: '2026-10-19', from: 1850, to: 1900)]), isNull);
    expect(
      formula([(week: '2026-10-26', from: 1900, to: 1850)]),
      'On Monday the Adaptive formula changed the daily target from 1,900 to '
      '1,850 kcal, from the user\'s weigh-ins and logged food.',
    );
  });

  test('the user\'s own meals are never offered as ideas', () {
    // "Skyr with honey" was a 27 g first meal: once it was an idea.
    final lines = _facts().lines;
    expect(lines.where((line) => line.contains('Skyr with honey')), isEmpty);
    expect(_starting(lines, 'The user\'s own'), isEmpty);
  });

  test('meal names are cut to 60 characters', () {
    final long = 'Ham and cheese toastie, ${'pickles, ' * 6}and crisps';
    final meals = [
      for (final meal in _meals)
        meal.name == 'Ham and cheese toastie'
            ? _meal(
                meal.date,
                int.parse(meal.id.split('-').last),
                long,
                protein: meal.proteinGrams,
                macros: meal.macros,
              )
            : meal,
    ];
    final salt = _starting(
      _facts(meals: meals).lines,
      'Most salt came from',
    ).single;
    expect(salt, contains('"${long.substring(0, 60).trimRight()}"'));
  });

  test('a nutrient needs 3 days with it for every meal', () {
    // Monday to Thursday lose their macros, leaving Friday and Saturday.
    final meals = [
      for (final meal in _meals)
        meal.date.compareTo('2026-10-30') < 0
            ? _meal(
                meal.date,
                int.parse(meal.id.split('-').last),
                meal.name!,
                protein: meal.proteinGrams,
              )
            : meal,
    ];
    final lines = _facts(meals: meals).lines;
    for (final name in ['Fibre', 'Salt', 'Sugars', 'Saturates', 'Most salt']) {
      expect(_starting(lines, name), isEmpty, reason: name);
    }
    expect(_starting(lines, 'Recipes high in fibre'), isEmpty);
  });

  test('fat and carbs never appear', () {
    for (final line in _facts().lines) {
      expect(line.toLowerCase(), isNot(contains('fat')));
      expect(line.toLowerCase(), isNot(contains('carb')));
    }
  });

  test('the same input gives the same lines', () {
    expect(_facts().text, _facts().text);
  });
}
