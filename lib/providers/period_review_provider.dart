import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/services/period_review_service.dart';

final periodReviewServiceProvider = Provider<PeriodReviewService>((ref) {
  return PeriodReviewService();
});

class PeriodReviewRange {
  const PeriodReviewRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) {
    return other is PeriodReviewRange &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}
