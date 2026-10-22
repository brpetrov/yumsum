import 'package:lean_streak/models/daily_summary.dart';

class PeriodReview {
  const PeriodReview({
    required this.startDate,
    required this.endDate,
    required this.daysInPeriod,
    required this.loggedDays,
    required this.summaries,
    required this.totalCalories,
    required this.averageCaloriesPerDay,
    required this.totalMeals,
    required this.greenDays,
    required this.yellowDays,
    required this.redDays,
    required this.daysOff,
    required this.calorieConsistencyRate,
    required this.bestDay,
    required this.worstDay,
    required this.guidance,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int daysInPeriod;
  final int loggedDays;
  final List<DailySummary> summaries;
  final int totalCalories;
  final double averageCaloriesPerDay;
  final int totalMeals;
  final int greenDays;
  final int yellowDays;
  final int redDays;

  /// Logged days taken off, which aren't judged.
  final int daysOff;
  final double calorieConsistencyRate;
  final DailySummary? bestDay;
  final DailySummary? worstDay;
  final List<String> guidance;
}
