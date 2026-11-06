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

/// The Adaptive formula in one line, under its name in the dialog.
const adaptiveSubtitle =
    'A smarter calorie estimation formula, tailored to your body and adjusted '
    'weekly as it learns what you burn.';

/// Sells the Adaptive formula: once after subscribing, and from Plan
/// Settings and Weight & Progress. With YumSum
/// Star ([plus]) its button opens the weigh-in dialog, since weigh-ins are
/// what it learns from; without, Enable opens the YumSum Star page.
Future<void> showAdaptiveIntro(BuildContext context, {bool plus = true}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => FeatureIntroDialog(
      title: 'Adaptive formula',
      subtitle: adaptiveSubtitle,
      promises: const [
        (
          Icons.insights_rounded,
          'Measures what you burn',
          'A formula can only guess. This measures what your body really '
              'burns, from your weigh-ins and what you eat.',
        ),
        (
          Icons.tune_rounded,
          'Tailored to you',
          'A target built around your body and your habits, not the '
              'average person.',
        ),
        (
          Icons.trending_down_rounded,
          'Keeps you moving',
          'If your weight stalls, your target adjusts so you keep losing.',
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
