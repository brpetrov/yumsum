import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/shine.dart';

/// For free users: a YumSum Star feature's name as the button, a warm
/// orange pill with a soft glow under it and a [Shine] across it when it
/// appears, asking to be tapped. The star waits in the dialog's Enable.
/// The Adaptive formula and AI Coach use it.
class TryButton extends StatelessWidget {
  const TryButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(999);
    // The glow sits outside the shine, which would otherwise cut it off.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shine(
        child: Material(
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  Color.lerp(AppColors.primary, Colors.white, 0.2)!,
                ],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: AppTheme.display.copyWith(
                          fontSize: 17,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: AppColors.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A YumSum Star feature's dialog: its name over a short subtitle, with its
/// [image] beside them if it has one, then four bold promises, each with one
/// short line, to take in at a glance.
class FeatureIntroDialog extends StatelessWidget {
  const FeatureIntroDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.image,
    required this.promises,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final Widget? image;

  /// Icon, headline and line.
  final List<(IconData, String, String)> promises;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
    return AlertDialog(
      title: image == null
          ? heading
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image!,
                const SizedBox(width: 14),
                Expanded(child: heading),
              ],
            ),
      content: SingleChildScrollView(child: FeaturePromises(promises)),
      actions: actions,
    );
  }
}

/// A feature's bold promises, each with an icon and one short line: in
/// [FeatureIntroDialog], and on the AI Coach page for free users.
class FeaturePromises extends StatelessWidget {
  const FeaturePromises(this.promises, {super.key});

  /// Icon, headline and line.
  final List<(IconData, String, String)> promises;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (icon, headline, line)) in promises.indexed) ...[
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
    );
  }
}
