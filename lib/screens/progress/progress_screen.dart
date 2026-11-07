import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/weight_trend.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/units_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/progress/helpers/adaptive_section.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final unit = ref.watch(weightUnitProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        // Shrinks rather than cuts off beside Log weight on narrow phones.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(l10n.progressTitle),
        ),
        actions: [
          // The empty state has its own button, so only show this one once
          // there is history.
          if (entriesAsync.valueOrNull?.isNotEmpty ?? false)
            TextButton.icon(
              onPressed: () => _logWeight(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.progressLogWeight),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return SafeArea(
              child: _EmptyState(onLogWeight: () => _logWeight(context, ref)),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              // As a ResponsivePage 760 wide: centred, with 20 at the sides.
              final side = 20 + math.max(0.0, constraints.maxWidth - 760) / 2;
              // Built as they scroll in, so a long history only builds the
              // weigh-ins on screen: the stats and chart, the weigh-ins
              // newest first, then Reset progress.
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  side,
                  12,
                  side,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                itemCount: entries.length + 2,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatsHeader(
                          entries: entries,
                          profile: profile,
                          unit: unit,
                        ),
                        const SizedBox(height: 18),
                        _WeightChartCard(
                          entries: entries,
                          profile: profile,
                          unit: unit,
                        ),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                          child: Text(
                            l10n.progressHistory,
                            style: AppTheme.display.copyWith(
                              fontSize: 21,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  if (i > entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _resetHistory(context, ref),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: Text(l10n.progressReset),
                        ),
                      ),
                    );
                  }
                  final entry = entries[entries.length - i];
                  return _WeighInRow(
                    entry: entry,
                    unit: unit,
                    onDelete: () => _deleteEntry(context, ref, entries, entry),
                  );
                },
              );
            },
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text(
            l10n.progressErrorLoad,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Future<void> _logWeight(BuildContext context, WidgetRef ref) async {
    final result = await showLogWeightDialog(context);
    if (!context.mounted || result == null) return;

    final l10n = context.l10n;
    final message = result.targetChanged
        ? l10n.progressSavedNewTarget(
            result.newCalorieTarget,
            result.previousCalorieTarget,
          )
        : l10n.progressSavedSameTarget(result.newCalorieTarget);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    List<WeightEntry> entries,
    WeightEntry entry,
  ) async {
    // Taking away the newest one takes the plan back to the one before.
    final previous = entries.length > 1 && entries.last.dateKey == entry.dateKey
        ? entries[entries.length - 2]
        : null;
    final unit = ref.read(weightUnitProvider);
    final l10n = context.l10n;
    final weight = formatWeight(entry.weightKg, unit, l10n);
    final date = l10n.shortWeekdayDayMonth(entry.date);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.progressDeleteTitle),
        content: Text(
          previous == null
              ? l10n.progressDeleteBody(weight, date)
              : l10n.progressDeleteBodyBack(
                  weight,
                  date,
                  formatWeight(previous.weightKg, unit, l10n),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(weightLogControllerProvider.notifier)
        .deleteEntry(entry);
    if (!context.mounted) return;
    final message = ref.read(weightLogControllerProvider).hasError
        ? l10n.progressErrorDelete
        : result != null && result.targetChanged
        ? l10n.progressDeletedNewTarget(
            result.newCalorieTarget,
            result.previousCalorieTarget,
          )
        : l10n.progressDeleted;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Clears the chart and history so progress counts from the next weigh-in.
  Future<void> _resetHistory(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.progressResetTitle),
        content: Text(l10n.progressResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.progressResetButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref
        .read(weightLogControllerProvider.notifier)
        .resetHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.progressResetDone : l10n.progressErrorReset),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.entries,
    required this.profile,
    required this.unit,
  });

  final List<WeightEntry> entries;
  final UserProfile? profile;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final start = entries.first.weightKg;
    final current = entries.last.weightKg;
    final delta = current - start;
    final target = profile?.targetWeightKg;
    final l10n = context.l10n;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _StatBlock(
              label: l10n.progressCurrent,
              value: formatWeight(current, unit, l10n),
            ),
          ),
          Expanded(
            child: _StatBlock(
              label: l10n.progressChange,
              value: formatWeightChange(delta, unit, l10n),
              highlight: delta <= 0 ? AppColors.veryGood : AppColors.bad,
            ),
          ),
          Expanded(
            child: _StatBlock(
              label: l10n.progressTarget,
              value: target != null ? formatWeight(target, unit, l10n) : '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value, this.highlight});

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.display.copyWith(
              fontSize: 23,
              color: highlight ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightChartCard extends StatelessWidget {
  const _WeightChartCard({
    required this.entries,
    required this.profile,
    required this.unit,
  });

  final List<WeightEntry> entries;
  final UserProfile? profile;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final firstDate = entries.first.date;
    final l10n = context.l10n;

    double xFor(WeightEntry entry) =>
        entry.date.difference(firstDate).inDays.toDouble();

    // Drawn in kg, or in pounds for pounds and stones.
    final metric = unit == WeightUnit.kg;
    double yFor(double kg) => metric ? kg : kgToLb(kg);
    String weightAt(double y) =>
        formatWeight(metric ? y : lbToKg(y), unit, l10n);

    final spots = entries
        .map((entry) => FlSpot(xFor(entry), yFor(entry.weightKg)))
        .toList();
    final trend = weightTrend(entries);
    final trendSpots = [
      for (var i = 0; i < entries.length; i++)
        FlSpot(spots[i].x, yFor(trend[i].trendKg)),
    ];

    final targetKg = profile?.targetWeightKg;
    final target = targetKg == null ? null : yFor(targetKg);
    final weights = spots.map((spot) => spot.y).toList();
    var minY = weights.reduce(math.min);
    var maxY = weights.reduce(math.max);
    if (target != null) {
      minY = math.min(minY, target);
      maxY = math.max(maxY, target);
    }
    // Pad the range so the line and target never hug the edges.
    final pad = math.max(yFor(1), (maxY - minY) * 0.15);
    minY -= pad;
    maxY += pad;
    // Stones are labelled on whole and half stones, or every pound or two
    // when the range is small: at most 5 lines.
    final stoneStep = unit == WeightUnit.st
        ? const [
            1.0,
            2.0,
            7.0,
            14.0,
            28.0,
            70.0,
          ].firstWhere((step) => (maxY - minY) / step <= 5, orElse: () => 140.0)
        : null;

    final maxX = spots.last.x == 0 ? 1.0 : spots.last.x;
    final labelInterval = math.max(1.0, (maxX / 4).floorToDouble());
    // Room at the sides too, so the first and last dots aren't cut in half.
    final xPad = maxX * 0.05;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 16),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: -xPad,
                maxX: maxX + xPad,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: stoneStep,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: stoneStep == null ? 40 : 52,
                      interval: stoneStep,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        final pounds = value.round();
                        return Text(
                          stoneStep == null
                              ? value.toStringAsFixed(0)
                              : pounds % 14 == 0
                              ? l10n.unitsStAxis(pounds ~/ 14)
                              : l10n.unitsStLbAxis(pounds ~/ 14, pounds % 14),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: labelInterval,
                      getTitlesWidget: (value, meta) {
                        // fl_chart always adds labels at the ends of the axis,
                        // which fall between days and collide with the
                        // regular ones.
                        if (value % labelInterval != 0) {
                          return const SizedBox.shrink();
                        }
                        final date = firstDate.add(
                          Duration(days: value.round()),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.shortDayMonth(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: target == null
                    ? const ExtraLinesData()
                    : ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: target,
                            color: AppColors.veryGood,
                            strokeWidth: 2,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.veryGood,
                              ),
                              labelResolver: (_) => l10n.progressTarget,
                            ),
                          ),
                        ],
                      ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    // Kept inside the chart, clear of the card's edges.
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touched) => [
                      for (final spot in touched)
                        LineTooltipItem(
                          spot.barIndex == 0
                              ? l10n.progressTrend(weightAt(spot.y))
                              : weightAt(spot.y),
                          TextStyle(
                            color: AppColors.veryGood,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  // The trend: a smooth green line over a soft green wash.
                  LineChartBarData(
                    spots: trendSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppColors.veryGood,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.veryGood.withValues(alpha: 0.22),
                          AppColors.veryGood.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                  // The weigh-ins: round beads with a cream rim and no line,
                  // hollow when set aside as a likely typo.
                  LineChartBarData(
                    spots: spots,
                    color: AppColors.veryGood,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, i) => trend[i].setAside
                          ? FlDotCirclePainter(
                              radius: 4.5,
                              color: AppColors.surface,
                              strokeWidth: 2,
                              strokeColor: AppColors.textSecondary,
                            )
                          : FlDotCirclePainter(
                              radius: 4.5,
                              color: AppColors.veryGood,
                              strokeWidth: 2.5,
                              strokeColor: AppColors.surface,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (profile != null) ...[
            const SizedBox(height: 12),
            // In line with the card's other edge, past the room the axis
            // labels need.
            Divider(height: 1, indent: 10, color: AppColors.divider),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: AdaptiveSection(profile: profile!),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeighInRow extends StatelessWidget {
  const _WeighInRow({
    required this.entry,
    required this.unit,
    required this.onDelete,
  });

  final WeightEntry entry;
  final WeightUnit unit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(22, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.date(entry.date, 'EEE, d MMM yyyy'),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (entry.source == WeightSource.checkIn) ...[
              Icon(
                Icons.event_available_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              formatWeight(entry.weightKg, unit, l10n),
              style: AppTheme.display.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDelete,
              tooltip: l10n.progressDeleteTooltip,
              iconSize: 20,
              color: AppColors.textSecondary,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLogWeight});

  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoMark(size: 96),
            const SizedBox(height: 20),
            Text(
              l10n.progressEmptyTitle,
              style: AppTheme.display.copyWith(
                fontSize: 24,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.progressEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onLogWeight,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.progressLogWeight),
            ),
          ],
        ),
      ),
    );
  }
}
