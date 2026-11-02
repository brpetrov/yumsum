import 'dart:math' as math;

import 'package:lean_streak/models/weight_entry.dart';

/// How much of each day's weigh-in the trend keeps from before: 0.9 moves
/// it 10% of the way towards a daily weigh-in (The Hacker's Diet).
const trendSmoothing = 0.9;

/// A weigh-in further than this from the trend (3%, 2.4 kg at 80 kg) is set
/// aside as a likely typo, unless the next one agrees with it.
const setAsideShare = 0.03;

/// One weigh-in's place on the trend: the trend after it, and whether it
/// was set aside (a typo, or the latest one waiting for the next).
typedef TrendPoint = ({double trendKg, bool setAside});

/// The weight trend, your weight without the daily ups and downs, for
/// [entries] oldest first: an exponentially smoothed average that allows
/// for the days between weigh-ins (docs/plans/08-adaptive-formula.md,
/// step 3). One point per entry.
List<TrendPoint> weightTrend(List<WeightEntry> entries) {
  final points = <TrendPoint>[];
  double? trend;
  DateTime? last;
  int? waiting;

  void count(int i) {
    final entry = entries[i];
    final t = trend;
    if (t == null) {
      trend = entry.weightKg;
    } else {
      final days = entry.date.difference(last!).inDays;
      trend = t + (1 - math.pow(trendSmoothing, days)) * (entry.weightKg - t);
    }
    last = entry.date;
    points[i] = (trendKg: trend!, setAside: false);
  }

  for (var i = 0; i < entries.length; i++) {
    final t = trend;
    points.add((trendKg: t ?? entries[i].weightKg, setAside: false));
    final off = t == null ? 0.0 : (entries[i].weightKg - t) / t;
    if (off.abs() <= setAsideShare) {
      // A weigh-in waiting for this one was a typo after all.
      waiting = null;
      count(i);
    } else if (waiting case final w?
        when (entries[w].weightKg - t!).sign == off.sign) {
      // Two in a row on the same side: it was real.
      waiting = null;
      count(w);
      count(i);
    } else {
      waiting = i;
      points[i] = (trendKg: t!, setAside: true);
    }
  }
  return points;
}
