import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Smart Snap (photo logging) in one line, under its name in the dialog.
const smartSnapSubtitle = 'Snap your plate and let our AI do the counting.';

/// Sells Smart Snap to someone without YumSum Star, from the bar's photo
/// button. It is simple, so the dialog is small: a camera over the name and
/// the line, two promises, and Become a Star, which opens the YumSum Star
/// page.
Future<void> showSmartSnapIntro(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        children: [
          const IconBubble(Icons.photo_camera_rounded, size: 64, raised: true),
          const SizedBox(height: 14),
          const Text('Smart Snap'),
          const SizedBox(height: 4),
          Text(
            smartSnapSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      content: const FeaturePromises([
        (
          Icons.format_list_bulleted_rounded,
          'Every item, counted',
          'Our AI names what\'s on your plate, with calories and protein '
              'for each.',
        ),
        (
          Icons.edit_rounded,
          'Yours to check',
          'See the list before you save, and change anything it got wrong.',
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Maybe later'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const PlusStar(size: 24),
          label: const Text('Become a Star'),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) await showPlusPaywall(context);
}
