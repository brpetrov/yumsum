import 'dart:math' as math;

import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/services/period_review_service.dart';

/// What the AI Coach is told about a finished week (plan 09). The app works
/// out every fact and the AI only puts a few of them into words. The lines
/// are also the cache's fingerprint, so the same data must always give
/// exactly the same lines.
class WeekFacts {
  const WeekFacts({required this.judgedDays, required this.lines});

  /// Logged days that weren't days off; notes need at least 4.
  final int judgedDays;
  final List<String> lines;

  String get text => lines.join('\n');
}

/// Logged (a meal or some calories, the period review's rule) and not a day
/// off, so it counts towards patterns, averages and tips.
bool isJudgedDay(DailySummary summary) => !summary.dayOff && _isLogged(summary);

bool _isLogged(DailySummary summary) =>
    summary.mealCount > 0 || summary.totalCalories > 0;

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

final _number = NumberFormat('#,##0');
final _tenths = NumberFormat('#,##0.#');
final _dateKey = DateFormat('yyyy-MM-dd');

String _n(num value) => _number.format(value);

/// Salt, to 0.1 g.
double _toTenth(double grams) => (grams * 10).round() / 10;

String _days(int count) => '$count ${count == 1 ? 'day' : 'days'}';

String _weekday(String date) => _weekdays[DateTime.parse(date).weekday - 1];

/// A meal name as the user wrote it, quoted and cut to 60 characters.
String _quoted(String name) =>
    '"${String.fromCharCodes(name.trim().runes.take(60)).trimRight()}"';

double _average(Iterable<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

/// The facts about the week starting [monday]. [summaries] cover the 4
/// weeks ending on its Sunday (for the usual big day); [meals] are this
/// week's; [weighIns] is how many fell in the week.
WeekFacts buildWeekFacts({
  required DateTime monday,
  required List<DailySummary> summaries,
  required List<Meal> meals,
  required int weighIns,
  required UserProfile profile,
  required List<Recipe> recipes,
}) {
  DateTime dayOf(int offset) =>
      DateTime(monday.year, monday.month, monday.day + offset);
  final byDate = {for (final summary in summaries) summary.date: summary};
  final week = [for (var i = 0; i < 7; i++) byDate[_dateKey.format(dayOf(i))]];
  final logged = [
    for (final summary in week)
      if (summary != null && _isLogged(summary)) summary,
  ];
  final judged = logged.where(isJudgedDay).toList();

  // Each day's meals in the order they were logged, ties by id.
  final mealsByDate = <String, List<Meal>>{};
  for (final meal in meals) {
    mealsByDate.putIfAbsent(meal.date, () => []).add(meal);
  }
  for (final dayMeals in mealsByDate.values) {
    dayMeals.sort((a, b) {
      final byTime = a.timestamp.compareTo(b.timestamp);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }
  List<Meal> mealsOn(DailySummary day) => mealsByDate[day.date] ?? const [];

  final target = logged.isEmpty
      ? profile.dailyCalorieTarget.round()
      : logged.last.targetCalories;
  final minimum = HealthCalculator.calorieFloor(profile.gender).round();
  final card = PeriodReviewService().buildReview(
    startDate: monday,
    endDate: dayOf(6),
    summaries: week.nonNulls.toList(),
  );

  String dayByDay(int i) {
    final day = week[i];
    if (day == null || !_isLogged(day)) return '${_weekdays[i]} not logged';
    if (day.dayOff) return '${_weekdays[i]} day off';
    final delta = day.calorieDelta;
    final away = delta == 0
        ? 'on target'
        : '${_n(delta.abs())} ${delta > 0 ? 'over' : 'under'}';
    return '${_weekdays[i]} ${_n(day.totalCalories)} kcal '
        '(${day.status.label.toLowerCase()}, $away)';
  }

  final lines = <String>[
    'Week: ${DateFormat('EEEE d MMMM').format(monday)} to '
        '${DateFormat('EEEE d MMMM').format(dayOf(6))}.',
    'On track means within 10% of the daily target; close means within 20%.',
    'Logged ${logged.length} of 7 days.',
    'Daily calorie target: ${_n(target)} kcal. Minimum: ${_n(minimum)} kcal '
        'a day.',
    'Already on the card: ${_days(card.greenDays)} on track, '
        '${card.yellowDays} close, ${card.redDays} off track'
        '${card.daysOff > 0 ? '; ${_days(card.daysOff)} off' : ''}; average '
        '${_n(card.averageCaloriesPerDay.round())} kcal.',
    'Day by day: ${[for (var i = 0; i < 7; i++) dayByDay(i)].join('; ')}.',
  ];

  // Weekdays against the weekend, and steady weekdays.
  final weekdays = [
    for (final day in judged)
      if (DateTime.parse(day.date).weekday <= DateTime.friday) day,
  ];
  final weekend = [
    for (final day in judged)
      if (DateTime.parse(day.date).weekday > DateTime.friday) day,
  ];
  if (weekdays.length >= 3 && weekend.length == 2) {
    final weekdayAverage = _average(
      weekdays.map((day) => day.totalCalories.toDouble()),
    );
    final weekendAverage = _average(
      weekend.map((day) => day.totalCalories.toDouble()),
    );
    if ((weekendAverage - weekdayAverage).abs() >= 0.15 * target) {
      int toTen(double kcal) => (kcal / 10).round() * 10;
      lines.add(
        'Weekdays averaged ${_n(toTen(weekdayAverage))} kcal; the weekend '
        'averaged ${_n(toTen(weekendAverage))} kcal.',
      );
    }
  }
  if (weekdays.length >= 4 &&
      weekdays.every((day) => day.status == DailyStatus.green)) {
    lines.add('Every weekday logged was on track.');
  }

  // The biggest day, when it was well over; the earliest wins a tie.
  if (judged.isNotEmpty) {
    final biggest = judged.reduce(
      (a, b) => b.totalCalories > a.totalCalories ? b : a,
    );
    if (biggest.status == DailyStatus.red && biggest.calorieDelta > 0) {
      lines.add(
        'Biggest day: ${_weekday(biggest.date)}, '
        '${_n(biggest.totalCalories)} kcal.',
      );
    }
  }

  final low = [
    for (final day in judged)
      if (day.totalCalories < minimum) day,
  ];
  if (low.isNotEmpty) {
    final named = [
      for (final day in low)
        '${_weekday(day.date)} ${_n(day.totalCalories)} kcal',
    ];
    lines.add(
      'Under the ${_n(minimum)} kcal minimum: ${named.join('; ')}. '
      '${low.length == 1 ? 'It' : 'They'} may not have been fully logged.',
    );
  }

  // A usual big day: the same weekday biggest in 3 of the last 4 weeks,
  // counting weeks with 4 judged days and a single biggest day.
  final wins = <int, int>{};
  for (var weeksBack = 3; weeksBack >= 0; weeksBack--) {
    final days = [
      for (var i = 0; i < 7; i++)
        byDate[_dateKey.format(dayOf(i - 7 * weeksBack))],
    ].nonNulls.where(isJudgedDay).toList();
    if (days.length < 4) continue;
    final most = days.map((day) => day.totalCalories).reduce(math.max);
    final top = days.where((day) => day.totalCalories == most).toList();
    if (top.length != 1) continue;
    final weekday = DateTime.parse(top.single.date).weekday;
    wins.update(weekday, (count) => count + 1, ifAbsent: () => 1);
  }
  for (final MapEntry(key: weekday, value: count) in wins.entries) {
    if (count >= 3) {
      lines.add(
        '${_weekdays[weekday - 1]} was the biggest day in $count of the last '
        '4 weeks.',
      );
    }
  }

  // Protein, from days where every meal has it, since a gap looks low.
  final proteinTarget = HealthCalculator.proteinTargetGrams(
    targetWeightKg: profile.targetWeightKg,
    trainingFrequency: profile.trainingFrequency,
  );
  if (profile.trackProtein) {
    final proteinDays = [
      for (final day in judged)
        if (mealsOn(day) case final dayMeals
            when dayMeals.isNotEmpty &&
                dayMeals.every((meal) => meal.proteinGrams != null))
          dayMeals.fold(0.0, (sum, meal) => sum + meal.proteinGrams!).round(),
    ];
    int? proteinAverage;
    if (proteinDays.length >= 3) {
      proteinAverage = _average(proteinDays.map((g) => g.toDouble())).round();
      final reached = proteinDays.where((g) => g >= proteinTarget).length;
      lines.add(
        'Protein target: $proteinTarget g a day. Averaged $proteinAverage g '
        'on the ${proteinDays.length} days with protein for every meal; '
        'reached on ${_days(reached)}.',
      );
    }

    // The first meal of each day, by the order meals were logged, on days
    // where every meal was logged on the day itself (a meal added later
    // gets that day's time, so the order would be wrong).
    final firstMeals = [
      for (final day in judged)
        if (mealsOn(day) case final dayMeals
            when dayMeals.isNotEmpty &&
                dayMeals.every(
                  (meal) => _dateKey.format(meal.createdAt) == meal.date,
                ) &&
                dayMeals.first.proteinGrams != null)
          dayMeals.first,
    ];
    final firstAverage = firstMeals.isEmpty
        ? null
        : _average(firstMeals.map((meal) => meal.proteinGrams!)).round();
    if (firstAverage != null &&
        firstMeals.length >= 3 &&
        firstAverage < 20 &&
        (proteinAverage == null || proteinAverage < proteinTarget)) {
      lines.add(
        'The first meal of the day averaged $firstAverage g of protein, on '
        '${firstMeals.length} days.',
      );

      // Ideas come from the library only: the user's own meals were logged
      // first on some day, not necessarily eaten as breakfast.
      final ideas = [
        for (final recipe in recipes)
          if (recipe.category == RecipeCategory.breakfast &&
              recipe.proteinPerPortion >= firstAverage + 10)
            recipe,
      ]..sort(_byRatio((recipe) => recipe.proteinPerPortion.toDouble()));
      if (ideas.isNotEmpty) {
        final named = [
          for (final recipe in ideas.take(2))
            '${_quoted(recipe.name)} (${_n(recipe.kcalPerPortion)} kcal, '
                '${recipe.proteinPerPortion} g protein)',
        ];
        lines.add('Recipes from the app\'s library: ${named.join('; ')}.');
      }
    }
  }

  // Fibre, salt, sugars and saturates against the guides, each from days
  // where every meal has it. Fat and carbs are left out: their guides are
  // about balance, with no clear over or under.
  final guides = HealthCalculator.macroTargets(
    calories: target,
    proteinGrams: proteinTarget,
  );
  Map<String, double> nutrientDays(double? Function(Nutrients) of) => {
    for (final day in judged)
      if (mealsOn(day) case final dayMeals
          when dayMeals.isNotEmpty &&
              dayMeals.every(
                (meal) => meal.macros != null && of(meal.macros!) != null,
              ))
        day.date: dayMeals.fold(0.0, (sum, meal) => sum + of(meal.macros!)!),
  };

  final fibre = nutrientDays((n) => n.fibre);
  final fibreAverage = fibre.length < 3 ? null : _average(fibre.values).round();
  if (fibreAverage != null) {
    final reached = fibre.values.where((g) => g.round() >= guides.fibre);
    lines.add(
      'Fibre: the UK guide is at least ${guides.fibre} g a day. Averaged '
      '$fibreAverage g on the ${fibre.length} days with fibre for every '
      'meal; reached on ${_days(reached.length)}.',
    );
  }

  final salt = nutrientDays((n) => n.salt);
  final saltAverage = salt.length < 3 ? null : _toTenth(_average(salt.values));
  if (saltAverage != null) {
    final over = salt.values.where((g) => _toTenth(g) > guides.salt);
    lines.add(
      'Salt: the UK guide is at most ${guides.salt} g a day. Averaged '
      '${_tenths.format(saltAverage)} g on the ${salt.length} days with salt '
      'for every meal; over on ${_days(over.length)}.',
    );
  }

  for (final (name, guide, days) in [
    ('Sugars', guides.sugars, nutrientDays((n) => n.sugars)),
    ('Saturates', guides.saturates, nutrientDays((n) => n.saturates)),
  ]) {
    if (days.length < 3) continue;
    final over = days.values.where((g) => g.round() > guide);
    lines.add(
      '$name: the guide is at most $guide g a day. Averaged '
      '${_average(days.values).round()} g on the ${days.length} days with '
      '${name.toLowerCase()} for every meal; over on ${_days(over.length)}.',
    );
  }

  // Where the salt came from: meals summed by name over the salt days.
  if (saltAverage != null && saltAverage > guides.salt) {
    final sources = <String, ({String name, double grams, int meals})>{};
    for (final date in salt.keys) {
      for (final meal in mealsByDate[date]!) {
        if (meal.name == null) continue;
        sources.update(
          meal.name!.trim().toLowerCase(),
          (s) => (
            name: s.name,
            grams: s.grams + meal.macros!.salt!,
            meals: s.meals + 1,
          ),
          ifAbsent: () =>
              (name: meal.name!, grams: meal.macros!.salt!, meals: 1),
        );
      }
    }
    final top = sources.values.toList()
      ..sort((a, b) {
        final byGrams = b.grams.compareTo(a.grams);
        return byGrams != 0 ? byGrams : a.name.compareTo(b.name);
      });
    if (top.isNotEmpty) {
      final named = [
        for (final source in top.take(2))
          '${_quoted(source.name)} '
              '(${_tenths.format(_toTenth(source.grams))} g over '
              '${source.meals} ${source.meals == 1 ? 'meal' : 'meals'})',
      ];
      lines.add('Most salt came from ${named.join(' and ')}.');
    }
  }

  // Fibre ideas that never add salt.
  if (fibreAverage != null && fibreAverage < guides.fibre) {
    final ideas = [
      for (final recipe in recipes)
        if (recipe.macrosPerPortion.fibre! >= 8 &&
            recipe.macrosPerPortion.salt! < 2)
          recipe,
    ]..sort(_byRatio((recipe) => recipe.macrosPerPortion.fibre!));
    if (ideas.isNotEmpty) {
      final named = [
        for (final recipe in ideas.take(2))
          '${_quoted(recipe.name)} (${_n(recipe.kcalPerPortion)} kcal, '
              '${recipe.macrosPerPortion.fibre!.round()} g fibre)',
      ];
      lines.add(
        'Recipes high in fibre from the app\'s library: ${named.join('; ')}.',
      );
    }
  }

  if (weighIns > 0) lines.add('Weigh-ins this week: $weighIns.');

  // The change made on this week's own Monday: the target lived with.
  final change = profile.adaptiveChanges
      .where((change) => change.week == _dateKey.format(monday))
      .lastOrNull;
  if (change != null) {
    lines.add(
      'On Monday the Adaptive formula changed the daily target from '
      '${_n(change.from)} to ${_n(change.to)} kcal, from the user\'s '
      'weigh-ins and logged food.',
    );
  }

  return WeekFacts(judgedDays: judged.length, lines: lines);
}

/// Most of [value] per kcal first, then by id, so the order never changes.
int Function(Recipe, Recipe) _byRatio(double Function(Recipe) value) => (a, b) {
  final byRatio = (value(b) / b.kcalPerPortion).compareTo(
    value(a) / a.kcalPerPortion,
  );
  return byRatio != 0 ? byRatio : a.id.compareTo(b.id);
};
