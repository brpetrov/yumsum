import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/period_review_provider.dart';

class ReviewRange {
  const ReviewRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) {
    return other is ReviewRange &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

/// The first day anything was logged, or null before that: History doesn't
/// page back past its week or month.
final firstLoggedDayProvider = FutureProvider.autoDispose<DateTime?>((
  ref,
) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ref.watch(dailySummaryRepositoryProvider).fetchFirstSummaryDate(uid);
});

final reviewSummariesProvider = FutureProvider.autoDispose
    .family<Map<String, DailySummary>, ReviewRange>((ref, range) async {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return const {};

      final formatter = DateFormat('yyyy-MM-dd');
      final summaries = await ref
          .watch(dailySummaryRepositoryProvider)
          .fetchSummariesInRange(
            uid,
            startDate: formatter.format(range.startDate),
            endDate: formatter.format(range.endDate),
          );

      return {for (final summary in summaries) summary.date: summary};
    });

/// Refetches History's one-off reads after a day's meals changed; the
/// day summary streams follow by themselves.
void refreshHistory(Ref ref) {
  ref.invalidate(firstLoggedDayProvider);
  ref.invalidate(reviewSummariesProvider);
  ref.invalidate(periodReviewProvider);
}
