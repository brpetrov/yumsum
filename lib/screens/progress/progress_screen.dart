import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Weight & Progress'),
        actions: [
          // The empty state has its own button, so only show this one once
          // there is history.
          if (entriesAsync.valueOrNull?.isNotEmpty ?? false)
            TextButton.icon(
              onPressed: () => _logWeight(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log weight'),
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
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              ResponsivePage(
                maxWidth: 760,
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsHeader(entries: entries, profile: profile),
                    const SizedBox(height: 16),
                    _WeightChartCard(entries: entries, profile: profile),
                    const SizedBox(height: 16),
                    _HistorySection(entries: entries),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _resetHistory(context, ref),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset progress'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text(
            'Could not load your weight history.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Future<void> _logWeight(BuildContext context, WidgetRef ref) async {
    final result = await showLogWeightDialog(context);
    if (!context.mounted || result == null) return;

    final message = result.targetChanged
        ? 'Weight saved. New target: ${result.newCalorieTarget} kcal '
              '(was ${result.previousCalorieTarget}).'
        : 'Weight saved. Your target stays at ${result.newCalorieTarget} kcal.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Clears the chart and history so progress counts from the next weigh-in.
  Future<void> _resetHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears your weight history and chart. Your plan, meals and '
          'profile stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
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
        content: Text(
          ok
              ? 'Weight history cleared.'
              : 'Could not reset progress. Try again.',
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.entries, required this.profile});

  final List<WeightEntry> entries;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final start = entries.first.weightKg;
    final current = entries.last.weightKg;
    final delta = current - start;
    final target = profile?.targetWeightKg;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _StatBlock(
              label: 'Current',
              value: '${current.toStringAsFixed(1)} kg',
            ),
          ),
          Expanded(
            child: _StatBlock(
              label: 'Change',
              value: '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
              highlight: delta <= 0 ? AppColors.veryGood : AppColors.bad,
            ),
          ),
          Expanded(
            child: _StatBlock(
              label: 'Target',
              value: target != null ? '${target.toStringAsFixed(1)} kg' : '—',
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
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: highlight ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightChartCard extends StatelessWidget {
  const _WeightChartCard({required this.entries, required this.profile});

  final List<WeightEntry> entries;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final firstDate = entries.first.date;

    double xFor(WeightEntry entry) =>
        entry.date.difference(firstDate).inDays.toDouble();

    final spots = entries
        .map((entry) => FlSpot(xFor(entry), entry.weightKg))
        .toList();

    final target = profile?.targetWeightKg;
    final weights = entries.map((e) => e.weightKg).toList();
    var minY = weights.reduce(math.min);
    var maxY = weights.reduce(math.max);
    if (target != null) {
      minY = math.min(minY, target);
      maxY = math.max(maxY, target);
    }
    // Pad the range so the line and target never hug the edges.
    final pad = math.max(1.0, (maxY - minY) * 0.15);
    minY -= pad;
    maxY += pad;

    final maxX = spots.last.x == 0 ? 1.0 : spots.last.x;
    final labelInterval = math.max(1.0, (maxX / 4).floorToDouble());

    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
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
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toStringAsFixed(0),
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
                    // fl_chart always adds a label at the end of the axis,
                    // which collides with the last regular one.
                    if (value == meta.max && value % labelInterval != 0) {
                      return const SizedBox.shrink();
                    }
                    final date = firstDate.add(Duration(days: value.round()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('d MMM').format(date),
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
                          labelResolver: (_) => 'Target',
                        ),
                      ),
                    ],
                  ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 3.5,
                    color: AppColors.primary,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.entries});

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Newest first for the list.
    final reversed = entries.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...reversed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEE, d MMM yyyy').format(entry.date),
                      style: TextStyle(
                        fontSize: 14,
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
                    '${entry.weightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLogWeight});

  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No weight logged yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your weight to see your progress. Your plan adjusts each '
              'time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onLogWeight,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log weight'),
            ),
          ],
        ),
      ),
    );
  }
}
