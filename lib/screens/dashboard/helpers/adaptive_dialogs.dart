import 'package:flutter/material.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Prefs keys: the Adaptive formula dialog shown once after subscribing,
/// and the end date whose lapse notice was shown.
const adaptiveIntroShownKey = 'adaptive.intro_shown';
const adaptiveLapseNoticeKey = 'adaptive.lapse_notice';

/// Sells the Adaptive formula: once after subscribing, and from Plan
/// Settings and Weight & Progress. With YumSum Star ([plus]) its button
/// opens the weigh-in dialog, since weigh-ins are what it learns from;
/// without, Become a Star opens the YumSum Star page.
Future<void> showAdaptiveIntro(BuildContext context, {bool plus = true}) async {
  final l10n = context.l10n;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => FeatureIntroDialog(
      title: l10n.adaptiveIntroTitle,
      subtitle: l10n.adaptiveIntroSubtitle,
      promises: [
        (
          Icons.insights_rounded,
          l10n.adaptiveIntroBurnTitle,
          l10n.adaptiveIntroBurnBody,
        ),
        (
          Icons.tune_rounded,
          l10n.adaptiveIntroBodyTitle,
          l10n.adaptiveIntroBodyBody,
        ),
        (
          Icons.trending_down_rounded,
          l10n.adaptiveIntroChangeTitle,
          l10n.adaptiveIntroChangeBody,
        ),
        (
          Icons.monitor_weight_outlined,
          l10n.adaptiveIntroWeighTitle,
          l10n.adaptiveIntroWeighBody,
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonMaybeLater),
        ),
        if (plus)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adaptiveIntroLogWeight),
          )
        else
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const PlusStar(size: 24),
            label: Text(l10n.commonBecomeStar),
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
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.adaptiveLapseTitle),
      content: Text(l10n.adaptiveLapseBody(l10n.dayMonth(back))),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonGotIt),
        ),
      ],
    ),
  );
}
