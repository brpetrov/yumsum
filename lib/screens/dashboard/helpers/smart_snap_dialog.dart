import 'package:flutter/material.dart';

import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Smart Snap (photo logging) in one line, under its name in the dialog.
const smartSnapSubtitle =
    'Photograph your plate and let the AI do the counting.';

/// Sells Smart Snap to someone without YumSum Star, from the bar's photo
/// button: what it does in four lines, and Become a Star opens the YumSum
/// Star page.
Future<void> showSmartSnapIntro(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => FeatureIntroDialog(
      title: 'Smart Snap',
      subtitle: smartSnapSubtitle,
      image: const IconBubble(Icons.photo_camera_rounded, size: 52),
      promises: const [
        (
          Icons.photo_camera_rounded,
          'Point, snap, done',
          'One photo of your plate, and the meal is logged in seconds.',
        ),
        (
          Icons.format_list_bulleted_rounded,
          'Every item counted',
          'The AI names what\'s on the plate, with calories and protein '
              'for each.',
        ),
        (
          Icons.edit_rounded,
          'Yours to check',
          'See the list before you save, and change anything it got wrong.',
        ),
        (
          Icons.restaurant_rounded,
          'Works anywhere',
          'Home cooking, restaurants or takeaways. If you can see it, it '
              'counts.',
        ),
      ],
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
