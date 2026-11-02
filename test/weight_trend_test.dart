import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/weight_trend.dart';
import 'package:lean_streak/models/weight_entry.dart';

/// Weigh-ins from 1 November, one per [days] offset.
List<WeightEntry> _weighIns(Map<int, double> byDay) => [
  for (final MapEntry(key: day, value: kg) in byDay.entries)
    WeightEntry(
      dateKey: '2026-11-${(day + 1).toString().padLeft(2, '0')}',
      weightKg: kg,
      loggedAt: DateTime(2026, 11, day + 1),
      source: WeightSource.manual,
    ),
];

void main() {
  test('the first weigh-in starts the trend', () {
    final trend = weightTrend(_weighIns({0: 80.0}));
    expect(trend.single, (trendKg: 80.0, setAside: false));
  });

  test('a daily weigh-in moves the trend 10% of the way', () {
    final trend = weightTrend(_weighIns({0: 80.0, 1: 81.0}));
    expect(trend.last.trendKg, closeTo(80.1, 1e-9));
  });

  test('after a 3-day gap it moves 1 - 0.9^3 = 27.1% of the way', () {
    final trend = weightTrend(_weighIns({0: 80.0, 3: 81.0}));
    expect(trend.last.trendKg, closeTo(80.271, 1e-9));
  });

  test('a typo is set aside and the trend ignores it', () {
    final trend = weightTrend(_weighIns({0: 79.8, 1: 79.6, 2: 97.8, 3: 79.5}));
    final without = weightTrend(_weighIns({0: 79.8, 1: 79.6, 3: 79.5}));
    expect([for (final p in trend) p.setAside], [false, false, true, false]);
    expect(trend.last.trendKg, closeTo(without.last.trendKg, 1e-9));
  });

  test('two jumps in a row on the same side both count', () {
    final trend = weightTrend(_weighIns({0: 79.9, 1: 83.0, 2: 83.1}));
    expect([for (final p in trend) p.setAside], [false, false, false]);
    expect(trend[1].trendKg, closeTo(79.9 + 0.1 * 3.1, 1e-9));
    expect(trend.last.trendKg, greaterThan(trend[1].trendKg));
  });

  test('a jump the other way does not confirm one before it', () {
    final trend = weightTrend(_weighIns({0: 80.0, 1: 84.0, 2: 76.0}));
    expect([for (final p in trend) p.setAside], [false, true, true]);
    expect(trend.last.trendKg, 80.0);
  });

  test('a set-aside latest weigh-in waits for the next', () {
    final trend = weightTrend(_weighIns({0: 80.0, 1: 85.0}));
    expect(trend.last, (trendKg: 80.0, setAside: true));
  });
}
