import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';
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
        // Shrinks rather than cuts off beside Log weight on narrow phones.
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Weight & Progress'),
        ),
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
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsHeader(entries: entries, profile: profile),
                    const SizedBox(height: 18),
                    _WeightChartCard(entries: entries, profile: profile),
                    const SizedBox(height: 22),
                    _HistorySection(
                      entries: entries,
                      onDelete: (entry) =>
                          _deleteEntry(context, ref, entries, entry),
                    ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete weigh-in?'),
        content: Text(
          'Remove ${entry.weightKg.toStringAsFixed(1)} kg from '
          '${DateFormat('EEE, d MMM').format(entry.date)}?'
          '${previous == null ? '' : ' Your plan adjusts back to '
                    '${previous.weightKg.toStringAsFixed(1)} kg.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
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
        ? 'Could not delete the weigh-in. Try again.'
        : result != null && result.targetChanged
        ? 'Weigh-in deleted. New target: ${result.newCalorieTarget} kcal '
              '(was ${result.previousCalorieTarget}).'
        : 'Weigh-in deleted.';
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
          'This clears all your weight history and chart progress. Are you '
          'sure?',
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
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 16),
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
                color: AppColors.veryGood,
                barWidth: 4,
                isStrokeCapRound: true,
                // Round beads with a cream rim, over a soft green wash.
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 5.5,
                    color: AppColors.veryGood,
                    strokeWidth: 3,
                    strokeColor: AppColors.surface,
                  ),
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.entries, required this.onDelete});

  final List<WeightEntry> entries;
  final ValueChanged<WeightEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    // Newest first for the list.
    final reversed = entries.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'History',
            style: AppTheme.display.copyWith(
              fontSize: 21,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...reversed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(22, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEE, d MMM yyyy').format(entry.date),
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
                    '${entry.weightKg.toStringAsFixed(1)} kg',
                    style: AppTheme.display.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => onDelete(entry),
                    tooltip: 'Delete weigh-in',
                    iconSize: 20,
                    color: AppColors.textSecondary,
                    icon: const Icon(Icons.delete_outline_rounded),
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
            const AppLogoMark(size: 96),
            const SizedBox(height: 20),
            Text(
              'No weight logged yet',
              style: AppTheme.display.copyWith(
                fontSize: 24,
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
            const SizedBox(height: 24),
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
