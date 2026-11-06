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

/// The Adaptive formula dialog's title and the line under it.
const adaptiveTitle = 'Your calories, personalised';
const adaptiveSubtitle =
    'Feel more confident about how much to eat, with a smart formula that '
    'adapts to you every week.';

/// Sells the Adaptive formula: once after subscribing, and from Plan
/// Settings and Weight & Progress. With YumSum Star ([plus]) its button
/// opens the weigh-in dialog, since weigh-ins are what it learns from;
/// without, Become a Star opens the YumSum Star page.
Future<void> showAdaptiveIntro(BuildContext context, {bool plus = true}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => FeatureIntroDialog(
      title: adaptiveTitle,
      subtitle: adaptiveSubtitle,
      promises: const [
        (
          Icons.insights_rounded,
          'Understand what you burn',
          'Your food logs and weight trends help estimate your daily '
              'calorie burn, taking the guesswork out of your target.',
        ),
        (
          Icons.tune_rounded,
          'Built around your body',
          'Get a target shaped by how your body actually responds, helping '
              'you find what works for you.',
        ),
        (
          Icons.trending_down_rounded,
          'Stay on track as you change',
          'Your calorie needs can change as you lose weight. Your target '
              'adjusts to help you keep making progress.',
        ),
        (
          Icons.monitor_weight_outlined,
          'Make every weigh-in count',
          'Each weigh-in adds to the picture. Consistent logging helps '
              'fine-tune your target over time.',
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Maybe later'),
        ),
        if (plus)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log my weight'),
          )
        else
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const PlusStar(size: 24),
            label: const Text('Become a Star'),
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
