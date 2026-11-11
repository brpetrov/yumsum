import 'package:flutter/widgets.dart';

import 'package:lean_streak/l10n/app_localizations.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/period_review.dart';

class PeriodReviewService {
  /// The [PeriodReview.guidance] is in [l10n]'s language, English when not
  /// given. A [month] also says when its days ran over target on average,
  /// and for someone [losing] weight that the goal date moves later.
  PeriodReview buildReview({
    required DateTime startDate,
    required DateTime endDate,
    required List<DailySummary> summaries,
    AppLocalizations? l10n,
    bool month = false,
    bool losing = false,
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
    // A day 140 kcal over is still on track, but a month of them adds up.
    // Each day against its own target, from a week of judged days.
    final averageOver = !month || judged.length < 7
        ? 0
        : (judged.fold<int>(
                    0,
                    (sum, summary) =>
                        sum + summary.totalCalories - summary.targetCalories,
                  ) /
                  judged.length)
              .round();

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
        l10n ?? lookupAppLocalizations(const Locale('en')),
        calorieConsistencyRate: calorieConsistencyRate,
        daysInPeriod: daysInPeriod,
        loggedDays: loggedDays,
        averageOver: averageOver,
        losing: losing,
      ),
    );
  }

  bool _hasLoggedActivity(DailySummary summary) {
    return summary.mealCount > 0 || summary.totalCalories > 0;
  }

  List<String> _buildGuidance(
    AppLocalizations l10n, {
    required double calorieConsistencyRate,
    required int daysInPeriod,
    required int loggedDays,
    required int averageOver,
    required bool losing,
  }) {
    final guidance = <String>[];

    if (loggedDays == 0) {
      guidance.add(l10n.historyGuidanceNoMeals);
      return guidance;
    }

    if (calorieConsistencyRate >= 0.70) {
      guidance.add(l10n.historyGuidanceMostClose);
    } else if (calorieConsistencyRate >= 0.40) {
      guidance.add(l10n.historyGuidanceSomeClose);
    } else {
      guidance.add(l10n.historyGuidanceMostOff);
    }

    if (averageOver > 100) {
      guidance.add(
        losing
            ? l10n.historyGuidanceOverGoalDate(averageOver)
            : l10n.historyGuidanceOver(averageOver),
      );
    }

    // About 4 days in 7 for weeks, half for months, scaled to the days that
    // have passed so a week in progress isn't judged as a full one.
    final minimumLoggedDays = daysInPeriod <= 7
        ? (daysInPeriod * 4 / 7).ceil()
        : (daysInPeriod * 0.5).ceil();
    if (loggedDays < minimumLoggedDays) {
      guidance.add(l10n.historyGuidanceLogMore);
    }

    return guidance.take(4).toList();
  }
}
