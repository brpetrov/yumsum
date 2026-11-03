import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// The Adaptive formula under the weight chart: its switch, which saves at
/// once, and for YumSum Star with it on, the sum it makes, how well it knows
/// you and this week's result. Without YumSum Star the switch opens the
/// YumSum Star page. Its info button explains it ([showAdaptiveIntro]).
class AdaptiveSection extends ConsumerWidget {
  const AdaptiveSection({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _switch(BuildContext context, WidgetRef ref, bool on) async {
    // Switching off clears what it has learned, so ask first.
    if (!on && profile.adaptiveKcal != 0) {
      final plan = AdaptiveFormula.planOf(
        profile,
        adaptiveKcal: 0,
        now: DateTime.now(),
      ).dailyCalorieTarget.round();
      final off = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch off the Adaptive formula?'),
          content: Text(
            'Your target goes back to your standard plan, $plan kcal. If you '
            'switch it on again, it starts over from there.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Switch off'),
            ),
          ],
        ),
      );
      if (off != true) return;
    }
    final saved = await ref
        .read(profileControllerProvider.notifier)
        .setAdaptiveOn(profile, on);
    if (saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not switch it ${on ? 'on' : 'off'}. Try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(plusProvider);
    final on = plus && profile.adaptiveOn;
    final progress = on
        ? ref.watch(adaptiveProgressProvider).valueOrNull
        : null;
    final week = on ? ref.watch(adaptiveTodayLineProvider) : null;
    final muted = TextStyle(
      fontSize: 13,
      height: 1.35,
      color: AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Adaptive formula',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!plus) ...[
                    const SizedBox(width: 6),
                    const PlusStar(size: 20),
                  ],
                  IconButton(
                    tooltip: 'How it works',
                    onPressed: () => showAdaptiveIntro(context, ref),
                    icon: const Icon(Icons.info_outline_rounded),
                    iconSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Switch(
              value: on,
              onChanged: plus
                  ? (value) => _switch(context, ref, value)
                  : (_) => showPlusPaywall(context),
            ),
          ],
        ),
        Text(
          on
              ? adaptiveSumLine(
                  AdaptiveFormula.planOf(profile, now: DateTime.now()),
                )
              : 'Learns from your weigh-ins and adjusts your target each '
                    'Monday.',
          style: muted,
        ),
        if (progress != null) ...[
          const SizedBox(height: 4),
          Text(adaptiveStageLine(progress), style: muted),
        ],
        if (week != null) ...[
          const SizedBox(height: 4),
          Text(week, style: muted),
        ],
      ],
    );
  }
}
