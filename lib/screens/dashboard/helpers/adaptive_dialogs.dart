import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
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
    builder: (context) => FeatureIntroDialog(
      title: 'Adaptive formula',
      subtitle: 'A target that learns from you',
      promises: const [
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
      ],
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
