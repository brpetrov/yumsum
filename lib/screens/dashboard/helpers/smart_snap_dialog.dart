import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Sells Smart Snap to someone without YumSum Star, from the bar's photo
/// button. It is simple, so the dialog is small: the bowl with its camera
/// (assets/smart_snap.webp, trimmed and shrunk to 720 px) over the name and
/// the line, two promises, and Become a Star, which opens the YumSum Star
/// page.
Future<void> showSmartSnapIntro(BuildContext context) async {
  final l10n = context.l10n;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        children: [
          Image.asset(
            'assets/smart_snap.webp',
            width: 120,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(height: 10),
          Text(l10n.cameraSmartSnap),
          const SizedBox(height: 4),
          Text(
            l10n.cameraSmartSnapSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      content: FeaturePromises([
        (
          Icons.auto_awesome_rounded,
          l10n.cameraSmartSnapSkipTitle,
          l10n.cameraSmartSnapSkipBody,
        ),
        (
          Icons.fact_check_rounded,
          l10n.cameraSmartSnapControlTitle,
          l10n.cameraSmartSnapControlBody,
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonMaybeLater),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const PlusStar(size: 24),
          label: Text(l10n.commonBecomeStar),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) await showPlusPaywall(context);
}
