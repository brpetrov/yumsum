import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Prefs keys: the Adaptive formula dialog shown once after subscribing,
/// and the end date whose lapse notice was shown.
const adaptiveIntroShownKey = 'adaptive.intro_shown';
const adaptiveLapseNoticeKey = 'adaptive.lapse_notice';

/// Sells the Adaptive formula ("A target that learns from you"): once after
/// subscribing, and from Plan Settings and Weight & Progress. With YumSum
/// Star ([plus]) its button opens the weigh-in dialog, since weigh-ins are
/// what it learns from; without, Enable opens the YumSum Star page.
Future<void> showAdaptiveIntro(BuildContext context, {bool plus = true}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adaptive formula'),
          const SizedBox(height: 4),
          Text(
            'A target that learns from you',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Four bold promises, each with one short line, to take in at
            // a glance.
            for (final (i, (icon, headline, line)) in [
              (
                Icons.insights_rounded,
                'Finds your real burn',
                'From your own weigh-ins and meals, not a guess.',
              ),
              (
                Icons.tune_rounded,
                'Adapts to your body',
                'A target made for you, not the average person.',
              ),
              (
                Icons.trending_down_rounded,
                'Beats plateaus',
                'When the scale stops moving, your target does.',
              ),
              (
                Icons.monitor_weight_outlined,
                'Learns as you go',
                'The more you weigh in, the smarter it gets. Daily is best.',
              ),
            ].indexed) ...[
              if (i > 0) const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBubble(icon, size: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          line,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
        if (plus)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log weight now'),
          )
        else
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const PlusStar(size: 24),
            label: const Text('Enable'),
          ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  if (plus) {
    await logWeightWithFeedback(context);
  } else {
    await showPlusPaywall(context);
  }
}

/// Once YumSum Star has ended with an adjustment in place: when the target
/// goes back to the standard plan.
Future<void> showAdaptiveLapse(BuildContext context, DateTime back) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Your YumSum Star has ended'),
      content: Text(
        'Your target goes back to your standard plan on '
        '${DateFormat('d MMMM').format(back)}.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
