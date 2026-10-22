import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/period_review.dart';

class PeriodReviewService {
  PeriodReview buildReview({
    required DateTime startDate,
    required DateTime endDate,
    required List<DailySummary> summaries,
  }) {
    final sortedSummaries = [...summaries]
      ..sort((a, b) => a.date.compareTo(b.date));
    final activeSummaries = sortedSummaries.where(_hasLoggedActivity).toList();

    final daysInPeriod = endDate.difference(startDate).inDays + 1;
    final loggedDays = activeSummaries.length;
    final totalCalories = activeSummaries.fold<int>(
      0,
      (sum, summary) => sum + summary.totalCalories,
    );
    final totalMeals = activeSummaries.fold<int>(
      0,
      (sum, summary) => sum + summary.mealCount,
    );
    final averageCaloriesPerDay = loggedDays == 0
        ? 0.0
        : totalCalories / loggedDays.toDouble();

    // Days off are logged and counted in the totals, but not judged.
    final judged = activeSummaries.where((summary) => !summary.dayOff).toList();
    final greenDays = judged
        .where((summary) => summary.status == DailyStatus.green)
        .length;
    final yellowDays = judged
        .where((summary) => summary.status == DailyStatus.yellow)
        .length;
    final redDays = judged
        .where((summary) => summary.status == DailyStatus.red)
        .length;
    final calorieConsistencyRate = judged.isEmpty
        ? 0.0
        : greenDays / judged.length.toDouble();

    final bestDay = judged.isEmpty
        ? null
        : judged.reduce((best, current) {
            if (current.deltaRatio < best.deltaRatio) return current;
            return current.date.compareTo(best.date) > 0 ? current : best;
          });
    final worstDay = judged.isEmpty
        ? null
        : judged.reduce((worst, current) {
            if (current.deltaRatio > worst.deltaRatio) return current;
            return current.date.compareTo(worst.date) > 0 ? current : worst;
          });

    return PeriodReview(
      startDate: startDate,
      endDate: endDate,
      daysInPeriod: daysInPeriod,
      loggedDays: loggedDays,
      summaries: activeSummaries,
      totalCalories: totalCalories,
      averageCaloriesPerDay: averageCaloriesPerDay,
      totalMeals: totalMeals,
      greenDays: greenDays,
      yellowDays: yellowDays,
      redDays: redDays,
      daysOff: activeSummaries.length - judged.length,
      calorieConsistencyRate: calorieConsistencyRate,
      bestDay: bestDay,
      worstDay: worstDay,
      guidance: _buildGuidance(
        calorieConsistencyRate: calorieConsistencyRate,
        daysInPeriod: daysInPeriod,
        loggedDays: loggedDays,
      ),
    );
  }

  bool _hasLoggedActivity(DailySummary summary) {
    return summary.mealCount > 0 || summary.totalCalories > 0;
  }

  List<String> _buildGuidance({
    required double calorieConsistencyRate,
    required int daysInPeriod,
    required int loggedDays,
  }) {
    final guidance = <String>[];

    if (loggedDays == 0) {
      guidance.add('No logged meals were found for this period.');
      return guidance;
    }

    if (calorieConsistencyRate >= 0.70) {
      guidance.add('Most logged days stayed close to target.');
    } else if (calorieConsistencyRate >= 0.40) {
      guidance.add(
        'Some logged days stayed close to target. Tightening a few outliers will help.',
      );
    } else {
      guidance.add('Most logged days were well above or below target.');
    }

    // About 4 days in 7 for weeks, half for months, scaled to the days that
    // have passed so a week in progress isn't judged as a full one.
    final minimumLoggedDays = daysInPeriod <= 7
        ? (daysInPeriod * 4 / 7).ceil()
        : (daysInPeriod * 0.5).ceil();
    if (loggedDays < minimumLoggedDays) {
      guidance.add(
        'Logging was inconsistent. More complete logging will make the review more useful.',
      );
    }

    return guidance.take(4).toList();
  }
}
